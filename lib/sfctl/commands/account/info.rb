require 'pastel'
require 'tty-table'
require_relative '../../command'
require_relative '../../starfish'

module Sfctl
  module Commands
    class Account
      class Info < Sfctl::Command
        def initialize(options)
          @options = options
          @pastel = Pastel.new(enabled: !@options['no-color'])
        end

        def execute(output: $stdout)
          return unless config_present?(output)

          success, info = Starfish.account_info(@options['starfish-host'], access_token)

          unless success
            output.puts @pastel.red('Something went wrong. Unable to fetch account info')
            return
          end

          print_table(info, output)
        end

        private

        def print_table(info, output)
          header = info.keys
          rows = [info.values]
          table = TTY::Table.new header: header, rows: rows
          output.puts table.render(:unicode, padding: [0, 1])
          output.puts
        end
      end
    end
  end
end
