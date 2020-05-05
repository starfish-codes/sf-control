require 'date'
require 'pastel'
require 'tty-spinner'
require 'tty-prompt'
require_relative '../../../command'
require_relative '../../../starfish/client'
require_relative '../../../toggl/client'
require_relative '../../../harvest/client'

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
            success, data = Starfish::Client.account_assignments(@options['starfish-host'], @options['all'], ltoken)
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

            setup_connection!(provider, output, assignment_obj)
          end

          private

          def setup_connection!(provider, output, assignment_obj)
            case provider
            when TOGGL_PROVIDER
              setup_toggl_connection!(output, assignment_obj)
            when HARVEST_PROVIDER
              setup_harvest_connection!(output, assignment_obj)
            end
          end

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

          def ask_for_billable
            @prompt.select('Billable?', %w[yes no both])
          end

          def ask_for_rounding
            @prompt.select('Rounding?', %w[on off])
          end

          def setup_toggl_connection!(output, assignment_obj) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
            spinner = ::TTY::Spinner.new('[:spinner] Loading ...')

            assignment_id = assignment_obj['id']
            toggl_token = read_link_config['providers'][TOGGL_PROVIDER]['access_token']

            spinner.auto_spin
            _success, workspaces = Toggl::Client.workspaces(toggl_token)
            spinner.pause
            output.puts
            workspace = @prompt.select('Please select Workspace:') do |menu|
              workspaces.each do |w|
                menu.choice name: w['name'], value: w
              end
            end
            workspace_id = workspace['id']

            spinner.resume
            _success, projects = Toggl::Client.workspace_projects(toggl_token, workspace_id)

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
              _success, tasks = Toggl::Client.project_tasks(toggl_token, pj_id)
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

            billable = ask_for_billable

            rounding = ask_for_rounding

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

          def setup_harvest_connection!(output, assignment_obj) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
            spinner = ::TTY::Spinner.new('[:spinner] Loading ...')

            assignment_id = assignment_obj['id']
            harvest_account_id = read_link_config['providers'][HARVEST_PROVIDER]['account_id']
            harvest_token = read_link_config['providers'][HARVEST_PROVIDER]['access_token']

            spinner.auto_spin
            _success, projects = Harvest::Client.projects(harvest_account_id, harvest_token)

            if projects.nil? || projects.empty?
              spinner.stop
              error_message = "There is no projects. Please visit #{HARVEST_PROVIDER} and create them before continue."
              output.puts @pastel.red(error_message)
              return
            end

            spinner.pause
            output.puts
            project = @prompt.select('Please select Project:') do |menu|
              projects.each do |pj|
                menu.choice name: pj['name'], value: pj
              end
            end
            project_id = project['id']

            spinner.resume
            _success, tasks = Harvest::Client.tasks(harvest_account_id, harvest_token)

            if tasks.nil? || tasks.empty?
              spinner.stop
              error_message = "There is no tasks. Please visit #{HARVEST_PROVIDER} and create them before continue."
              output.puts @pastel.red(error_message)
              return
            end

            spinner.success
            output.puts
            task = @prompt.select('Please select Task:') do |menu|
              tasks.each do |t|
                menu.choice name: t['name'], value: t
              end
            end
            task_id = task['id']

            billable = ask_for_billable

            rounding = ask_for_rounding

            config.set("connections.#{assignment_id}.name", value: assignment_obj['name'])
            config.set("connections.#{assignment_id}.service", value: assignment_obj['service'])
            config.set("connections.#{assignment_id}.provider", value: HARVEST_PROVIDER)
            config.set("connections.#{assignment_id}.project_id", value: project_id.to_s)
            config.set("connections.#{assignment_id}.task_id", value: task_id.to_s)
            config.set("connections.#{assignment_id}.billable", value: billable)
            config.set("connections.#{assignment_id}.rounding", value: rounding)

            clear_conf_and_print_success!(output)
          end
        end
      end
    end
  end
end
