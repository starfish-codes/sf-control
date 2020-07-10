require 'tty-spinner'
require 'tty-table'
require_relative '../command'
require_relative './client'

module Sfctl
  module Harvest
    module Sync
      def self.load_data(output, connection, harvest_config, pastel, report_interval)
        spinner = TTY::Spinner.new("Loaded data from #{Sfctl::Command::HARVEST_PROVIDER}: [:spinner]", format: :dots)
        spinner.auto_spin

        time_entries = get_time_entries(connection, harvest_config, report_interval)

        spinner.success(pastel.green('Done'))

        table = TTY::Table.new %w[Date Comment Time], time_entries_table_rows(time_entries, connection)
        output.puts
        output.print table.render(:unicode, padding: [0, 1], alignments: %i[left left right])
        output.puts
        output.puts

        time_entries
      end

      def self.get_time_entries(connection, harvest_config, report_interval)
        _success, data = Harvest::Client.time_entries(
          harvest_config['account_id'],
          harvest_config['access_token'],
          time_entries_params(connection, report_interval)
        )

        data
      end

      def self.hours_field(rounding)
        return 'rounded_hours' if rounding == 'on'

        'hours'
      end

      def self.time_entries_table_rows(time_entries, connection)
        hours_field = hours_field(connection['rounding'])
        rows = time_entries.sort_by { |te| te['spent_date'] }.map do |te|
          [
            te['spent_date'],
            te['notes'],
            "#{te[hours_field]}h"
          ]
        end
        total_grand = time_entries.map { |te| te[hours_field] }.sum
        rows.push(['Total:', '', "#{total_grand}h"])
        rows
      end

      def self.time_entries_params(connection, report_interval)
        start_date, end_date = report_interval
        params = {
          project_id: connection['project_id'],
          task_id: connection['task_id'],
          from: start_date.to_s,
          to: end_date.to_s
        }
        params[:is_billed] = connection['billable'] == 'yes' unless connection['billable'] == 'both'
        params
      end

      def self.assignment_items(time_entries, connection)
        hours_field = hours_field(connection['rounding'])
        time_entries.map do |te|
          hours = te[hours_field]
          time_seconds = hours * 60 * 60
          {
            time_seconds: time_seconds.round,
            date: te['spent_date'].to_s,
            comment: te['notes']
          }
        end
      end
    end
  end
end
