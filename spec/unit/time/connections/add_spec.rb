require 'date'
require 'sfctl/commands/time/connections/add'

RSpec.describe Sfctl::Commands::Time::Connections::Add, type: :unit do
  let(:config_file) { '.sfctl' }
  let(:config_path) { fixtures_path(config_file) }
  let(:link_config_file) { '.sflink' }
  let(:link_config_path) { fixtures_path(link_config_file) }
  let(:output) { StringIO.new }
  let(:options) do
    {
      'no-color' => true,
      'starfish-host' => 'https://app.starfish.team'
    }
  end
  let(:toggl_provider) { 'toggl' }
  let(:harvest_provider) { 'harvest' }
  let(:providers_list) { [toggl_provider, harvest_provider] }
  let(:assignments_url) { "#{options['starfish-host']}/api/v1/assignments" }
  let(:assignment_id) { 1010 }
  let(:assignment_name) { 'Test assignment' }
  let(:assignment_service) { 'Test service' }
  let(:assignments_response_body) do
    <<~HEREDOC
      {
        "assignments": [
          {
            "id": #{assignment_id},
            "name": "#{assignment_name}",
            "service": "#{assignment_service}",
            "start_date": "2020-01-01",
            "end_date": "2020-05-15",
            "budget": 40,
            "unit": "hours"
          }
        ]
      }
    HEREDOC
  end
  let(:copy_config_files_to_tmp) do
    ::FileUtils.cp(config_path, tmp_path(config_file))
    ::FileUtils.cp(link_config_path, tmp_path(link_config_file))
  end

  before do
    stub_const('Sfctl::Command::CONFIG_PATH', tmp_path(config_file))
    stub_const('Sfctl::Command::LINK_CONFIG_PATH', tmp_path(link_config_file))
  end

  it 'should shown an error if .sfctl is not initialized' do
    ::FileUtils.cp(link_config_path, tmp_path(link_config_file))

    described_class.new(options).execute(output: output)

    expect(output.string).to include 'Please authentificate before continue.'
  end

  it 'should shown an error if .sflink is not initialized' do
    ::FileUtils.cp(config_path, tmp_path(config_file))

    described_class.new(options).execute(output: output)

    expect(output.string).to include 'Please initialize time before continue.'
  end

  it 'should return an error if assignments could not be fetched' do
    copy_config_files_to_tmp

    stub_request(:get, assignments_url).to_return(body: '{"error":"forbidden"}', status: 403)

    described_class.new(options).execute(output: output)

    expect(output.string).to include 'Something went wrong. Unable to fetch assignments'
  end

  it 'should return a message that all assignments are already added' do
    copy_config_files_to_tmp

    stub_request(:get, assignments_url).to_return(body: assignments_response_body, status: 200)

    described_class.new(options).execute(output: output)

    expect(output.string).to include 'All assignments already added.'
  end

  context 'toggl' do
    let(:toggl_workspaces_url) { 'https://www.toggl.com/api/v8/workspaces' }
    let(:workspace_id) { 'test_workspace_id' }
    let(:toggl_projects_url) { "https://www.toggl.com/api/v8/workspaces/#{workspace_id}/projects" }
    let(:assignment_id) { '1012' }
    let(:assignment_name) { 'Test assignment 3' }
    let(:assignment_service) { 'Test service 3' }
    let(:assignments_response_body) do
      <<~HEREDOC
        {
          "assignments": [
            {
              "id": #{assignment_id},
              "name": "#{assignment_name}",
              "service": "#{assignment_service}",
              "start_date": "2020-01-01",
              "end_date": "2020-05-15",
              "budget": 40,
              "unit": "hours"
            }
          ]
        }
      HEREDOC
    end

    before do
      copy_config_files_to_tmp
    end

    it 'should return an error if not able to fetch toggl projects' do
      stub_request(:get, assignments_url).to_return(body: assignments_response_body, status: 200)
      stub_request(:get, toggl_workspaces_url).to_return(body: '{}', status: 200)
      stub_request(:get, toggl_projects_url).to_return(body: '{}', status: 200)

      expect_any_instance_of(TTY::Prompt).to receive(:select).with('Select provider:', providers_list)
        .and_return(toggl_provider)

      expect_any_instance_of(TTY::Prompt).to receive(:select).with('Select assignment:')
        .and_return({ 'id' => assignment_id, 'name' => assignment_name, 'service' => assignment_service })

      workspace = { 'id' => workspace_id, name: 'Test workspace' }
      expect_any_instance_of(TTY::Prompt).to receive(:select).with('Please select Workspace:').and_return(workspace)

      described_class.new(options).execute(output: output)

      error_message = "There is no projects. Please visit #{toggl_provider} and create them before continue."
      expect(output.string).to include error_message
    end

    it 'should return a message that there is no tasks' do
      stub_request(:get, assignments_url).to_return(body: assignments_response_body, status: 200)
      stub_request(:get, toggl_workspaces_url).to_return(body: '{}', status: 200)
      stub_request(:get, toggl_projects_url).to_return(body: '[{}]', status: 200)
      selected_project_id = 'project_id1'
      toggl_tasks_url = "https://www.toggl.com/api/v8/workspaces/#{selected_project_id}/tasks"
      stub_request(:get, toggl_tasks_url).to_return(body: '[]', status: 200)

      expect_any_instance_of(TTY::Prompt).to receive(:select).with('Select provider:', providers_list)
        .and_return(toggl_provider)

      expect_any_instance_of(TTY::Prompt).to receive(:select).with('Select assignment:')
        .and_return({ 'id' => assignment_id, 'name' => assignment_name, 'service' => assignment_service })

      workspace = { 'id' => workspace_id, name: 'Test workspace' }
      expect_any_instance_of(TTY::Prompt).to receive(:select).with('Please select Workspace:').and_return(workspace)

      project_ids = [selected_project_id]
      expect_any_instance_of(TTY::Prompt).to receive(:multi_select).with('Please select Projects:', min: 1)
        .and_return(project_ids)

      expect_any_instance_of(TTY::Prompt).not_to receive(:multi_select).with('Please select Tasks(by last 3 months):')

      billable = 'yes'
      expect_any_instance_of(TTY::Prompt).to receive(:select)
        .with('Billable?', %w[yes no both])
        .and_return(billable)

      rounding = 'on'
      expect_any_instance_of(TTY::Prompt).to receive(:select)
        .with('Rounding?', %w[on off])
        .and_return(rounding)

      described_class.new(options).execute(output: output)

      expect(output.string).to include "You don't have tasks. Continue..."
    end

    it 'should add new connection' do
      stub_request(:get, assignments_url).to_return(body: assignments_response_body, status: 200)
      stub_request(:get, toggl_workspaces_url).to_return(body: '{}', status: 200)
      stub_request(:get, toggl_projects_url).to_return(body: '[{}]', status: 200)
      selected_project_id = 'project_id1'
      toggl_tasks_url = "https://www.toggl.com/api/v8/workspaces/#{selected_project_id}/tasks"
      stub_request(:get, toggl_tasks_url).to_return(body: '{}', status: 200)

      expect_any_instance_of(TTY::Prompt).to receive(:select).with('Select provider:', providers_list)
        .and_return(toggl_provider)

      expect_any_instance_of(TTY::Prompt).to receive(:select).with('Select assignment:')
        .and_return({ 'id' => assignment_id, 'name' => assignment_name, 'service' => assignment_service })

      workspace = { 'id' => workspace_id, name: 'Test workspace' }
      expect_any_instance_of(TTY::Prompt).to receive(:select).with('Please select Workspace:').and_return(workspace)

      project_ids = [selected_project_id]
      expect_any_instance_of(TTY::Prompt).to receive(:multi_select).with('Please select Projects:', min: 1)
        .and_return(project_ids)

      task_ids = %w[task_ids1 task_ids2 task_ids3 task_ids4]
      expect_any_instance_of(TTY::Prompt).to receive(:multi_select).with('Please select Tasks(by last 3 months):')
        .and_return(task_ids)

      billable = 'yes'
      expect_any_instance_of(TTY::Prompt).to receive(:select)
        .with('Billable?', %w[yes no both])
        .and_return(billable)

      rounding = 'on'
      expect_any_instance_of(TTY::Prompt).to receive(:select)
        .with('Rounding?', %w[on off])
        .and_return(rounding)

      described_class.new(options).execute(output: output)

      expect(output.string).to include 'Connection successfully added.'

      file_data = File.read(tmp_path(link_config_file))
      expect(file_data).to include 'connections:'
      expect(file_data).to include assignment_name
      expect(file_data).to include assignment_service
      expect(file_data).to include toggl_provider
      expect(file_data).to include workspace_id
      expect(file_data).to include project_ids.join(', ')
      expect(file_data).to include task_ids.join(', ')
      expect(file_data).to include billable
      expect(file_data).to include rounding
    end
  end

  context 'harvest' do
    let(:harvest_projects_url) { 'https://api.harvestapp.com/api/v2/projects' }
    let(:harvest_tasks_url) { 'https://api.harvestapp.com/api/v2/tasks' }
    let(:project_id) { 'test_harvest_project_id' }
    let(:task_id) { 'test_harvest_task_id' }
    let(:assignment_id) { '2021' }
    let(:assignment_name) { 'Test assignment 3' }
    let(:assignment_service) { 'Test service 3' }
    let(:assignments_response_body) do
      <<~HEREDOC
        {
          "assignments": [
            {
              "id": #{assignment_id},
              "name": "#{assignment_name}",
              "service": "#{assignment_service}",
              "start_date": "2020-01-01",
              "end_date": "2020-05-15",
              "budget": 40,
              "unit": "hours"
            }
          ]
        }
      HEREDOC
    end

    before do
      copy_config_files_to_tmp
    end

    it 'should return an error if not able to fetch harvest projects' do
      stub_request(:get, assignments_url).to_return(body: assignments_response_body, status: 200)
      stub_request(:get, harvest_projects_url).to_return(body: '{"projects": []}', status: 200)

      expect_any_instance_of(TTY::Prompt).to receive(:select).with('Select provider:', providers_list)
        .and_return(harvest_provider)

      expect_any_instance_of(TTY::Prompt).to receive(:select).with('Select assignment:')
        .and_return({ 'id' => assignment_id, 'name' => assignment_name, 'service' => assignment_service })

      described_class.new(options).execute(output: output)

      error_message = "There is no projects. Please visit #{harvest_provider} and create them before continue."
      expect(output.string).to include error_message
    end

    it 'should return an error if not able to fetch harvest tasks' do
      stub_request(:get, assignments_url).to_return(body: assignments_response_body, status: 200)
      stub_request(:get, harvest_projects_url).to_return(body: '{"projects": [{}]}', status: 200)
      stub_request(:get, harvest_tasks_url).to_return(body: '{"tasks": []}', status: 200)

      expect_any_instance_of(TTY::Prompt).to receive(:select).with('Select provider:', providers_list)
        .and_return(harvest_provider)

      expect_any_instance_of(TTY::Prompt).to receive(:select).with('Select assignment:')
        .and_return({ 'id' => assignment_id, 'name' => assignment_name, 'service' => assignment_service })

      project = { 'id' => project_id, name: 'Test project' }
      expect_any_instance_of(TTY::Prompt).to receive(:select).with('Please select Project:').and_return(project)

      described_class.new(options).execute(output: output)

      error_message = "There is no tasks. Please visit #{harvest_provider} and create them before continue."
      expect(output.string).to include error_message
    end

    it 'should add new connection' do
      stub_request(:get, assignments_url).to_return(body: assignments_response_body, status: 200)
      stub_request(:get, harvest_projects_url).to_return(body: '{"projects": [{}]}', status: 200)
      stub_request(:get, harvest_tasks_url).to_return(body: '{"tasks": [{}]}', status: 200)

      expect_any_instance_of(TTY::Prompt).to receive(:select).with('Select provider:', providers_list)
        .and_return(harvest_provider)

      expect_any_instance_of(TTY::Prompt).to receive(:select).with('Select assignment:')
        .and_return({ 'id' => assignment_id, 'name' => assignment_name, 'service' => assignment_service })

      project = { 'id' => project_id, name: 'Test project' }
      expect_any_instance_of(TTY::Prompt).to receive(:select).with('Please select Project:').and_return(project)

      task = { 'id' => task_id, name: 'Test task' }
      expect_any_instance_of(TTY::Prompt).to receive(:select).with('Please select Task:').and_return(task)

      billable = 'yes'
      expect_any_instance_of(TTY::Prompt).to receive(:select)
        .with('Billable?', %w[yes no both])
        .and_return(billable)

      rounding = 'on'
      expect_any_instance_of(TTY::Prompt).to receive(:select)
        .with('Rounding?', %w[on off])
        .and_return(rounding)

      described_class.new(options).execute(output: output)

      expect(output.string).to include 'Connection successfully added.'

      file_data = File.read(tmp_path(link_config_file))
      expect(file_data).to include 'connections:'
      expect(file_data).to include assignment_name
      expect(file_data).to include assignment_service
      expect(file_data).to include harvest_provider
      expect(file_data).to include project_id
      expect(file_data).to include task_id
      expect(file_data).to include billable
      expect(file_data).to include rounding
    end
  end
end
