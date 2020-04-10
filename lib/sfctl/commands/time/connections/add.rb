require 'pastel'
require 'tty-prompt'
require_relative '../../../command'
require_relative '../../../starfish'
require 'pry'

module Sfctl
  module Commands
    class Time
      class Connections
        class Add < Sfctl::Command
          def initialize(options)
            @options = options
            @pastel = Pastel.new(enabled: !@options['no-color'])
            @prompt = ::TTY::Prompt.new
          end

          def execute(output: $stdout) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
            return if !config_present?(output) || !link_config_present?(output)

            ltoken = access_token
            config.delete(:access_token)
            success, data = Starfish.account_assignments(@options['starfish-host'], @options['all'], ltoken)
            unless success
              output.puts @pastel.red('Something went wrong. Unable to fetch assignments')
              return
            end

            assignments = filter_assignments(data['assignments'])
            if assignments.length.zero?
              output.puts @pastel.yellow('All assignments already added.')
              return
            end

            provider = @prompt.select('Select provider:', PROVIDERS_LIST)

            assignment_obj = select_assignment(assignments)

            case provider
            when TOGGL_PROVIDER
              setup_toggl_connection!(assignment_obj)
            end

            save_link_config!

            output.puts @pastel.green('Connection successfully added.')
          end

          private

          def select_assignment(assignments)
            @prompt.select('Select assignment:') do |menu|
              assignments.each.with_index do |asmnt, i|
                menu.choice name: "#{i + 1}. #{asmnt['name']} / #{asmnt['service']}",
                            value: { 'id' => asmnt['id'], 'name' => asmnt['name'], 'service' => asmnt['service'] }
              end
            end
          end

          def filter_assignments(list)
            return list if config.fetch(:connections).nil?

            added_assignments_ids = config.fetch(:connections).keys
            list.delete_if { |h| added_assignments_ids.include?(h['id'].to_s) }
            list
          end

          def setup_toggl_connection!(assignment_obj) # rubocop:disable Metrics/AbcSize
            assignment_id = assignment_obj['id']
            workspace_id = @prompt.ask('Workspace ID (required):', required: true)
            project_ids = @prompt.ask('Project IDs  (required / comma separated):', required: true)
            task_ids = @prompt.ask('Task IDs     (optional / comma separated):') || ''
            billable = @prompt.select('Billable?    (required)', %w[yes no both])
            rounding = @prompt.select('Rounding?    (required)', %w[on off])

            config.set("connections.#{assignment_id}.name", value: assignment_obj['name'])
            config.set("connections.#{assignment_id}.service", value: assignment_obj['service'])
            config.set("connections.#{assignment_id}.provider", value: TOGGL_PROVIDER)
            config.set("connections.#{assignment_id}.workspace_id", value: workspace_id)
            config.set("connections.#{assignment_id}.project_ids", value: project_ids)
            config.set("connections.#{assignment_id}.task_ids", value: task_ids)
            config.set("connections.#{assignment_id}.billable", value: billable)
            config.set("connections.#{assignment_id}.rounding", value: rounding)
          end
        end
      end
    end
  end
end
