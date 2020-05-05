require 'pastel'
require 'tty-table'
require_relative '../../command'
require_relative '../../starfish/client'

module Sfctl
  module Commands
    class Account
      class Assignments < Sfctl::Command
        def initialize(options)
          @options = options
          @pastel = Pastel.new(enabled: !@options['no-color'])
        end

        def execute(output: $stdout)
          return unless config_present?(output)

          success, data = Starfish::Client.account_assignments(@options['starfish-host'], @options['all'], access_token)

          unless success
            output.puts @pastel.red('Something went wrong. Unable to fetch assignments')
            return
          end

          print_assignments(data['assignments'], output)
        end

        private

        def rows(assignment)
          [[
            <<~HEREDOC
              Service: #{assignment['service']}
              Start:   #{assignment['start_date']}
              End:     #{assignment['end_date']}
              Budget:  #{assignment['budget']} #{assignment['unit']}
            HEREDOC
          ]]
        end

        def print_assignments(assignments, output)
          assignments.each do |assignment|
            header = ["Assignment: #{assignment['name']}"]
            table = ::TTY::Table.new header: header, rows: rows(assignment)
            output.print table.render(:unicode, padding: [0, 1], multiline: true)
            output.puts
          end
        end
      end
    end
  end
end
