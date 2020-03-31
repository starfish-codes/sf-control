# frozen_string_literal: true

require_relative '../../command'
require_relative '../../starfish'
require 'pastel'
require 'tty-spinner'

module Sfctl
  module Commands
    class Auth
      class Init < Sfctl::Command
        def initialize(access_token, options)
          @access_token = access_token
          @options = options

          @pastel = Pastel.new(enabled: !@options['no-color'])
        end

        def execute(output: $stdout)
          spinner = TTY::Spinner.new('[:spinner] Checking token ...')
          spinner.auto_spin
          token_valid? ? update_config!(spinner, output) : render_error(spinner, output)
        end

        private

        def token_valid?
          Starfish.check_authorization(@options['starfish-host'], @access_token)
        end

        def token_accepted_message
          @pastel.green('Credentials are accepted.')
        end

        def wrong_token_message
          @pastel.red('Token is not accepted, please make sure you copy and paste it correctly.')
        end

        def update_config!(spinner, output)
          config.set :access_token, value: @access_token
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
