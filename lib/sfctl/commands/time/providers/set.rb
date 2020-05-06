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
            return unless config_present?(output)

            prompt = ::TTY::Prompt.new
            provider = prompt.select('Setting up:', PROVIDERS_LIST)

            !ask_for_replace(output, prompt) && return unless config.fetch("providers.#{provider}").nil?

            case provider
            when TOGGL_PROVIDER
              setup_toggl_provider!(output, prompt)
            when HARVEST_PROVIDER
              setup_harvest_provider!(output, prompt)
            end
          end

          private

          def ask_for_replace(output, prompt)
            output.puts @pastel.yellow('You already have a configuration for this provider.')
            prompt.yes?('Do you want to replace it?')
          end

          def correct?(prompt)
            prompt.yes?('Is that information correct?')
          end

          def save_config_and_print_message!(output)
            save_config!
            output.puts @pastel.green('Everything saved.')
          end

          def save_toggl_config!(output, access_token)
            config.set("providers.#{TOGGL_PROVIDER}.access_token", value: access_token)
            save_config_and_print_message!(output)
          end

          def setup_toggl_provider!(output, prompt)
            output.puts
            access_token = prompt.ask("Your access token at [#{@pastel.green(TOGGL_PROVIDER)}]:", required: true)
            if correct?(prompt)
              save_toggl_config!(output, access_token)
            else
              setup_toggl_provider!(output, prompt)
            end
          end

          def save_harvest_config!(output, account_id, access_token)
            config.set("providers.#{HARVEST_PROVIDER}.account_id", value: account_id)
            config.set("providers.#{HARVEST_PROVIDER}.access_token", value: access_token)
            save_config_and_print_message!(output)
          end

          def setup_harvest_provider!(output, prompt)
            output.puts
            account_id = prompt.ask("Your Account ID at [#{@pastel.green(HARVEST_PROVIDER)}]:", required: true)
            access_token = prompt.ask("Your Token at [#{@pastel.green(HARVEST_PROVIDER)}]:", required: true)
            if correct?(prompt)
              save_harvest_config!(output, account_id, access_token)
            else
              setup_harvest_provider!(output, prompt)
            end
          end
        end
      end
    end
  end
end
