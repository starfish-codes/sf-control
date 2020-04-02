require_relative '../../command'

module Sfctl
  module Commands
    class Time
      class Init < Sfctl::Command
        def initialize(options)
          @options = options

          @pastel = Pastel.new(enabled: !@options['no-color'])
        end

        def execute(output: $stdout)
          read_link_config
          output.puts @pastel.yellow('.sflink is already created.')
        rescue ::TTY::Config::ReadError
          save_link_config!
          output.puts @pastel.green('.sflink successfully created.')
        end
      end
    end
  end
end
