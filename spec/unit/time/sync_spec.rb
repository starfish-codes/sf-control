require 'sfctl/commands/time/sync'

RSpec.describe Sfctl::Commands::Time::Sync, type: :unit do
  let(:config_file) { '.sfctl' }
  let(:link_config_file) { '.sflink' }
  let(:output) { StringIO.new }
  let(:options) do
    {
      'starfish-host' => 'https://starfish.team',
      'no-color' => true
    }
  end
  let(:assignment_id) { 1010 }
  let(:next_report_url) { "#{options['starfish-host']}/api/v1/assignments/#{assignment_id}/next_report" }
  let(:toggl_token) { 'test_toggl_token' }
  let(:toggl_url) do
    <<~HEREDOC
      https://www.toggl.com/reports/api/v2/details?billable=yes&project_ids=2222,%203333&rounding=off&since=2020-12-01&task_ids=4444,%205555,%206666,%207777&until=2020-12-31&user_agent=api_test&workspace_id=11111
    HEREDOC
  end
  let(:assignment_name) { 'Test assignment' }
  let(:assignment_service) { 'Test service' }
  let(:assignments_body) do
    <<~HEREDOC
      {
        "assignments": [
          {
            "id": #{assignment_id},
            "budget": 40,
            "start_date": "2020-12-01",
            "end_date": "2020-12-31",
            "name": "#{assignment_name}",
            "service": "#{assignment_service}",
            "unit": "hours"
          }
        ]
      }
    HEREDOC
  end
  let(:next_report_body) do
    <<~HEREDOC
      {
        "year": 2020,
        "month": 12,
        "data": "absent"
      }
    HEREDOC
  end
  let(:toggl_time_entries_body) do
    <<~HEREDOC
      {
        "total_grand": 19800000,
        "data": [
          {
            "id": 4444,
            "start": "2020-12-10",
            "dur": 10800000,
            "description": "Test non-billable time entry",
            "billable": false
          },
          {
            "id": 5555,
            "start": "2020-12-10",
            "dur": 9000000,
            "description": "Test billable time entry",
            "billable": true
          }
        ]
      }
    HEREDOC
  end
  let(:table_headers) { %w[Date Comment Time] }
  let(:copy_config_file) do
    config_path = fixtures_path(config_file)
    ::FileUtils.cp(config_path, tmp_path(config_file))
    expect(File.file?(tmp_path(config_file))).to be_truthy
  end
  let(:copy_link_config_file) do
    link_config_path = fixtures_path(link_config_file)
    ::FileUtils.cp(link_config_path, tmp_path(link_config_file))
    expect(File.file?(tmp_path(link_config_file))).to be_truthy
  end

  before do
    stub_const('Sfctl::Command::CONFIG_PATH', tmp_path(config_file))
    stub_const('Sfctl::Command::LINK_CONFIG_PATH', tmp_path(link_config_file))
  end

  it 'should do nothing if config file is not created' do
    copy_link_config_file

    described_class.new(options).execute(output: output)

    expect(output.string).to include 'Please authentificate before continue.'
  end

  it 'should do nothing if link config file is not created' do
    copy_config_file

    described_class.new(options).execute(output: output)

    expect(output.string).to include 'Please initialize time before continue.'
  end

  it 'should return an error if not able to fetch assignments' do
    copy_config_file

    ::FileUtils.touch tmp_path(link_config_file)
    expect(File.file?(tmp_path(link_config_file))).to be_truthy
    File.write tmp_path(link_config_file), "---\nconnections: {}"

    described_class.new(options).execute(output: output)
    expect(output.string).to include 'Please add a connection before continue.'
  end

  it 'should return an error that next report is not exists' do
    copy_config_file
    copy_link_config_file

    stub_request(:get, next_report_url).to_return(body: '{}', status: 404)

    expect_any_instance_of(TTY::Prompt).to receive(:select).with('Which assignment do you want to sync?')
      .and_return('all')

    described_class.new(options).execute(output: output)

    message = <<~HEREDOC
      No next reporting segment on Starfish that accepts time report data, the synchronization will be skipped.
    HEREDOC
    expect(output.string).to include message
  end

  it 'should return a message that dry run enabled' do
    copy_config_file
    copy_link_config_file

    stub_request(:get, next_report_url).to_return(body: next_report_body, status: 200)
    stub_request(:get, toggl_url).to_return(body: toggl_time_entries_body, status: 200)

    expect_any_instance_of(TTY::Prompt).to receive(:select).with('Which assignment do you want to sync?')
      .and_return('all')
    expect_any_instance_of(TTY::Table).to receive(:render).and_return('printed table')

    options['dry_run'] = true
    described_class.new(options).execute(output: output)

    expect(output.string).to include 'Dry run enabled. Skipping upload to starfish.team.'
  end

  it 'should skip selecting an assignment with option "all"' do
    copy_config_file
    copy_link_config_file

    stub_request(:get, next_report_url).to_return(body: next_report_body, status: 200)
    stub_request(:get, toggl_url).to_return(body: toggl_time_entries_body, status: 200)

    expect_any_instance_of(TTY::Prompt).not_to receive(:select).with('Which assignment do you want to sync?')
    expect_any_instance_of(TTY::Table).to receive(:render).and_return('printed table')

    options['all'] = true
    options['dry_run'] = true
    described_class.new(options).execute(output: output)
  end

  it 'should return a message that report contains data' do
    copy_config_file
    copy_link_config_file

    next_report_body = <<~HEREDOC
      {
        "data": "present",
        "month": 12,
        "year": 2020
      }
    HEREDOC

    stub_request(:get, next_report_url).to_return(body: next_report_body, status: 200)
    stub_request(:get, toggl_url).to_return(body: toggl_time_entries_body, status: 200)

    expect_any_instance_of(TTY::Prompt).to receive(:select).with('Which assignment do you want to sync?')
      .and_return('all')
    expect_any_instance_of(TTY::Table).to receive(:render).and_return('printed table')

    options['touchy'] = true
    described_class.new(options).execute(output: output)

    message = 'Report [2020-12] contains data. Skipping upload to starfish.team.'
    expect(output.string).to include message
  end

  it 'should print a message that upload to starfish fails' do
    copy_config_file
    copy_link_config_file

    stub_request(:get, next_report_url).to_return(body: next_report_body, status: 200)
    stub_request(:get, toggl_url).to_return(body: toggl_time_entries_body, status: 200)
    stub_request(:put, next_report_url).to_return(body: '{}', status: 404)

    expect_any_instance_of(TTY::Prompt).to receive(:select).with('Which assignment do you want to sync?')
      .and_return('all')
    expect_any_instance_of(TTY::Table).to receive(:render).and_return('printed table')

    described_class.new(options).execute(output: output)

    expect(output.string).to include 'Something went wrong. Unable to upload time entries to starfish.team'
  end

  it 'should sync data successfully' do
    copy_config_file
    copy_link_config_file

    stub_request(:get, next_report_url).to_return(body: next_report_body, status: 200)
    stub_request(:get, toggl_url).to_return(body: toggl_time_entries_body, status: 200)
    stub_request(:put, next_report_url).to_return(body: '{}', status: 204)

    expect_any_instance_of(TTY::Prompt).to receive(:select).with('Which assignment do you want to sync?')
      .and_return('all')

    printed_table = <<~HEREDOC
      ┌────────────┬─────────────────┬──────┐
      │ Date       │ Comment         │ Time │
      ├────────────┼─────────────────┼──────┤
      │ 2020-12-10 │ Test time entry │   3h │
      │ Total:     │                 │   3h │
      └────────────┴─────────────────┴──────┘
    HEREDOC

    expect_any_instance_of(TTY::Table).to receive(:render).and_return(printed_table)

    result = <<~HEREDOC
      Synchronizing: [#{assignment_name} / #{assignment_service}]
      Next Report:   [2020-12]

      #{printed_table}



    HEREDOC

    described_class.new(options).execute(output: output)

    expect(output.string).to eq result
  end

  it 'should raise an exception' do
    copy_config_file
    copy_link_config_file

    stub_request(:get, next_report_url).to_return(body: next_report_body, status: 200)
    stub_request(:get, toggl_url).to_return(body: '', status: 200)

    expect_any_instance_of(TTY::Prompt).to receive(:select).with('Which assignment do you want to sync?')
      .and_return('all')

    described_class.new(options).execute(output: output)

    expect(output.string).to include 'Something went wrong.'
  end

  context 'billable/non-billable/both time entries.' do
    it 'should print only billable time entries' do
      toggl_time_entries_body = <<~HEREDOC
        {
          "total_grand": 9000000,
          "data": [
            {
              "id": 5555,
              "start": "2020-12-10",
              "dur": 9000000,
              "description": "Test billable time entry",
              "billable": true
            }
          ]
        }
      HEREDOC

      copy_config_file
      copy_link_config_file

      stub_request(:get, next_report_url).to_return(body: next_report_body, status: 200)
      stub_request(:get, toggl_url).to_return(body: toggl_time_entries_body, status: 200)
      stub_request(:put, next_report_url).to_return(body: '{}', status: 204)

      expect_any_instance_of(TTY::Prompt).to receive(:select).with('Which assignment do you want to sync?')
        .and_return('all')

      expect(TTY::Table).to receive(:new)
        .with(
          table_headers,
          [
            ['2020-12-10', 'Test billable time entry', '2.50h'],
            ['Total:', '', '2.50h']
          ]
        )
        .and_call_original

      expect_any_instance_of(TTY::Table).to receive(:render).and_return('printed table')

      described_class.new(options).execute(output: output)
    end

    it 'should print only non-billable time entries' do
      toggl_url = <<~HEREDOC
        https://www.toggl.com/reports/api/v2/details?billable=no&project_ids=2222,%203333&rounding=off&since=2020-12-01&task_ids=4444,%205555,%206666,%207777&until=2020-12-31&user_agent=api_test&workspace_id=11111
      HEREDOC

      toggl_time_entries_body = <<~HEREDOC
        {
          "total_grand": 10800000,
          "data": [
            {
              "id": 4444,
              "start": "2020-12-10",
              "dur": 10800000,
              "description": "Test non-billable time entry",
              "billable": false
            }
          ]
        }
      HEREDOC

      copy_config_file

      ::FileUtils.touch tmp_path(link_config_file)
      link_file_content = <<~HEREDOC
        ---
        connections:
          '1010':
            name: Test assignment
            service: Test service
            provider: toggl
            workspace_id: '11111'
            project_ids: '2222, 3333'
            task_ids: '4444, 5555, 6666, 7777'
            billable: 'no'
            rounding: 'off'
      HEREDOC
      File.write tmp_path(link_config_file), link_file_content

      stub_request(:get, next_report_url).to_return(body: next_report_body, status: 200)
      stub_request(:get, toggl_url).to_return(body: toggl_time_entries_body, status: 200)
      stub_request(:put, next_report_url).to_return(body: '{}', status: 204)

      expect_any_instance_of(TTY::Prompt).to receive(:select).with('Which assignment do you want to sync?')
        .and_return('all')

      expect(TTY::Table).to receive(:new)
        .with(
          table_headers,
          [
            ['2020-12-10', 'Test non-billable time entry', '3h'],
            ['Total:', '', '3h']
          ]
        )
        .and_call_original

      expect_any_instance_of(TTY::Table).to receive(:render).and_return('printed table')

      described_class.new(options).execute(output: output)
    end

    it 'should print both time entries' do
      toggl_url = <<~HEREDOC
        https://www.toggl.com/reports/api/v2/details?billable=both&project_ids=2222,%203333&rounding=off&since=2020-12-01&task_ids=4444,%205555,%206666,%207777&until=2020-12-31&user_agent=api_test&workspace_id=11111
      HEREDOC

      copy_config_file

      ::FileUtils.touch tmp_path(link_config_file)
      link_file_content = <<~HEREDOC
        ---
        connections:
          '1010':
            name: Test assignment
            service: Test service
            provider: toggl
            workspace_id: '11111'
            project_ids: '2222, 3333'
            task_ids: '4444, 5555, 6666, 7777'
            billable: 'both'
            rounding: 'off'
      HEREDOC
      File.write tmp_path(link_config_file), link_file_content

      stub_request(:get, next_report_url).to_return(body: next_report_body, status: 200)
      stub_request(:get, toggl_url).to_return(body: toggl_time_entries_body, status: 200)
      stub_request(:put, next_report_url).to_return(body: '{}', status: 204)

      expect_any_instance_of(TTY::Prompt).to receive(:select).with('Which assignment do you want to sync?')
        .and_return('all')

      expect(TTY::Table).to receive(:new)
        .with(
          table_headers,
          [
            ['2020-12-10', 'Test non-billable time entry', '3h'],
            ['2020-12-10', 'Test billable time entry', '2.50h'],
            ['Total:', '', '5.50h']
          ]
        )
        .and_call_original

      expect_any_instance_of(TTY::Table).to receive(:render).and_return('printed table')

      described_class.new(options).execute(output: output)
    end
  end

  context 'rounding on/off' do
    let(:toggl_time_entries_body) do
      <<~HEREDOC
        {
          "total_grand": 12500000,
          "data": [
            {
              "id": 4444,
              "start": "2020-12-10",
              "dur": 12500000,
              "description": "Test time entry",
              "billable": true
            }
          ]
        }
      HEREDOC
    end

    it 'should not round the value' do
      copy_config_file
      copy_link_config_file

      stub_request(:get, next_report_url).to_return(body: next_report_body, status: 200)
      stub_request(:get, toggl_url).to_return(body: toggl_time_entries_body, status: 200)
      stub_request(:put, next_report_url).to_return(body: '{}', status: 204)

      expect_any_instance_of(TTY::Prompt).to receive(:select).with('Which assignment do you want to sync?')
        .and_return('all')

      expect(TTY::Table).to receive(:new)
        .with(
          table_headers,
          [
            ['2020-12-10', 'Test time entry', '3.46h'],
            ['Total:', '', '3.46h']
          ]
        )
        .and_call_original

      expect_any_instance_of(TTY::Table).to receive(:render).and_return('printed table')

      described_class.new(options).execute(output: output)
    end

    it 'should round the value' do
      toggl_url = <<~HEREDOC
        https://www.toggl.com/reports/api/v2/details?billable=both&project_ids=2222,%203333&rounding=on&since=2020-12-01&task_ids=4444,%205555,%206666,%207777&until=2020-12-31&user_agent=api_test&workspace_id=11111
      HEREDOC

      toggl_time_entries_body = <<~HEREDOC
        {
          "total_grand": 10800000,
          "data": [
            {
              "id": 4444,
              "start": "2020-12-10",
              "dur": 10800000,
              "description": "Test time entry",
              "billable": false
            }
          ]
        }
      HEREDOC

      copy_config_file

      ::FileUtils.touch tmp_path(link_config_file)
      link_file_content = <<~HEREDOC
        ---
        connections:
          '1010':
            name: Test assignment
            service: Test service
            provider: toggl
            workspace_id: '11111'
            project_ids: '2222, 3333'
            task_ids: '4444, 5555, 6666, 7777'
            billable: 'both'
            rounding: 'on'
      HEREDOC
      File.write tmp_path(link_config_file), link_file_content

      stub_request(:get, next_report_url).to_return(body: next_report_body, status: 200)
      stub_request(:get, toggl_url).to_return(body: toggl_time_entries_body, status: 200)
      stub_request(:put, next_report_url).to_return(body: '{}', status: 204)

      expect_any_instance_of(TTY::Prompt).to receive(:select).with('Which assignment do you want to sync?')
        .and_return('all')

      expect(TTY::Table).to receive(:new)
        .with(
          table_headers,
          [
            ['2020-12-10', 'Test time entry', '3h'],
            ['Total:', '', '3h']
          ]
        )
        .and_call_original

      expect_any_instance_of(TTY::Table).to receive(:render).and_return('printed table')

      described_class.new(options).execute(output: output)
    end
  end
end
