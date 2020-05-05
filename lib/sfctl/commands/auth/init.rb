require_relative '../../command'
require_relative '../../starfish/client'
require 'pastel'
require 'tty-prompt'
require 'tty-spinner'

module Sfctl
  module Commands
    class Auth
      class Init < Sfctl::Command
        def initialize(options)
          @options = options
          @pastel = Pastel.new(enabled: !@options['no-color'])
        end

        def execute(output: $stdout)
          access_token = ::TTY::Prompt.new.ask("Access token(#{@options['starfish-host']}):", required: true)
          spinner = ::TTY::Spinner.new('[:spinner] Checking token ...')
          spinner.auto_spin
          token_valid?(access_token) ? update_config!(spinner, output, access_token) : render_error(spinner, output)
        end

        private

        def token_valid?(access_token)
          Starfish::Client.check_authorization(@options['starfish-host'], access_token)
        end

        def token_accepted_message
          @pastel.green('Credentials are accepted.')
        end

        def wrong_token_message
          @pastel.red('Token is not accepted, please make sure you copy and paste it correctly.')
        end

        def update_config!(spinner, output, access_token)
          config.set :access_token, value: access_token
          save_config!
          spinner.success
          output.puts token_accepted_message
        end

        def render_error(spinner, output)
          spinner.error
          output.puts wrong_token_message
        end
      end
    end
  end
end
