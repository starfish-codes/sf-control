require 'date'
require 'pastel'
require 'tty-prompt'
require 'tty-spinner'
require 'tty-table'
require_relative '../../command'
require_relative '../../starfish'
require_relative '../../toggl'

module Sfctl
  module Commands
    class Time
      class Sync < Sfctl::Command # rubocop:disable Metrics/ClassLength
        def initialize(options)
          @options = options
          @pastel = Pastel.new(enabled: !@options['no-color'])
          @prompt = ::TTY::Prompt.new
        end

        def execute(output: $stdout)
          return if !config_present?(output) || !link_config_present?(output)

          success, data = Starfish.account_assignments(@options['starfish-host'], @options['all'], access_token)
          unless success
            output.puts @pastel.red('Something went wrong. Unable to fetch assignments')
            return
          end

          sync_assignments(output, assignments_to_sync(data['assignments']))
        rescue ThreadError, JSON::ParserError
          output.puts @pastel.red('Something went wrong.')
        end

        private

        def assignments_to_sync(assignments)
          assignment_name = select_assignment(assignments)

          return assignments if assignment_name == 'all'

          assignments.select { |a| a['name'] == assignment_name }.to_a
        end

        def select_assignment(assignments)
          @prompt.select('Which assignment do you want to sync?') do |menu|
            assignments.each do |asmnt|
              menu.choice name: "#{asmnt['name']} / #{asmnt['service']}", value: asmnt['name']
            end
            menu.choice name: 'All', value: 'all'
          end
        end

        def sync_assignments(output, list)
          list.each do |assignment|
            assignment_name = assignment['name']
            connection = read_link_config['connections'].select { |c| c == assignment_name }

            if connection.empty?
              output.puts @pastel.red("Unable to find a connection for assignment \"#{assignment_name}\"")
              next
            end

            sync(output, assignment, connection[assignment_name])
          end
        end

        def sync(output, assignment, connection)
          case connection['provider']
          when TOGGL_PROVIDER
            sync_with_toggl!(output, assignment, connection)
          end
        end

        def sync_with_toggl!(output, assignment, connection) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          output.puts "Synchronizing: #{@pastel.cyan("[#{assignment['name']} / #{assignment['service']}]")}"

          success, next_report = Starfish.next_report(@options['starfish-host'], access_token, assignment['id'])

          print_no_next_reporting_segment(output) && return if !success || next_report.empty?

          time_entries = load_data_from_toggl(output, next_report, connection)

          print_dry_run_enabled(output) && return if @options['dry_run']

          print_report_contains_data(output, next_report) && return if touchy?(next_report)

          uploading_to_starfish(output, assignment, time_entries)
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

        def load_data_from_toggl(output, next_report, connection)
          output.puts "Next Report:   #{@pastel.cyan(report_name(next_report))}"

          spinner = TTY::Spinner.new("Loaded data from #{TOGGL_PROVIDER}: [:spinner]", format: :dots)
          spinner.auto_spin

          time_entries = get_toggle_time_entries(next_report, connection)

          spinner.success(@pastel.green('Done'))

          table = TTY::Table.new %w[Date Comment Time], time_entries_table_rows(time_entries)
          output.puts
          output.print table.render(:unicode, padding: [0, 1], alignments: %i[left left right])
          output.puts
          output.puts

          time_entries
        end

        def time_entries_table_rows(time_entries)
          rows = time_entries.map do |te|
            [
              Date.parse(te['start']).to_s,
              te['description'],
              "#{humanize_duration(te['duration'])}h"
            ]
          end
          rows.push(['Total:', '', "#{humanize_duration(time_entries.map { |te| te['duration'] }.sum)}h"])
          rows
        end

        def get_toggle_time_entries(next_report, connection)
          _success, time_entries = Toggl.time_entries(
            read_link_config['providers'][TOGGL_PROVIDER]['access_token'], time_entries_params(next_report, connection)
          )
          unless connection['task_ids'].empty?
            time_entries.delete_if { |te| !connection['task_ids'].include?(te['id'].to_s) }
          end

          time_entries
        end

        def time_entries_params(next_report, connection)
          start_date = Date.parse("#{next_report['year']}-#{next_report['month']}-01")
          end_date = start_date.next_month.prev_day
          {
            wid: connection['workspace_id'],
            pid: connection['project_ids'],
            start_date: start_date.to_datetime.to_s,
            end_date: "#{end_date}T23:59:59+00:00"
          }
        end

        def humanize_duration(seconds)
          minutes = seconds / 60
          int = (minutes / 60).ceil
          dec = minutes % 60
          amount = (dec * 100) / 60
          amount = dec.zero? ? '' : ".#{amount}"
          "#{int}#{amount}"
        end

        def assignment_items(time_entries)
          time_entries.map do |te|
            {
              time: humanize_duration(te['duration']),
              date: Date.parse(te['start']).to_s,
              comment: te['description']
            }
          end
        end

        def uploading_to_starfish(output, assignment, time_entries)
          spinner = TTY::Spinner.new('Uploading to starfish.team: [:spinner]', format: :dots)
          spinner.auto_spin
          success = Starfish.update_next_report(
            @options['starfish-host'], access_token, assignment['id'], assignment_items(time_entries)
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