require 'pastel'
require 'tty-prompt'
require_relative '../../../command'

module Sfctl
  module Commands
    class Time
      class Providers
        class Set < Sfctl::Command
          def initialize(options)
            @options = options
            @pastel = Pastel.new(enabled: !@options['no-color'])
          end

          def execute(output: $stdout)
            read_link_config

            prompt = ::TTY::Prompt.new
            provider = prompt.select('Setting up:', PROVIDERS_LIST)

            !ask_for_replace(output, prompt) && return unless config.fetch("providers.#{TOGGL_PROVIDER}").nil?

            case provider
            when TOGGL_PROVIDER
              setup_toggl_provider!(output, prompt)
            end
          rescue TTY::Config::ReadError
            output.puts @pastel.yellow('Please initialize time before continue.')
          end

          private

          def ask_for_replace(output, prompt)
            output.puts @pastel.yellow('You already have a configuration for this provider.')
            prompt.yes?('Do you want to replace it?')
          end

          def save_toggl_config!(output, access_token)
            config.set("providers.#{TOGGL_PROVIDER}.access_token", value: access_token)
            save_link_config!
            output.puts @pastel.green('Everything saved.')
          end

          def setup_toggl_provider!(output, prompt)
            output.puts
            access_token = prompt.ask("Your access token at [#{@pastel.green(TOGGL_PROVIDER)}]:", required: true)
            is_correct = prompt.yes?('Is that information correct?')
            if is_correct
              save_toggl_config!(output, access_token)
            else
              setup_toggl_provider!(output, prompt)
            end
          end
        end
      end
    end
  end
end
