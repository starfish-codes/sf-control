require 'date'
require 'pastel'
require 'tty-prompt'
require 'tty-spinner'
require 'tty-table'
require_relative '../../command'
require_relative '../../starfish/client'
require_relative '../../toggl/sync'
require_relative '../../harvest/sync'

module Sfctl
  module Commands
    class Time
      class Sync < Sfctl::Command
        def initialize(options)
          @options = options
          @pastel = Pastel.new(enabled: !@options['no-color'])
          @prompt = ::TTY::Prompt.new
        end

        def execute(output: $stdout)
          return if !config_present?(output) || !link_config_present?(output)

          if read_link_config['connections'].length.zero?
            output.puts @pastel.red('Please add a connection before continue.')
            return
          end

          sync_assignments(output, assignments_to_sync)
        rescue ThreadError, JSON::ParserError
          output.puts
          output.puts @pastel.red('Something went wrong.')
        end

        private

        def assignments_from_connections
          read_link_config['connections'].map do |con|
            id = con[0]
            asmnt = con[1]
            {
              'id' => id,
              'name' => asmnt['name'],
              'service' => asmnt['service'] || '-'
            }
          end
        end

        def assignments_to_sync
          assignments = assignments_from_connections

          return assignments if @options['all']

          assignment_id = select_assignment(assignments)

          return assignments if assignment_id == 'all'

          assignments.select { |a| a['id'].to_s == assignment_id.to_s }.to_a
        end

        def select_assignment(assignments)
          @prompt.select('Which assignment do you want to sync?') do |menu|
            assignments.each do |asmnt|
              menu.choice name: "#{asmnt['name']} / #{asmnt['service']}", value: asmnt['id'].to_s
            end
            menu.choice name: 'All', value: 'all'
          end
        end

        def sync_assignments(output, list)
          list.each do |assignment|
            assignment_id = assignment['id'].to_s
            connection = read_link_config['connections'].select { |c| c == assignment_id }

            if connection.empty?
              output.puts @pastel.red("Unable to find a connection for assignment \"#{assignment['name']}\"")
              next
            end

            sync(output, assignment, connection[assignment_id])
          end
        end

        def sync(output, assignment, connection) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          output.puts "Synchronizing: #{@pastel.cyan("[#{assignment['name']} / #{assignment['service']}]")}"

          success, next_report = Starfish::Client.next_report(@options['starfish-host'], access_token, assignment['id'])

          print_no_next_reporting_segment(output) && return if !success || next_report.empty?

          time_entries = load_time_entries(output, next_report, connection)

          print_dry_run_enabled(output) && return if @options['dry_run']

          print_report_contains_data(output, next_report) && return if touchy?(next_report)

          uploading_to_starfish(output, assignment, time_entries, connection)
        end

        def report_interval(record)
          start_date = Date.parse("#{record['year']}-#{record['month']}-01")
          end_date = start_date.next_month.prev_day
          [start_date, end_date]
        end

        def load_time_entries(output, next_report, connection)
          output.puts "Next Report:   #{@pastel.cyan(report_name(next_report))}"
          next_report_interval = report_interval(next_report)

          case connection['provider']
          when TOGGL_PROVIDER
            Toggl::Sync.load_data(
              output, connection, read_link_config['providers'][TOGGL_PROVIDER], @pastel, next_report_interval
            )
          when HARVEST_PROVIDER
            Harvest::Sync.load_data(
              output, connection, read_link_config['providers'][HARVEST_PROVIDER], @pastel, next_report_interval
            )
          end
        end

        def touchy?(next_report)
          @options['touchy'] && next_report['data'] == 'present'
        end

        def report_name(next_report)
          "[#{next_report['year']}-#{next_report['month']}]"
        end

        def print_no_next_reporting_segment(output)
          message = <<~HEREDOC
            No next reporting segment on Starfish that accepts time report data, the synchronization will be skipped.
          HEREDOC
          output.puts @pastel.red(message)
          true
        end

        def print_dry_run_enabled(output)
          output.puts @pastel.yellow('Dry run enabled. Skipping upload to starfish.team.')
          output.puts
          true
        end

        def print_report_contains_data(output, next_report)
          output.puts @pastel.yellow(
            "Report #{report_name(next_report)} contains data. Skipping upload to starfish.team."
          )
          output.puts
          true
        end

        def assignment_items(time_entries, connection)
          case connection['provider']
          when TOGGL_PROVIDER
            Toggl::Sync.assignment_items(time_entries)
          when HARVEST_PROVIDER
            Harvest::Sync.assignment_items(time_entries, connection)
          end
        end

        def uploading_to_starfish(output, assignment, time_entries, connection)
          spinner = TTY::Spinner.new('Uploading to starfish.team: [:spinner]', format: :dots)
          spinner.auto_spin

          success = Starfish::Client.update_next_report(
            @options['starfish-host'], access_token, assignment['id'], assignment_items(time_entries, connection)
          )
          print_upload_results(output, success, spinner)
        end

        def print_upload_results(output, success, spinner)
          if success
            spinner.success(@pastel.green('Done'))
          else
            spinner.error
            output.puts @pastel.red('Something went wrong. Unable to upload time entries to starfish.team')
          end
          output.puts
          output.puts
          true
        end
      end
    end
  end
end
