require 'date'
require 'pastel'
require 'tty-spinner'
require 'tty-prompt'
require_relative '../../../command'
require_relative '../../../starfish'
require_relative '../../../toggl'

module Sfctl
  module Commands
    class Time
      class Connections
        class Add < Sfctl::Command
          def initialize(options)
            @options = options
            @pastel = Pastel.new(enabled: !@options['no-color'])
            @prompt = ::TTY::Prompt.new(help_color: :cyan)
          end

          def execute(output: $stdout) # rubocop:disable Metrics/AbcSize
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
              setup_toggl_connection!(output, assignment_obj)
            end
          end

          private

          def clear_conf_and_print_success!(output)
            delete_providers_from_link_config!
            save_link_config!

            output.puts @pastel.green('Connection successfully added.')
          end

          def delete_providers_from_link_config!
            config.set(:providers, value: '')
            config.delete(:providers)
          end

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

          def setup_toggl_connection!(output, assignment_obj) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
            spinner = ::TTY::Spinner.new('[:spinner] Loading ...')

            assignment_id = assignment_obj['id']
            toggl_token = read_link_config['providers'][TOGGL_PROVIDER]['access_token']

            spinner.auto_spin
            _success, workspaces = Toggl.workspaces(toggl_token)
            spinner.pause
            output.puts
            workspace = @prompt.select('Please select Workspace:') do |menu|
              workspaces.each do |w|
                menu.choice name: w['name'], value: w
              end
            end
            workspace_id = workspace['id']

            spinner.resume
            _success, projects = Toggl.workspace_projects(toggl_token, workspace_id)

            if projects.nil? || projects.empty?
              spinner.stop
              error_message = "There is no projects. Please visit #{TOGGL_PROVIDER} and create them before continue."
              output.puts @pastel.red(error_message)
              return
            end

            spinner.pause
            output.puts
            project_ids = @prompt.multi_select('Please select Projects:', min: 1) do |menu|
              projects.each do |project|
                menu.choice project['name'], project['id']
              end
            end

            spinner.resume
            tasks_objs = []
            project_ids.each do |pj_id|
              _success, tasks = Toggl.project_tasks(toggl_token, pj_id)
              tasks_objs << tasks
            end
            tasks_objs.flatten!
            tasks_objs.compact!
            output.puts
            spinner.success
            tasks_ids = []
            if tasks_objs.length.positive?
              tasks_ids = @prompt.multi_select('Please select Tasks(by last 3 months):') do |menu|
                tasks_objs.each do |to|
                  menu.choice to['name'], to['id']
                end
              end
            else
              output.puts @pastel.yellow("You don't have tasks. Continue...")
            end

            billable = @prompt.select('Billable?', %w[yes no both])

            rounding = @prompt.select('Rounding?', %w[on off])

            config.set("connections.#{assignment_id}.name", value: assignment_obj['name'])
            config.set("connections.#{assignment_id}.service", value: assignment_obj['service'])
            config.set("connections.#{assignment_id}.provider", value: TOGGL_PROVIDER)
            config.set("connections.#{assignment_id}.workspace_id", value: workspace_id.to_s)
            config.set("connections.#{assignment_id}.project_ids", value: project_ids.join(', '))
            config.set("connections.#{assignment_id}.task_ids", value: tasks_ids.join(', '))
            config.set("connections.#{assignment_id}.billable", value: billable)
            config.set("connections.#{assignment_id}.rounding", value: rounding)

            clear_conf_and_print_success!(output)
          end
        end
      end
    end
  end
end
