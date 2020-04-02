require 'pastel'
require_relative '../../../command'

module Sfctl
  module Commands
    class Time
      class Providers
        class Get < Sfctl::Command
          def initialize(options)
            @options = options
            @pastel = Pastel.new(enabled: !@options['no-color'])
          end

          def execute(output: $stdout)
            read_link_config

            PROVIDERS_LIST.each do |provider|
              read(provider, output)
            end
          rescue TTY::Config::ReadError
            output.puts @pastel.yellow('Please initialize time before continue.')
          end

          private

          def read(provider, output)
            info = config.fetch("providers.#{provider}")
            if info.nil?
              output.puts @pastel.yellow("Provider #{provider} is not set.")
            else
              output.puts "Provider: #{@pastel.cyan(provider)}"
              info.each_key do |k|
                output.puts "  #{k.upcase}: #{info[k]}"
              end
            end
          end
        end
      end
    end
  end
end
