require 'date'
require 'rounding'
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
      class Sync < Sfctl::Command
        ROUND_VALUE = 25

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

          uploading_to_starfish(output, assignment, time_entries, connection)
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
          time_entries = filter_by_billable!(time_entries, connection)

          spinner.success(@pastel.green('Done'))

          table = TTY::Table.new %w[Date Comment Time], time_entries_table_rows(time_entries, connection)
          output.puts
          output.print table.render(:unicode, padding: [0, 1], alignments: %i[left left right])
          output.puts
          output.puts

          time_entries
        end

        def time_entries_table_rows(time_entries, connection)
          rows = time_entries.map do |te|
            [
              Date.parse(te['start']).to_s,
              te['description'],
              "#{humanize_duration(te['duration'], connection)}h"
            ]
          end
          rows.push(['Total:', '', "#{humanize_duration(time_entries.map { |te| te['duration'] }.sum, connection)}h"])
          rows
        end

        def get_toggle_time_entries(next_report, connection) # rubocop:disable Metrics/AbcSize
          _success, time_entries = Toggl.time_entries(
            read_link_config['providers'][TOGGL_PROVIDER]['access_token'], time_entries_params(next_report, connection)
          )
          unless connection['task_ids'].empty?
            time_entries.delete_if { |te| !connection['task_ids'].include?(te['id'].to_s) }
          end
          unless connection['project_ids'].empty?
            time_entries.delete_if { |te| !connection['project_ids'].include?(te['pid'].to_s) }
          end

          time_entries
        end

        def filter_by_billable!(time_entries, connection)
          case connection['billable']
          when 'yes'
            time_entries.delete_if { |te| te['billable'] == false }
          when 'no'
            time_entries.delete_if { |te| te['billable'] == true }
          else
            time_entries
          end
        end

        def time_entries_params(next_report, connection)
          start_date = Date.parse("#{next_report['year']}-#{next_report['month']}-01")
          end_date = start_date.next_month.prev_day
          {
            wid: connection['workspace_id'],
            start_date: start_date.to_datetime.to_s,
            end_date: "#{end_date}T23:59:59+00:00"
          }
        end

        def humanize_duration(seconds, connection)
          minutes = seconds / 60
          int = (minutes / 60).ceil
          dec = minutes % 60
          amount = (dec * 100) / 60
          if connection['rounding'] == 'on'
            amount = amount.round_to(ROUND_VALUE)
            if amount == 100
              amount = 0
              int += 1
            end
          end
          amount = dec.zero? ? '' : ".#{amount}"
          "#{int}#{amount}"
        end

        def assignment_items(time_entries, connection)
          time_entries.map do |te|
            {
              time: humanize_duration(te['duration'], connection).to_f,
              date: Date.parse(te['start']).to_s,
              comment: te['description']
            }
          end
        end

        def uploading_to_starfish(output, assignment, time_entries, connection)
          spinner = TTY::Spinner.new('Uploading to starfish.team: [:spinner]', format: :dots)
          spinner.auto_spin
          success = Starfish.update_next_report(
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
