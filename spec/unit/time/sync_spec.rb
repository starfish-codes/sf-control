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
  let(:assignment_id) { 1 }
  let(:assignments_url) { "#{options['starfish-host']}/api/v1/assignments" }
  let(:next_report_url) { "#{options['starfish-host']}/api/v1/assignments/#{assignment_id}/next_report" }
  let(:toggl_token) { 'test_toggl_token' }
  let(:toggl_url) do
    <<~HEREDOC
      https://www.toggl.com/api/v8/time_entries?end_date=2020-12-31T23:59:59%2B00:00&pid=2222,%203333&start_date=2020-12-01T00:00:00%2B00:00&wid=11111
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
      [
        {
          "id": 4444,
          "start": "2020-12-10",
          "duration": 10800,
          "description": "Test time entry"
        }
      ]
    HEREDOC
  end
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
    copy_link_config_file

    stub_request(:get, assignments_url).to_return(body: '{"error":"forbidden"}', status: 403)

    described_class.new(options).execute(output: output)

    expect(output.string).to include 'Something went wrong. Unable to fetch assignments'
  end

  it 'should return an error that connection not created' do
    copy_config_file
    copy_link_config_file
    assignment_name = 'Not connected assignment'
    assignments_body = <<~HEREDOC
      {
        "assignments": [
          {
            "name": "#{assignment_name}",
            "service": "Test service"
          }
        ]
      }
    HEREDOC

    stub_request(:get, assignments_url).to_return(body: assignments_body, status: 200)

    expect_any_instance_of(TTY::Prompt).to receive(:select).with('Which assignment do you want to sync?')
      .and_return(assignment_name)

    described_class.new(options).execute(output: output)

    expect(output.string).to include "Unable to find a connection for assignment \"#{assignment_name}\""
  end

  it 'should return an error that next report is not exists' do
    copy_config_file
    copy_link_config_file

    stub_request(:get, assignments_url).to_return(body: assignments_body, status: 200)
    stub_request(:get, next_report_url).to_return(body: '{}', status: 404)

    expect_any_instance_of(TTY::Prompt).to receive(:select).with('Which assignment do you want to sync?')
      .and_return('all')

    described_class.new(options).execute(output: output)

    message = <<~HEREDOC
      No next reporting segment on Starfish that accepts time report data, the synchronization will be skipped.
    HEREDOC
    expect(output.string).to include message
  end

  it 'should return an error that next report is not exists' do
    copy_config_file
    copy_link_config_file

    stub_request(:get, assignments_url).to_return(body: assignments_body, status: 200)
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

    stub_request(:get, assignments_url).to_return(body: assignments_body, status: 200)
    stub_request(:get, next_report_url).to_return(body: next_report_body, status: 200)
    stub_request(:get, toggl_url).to_return(body: toggl_time_entries_body, status: 200)

    expect_any_instance_of(TTY::Prompt).to receive(:select).with('Which assignment do you want to sync?')
      .and_return('all')
    expect_any_instance_of(TTY::Table).to receive(:render).and_return('printed table')

    options['dry_run'] = true
    described_class.new(options).execute(output: output)

    expect(output.string).to include 'Dry run enabled. Skipping upload to starfish.team.'
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

    stub_request(:get, assignments_url).to_return(body: assignments_body, status: 200)
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

    stub_request(:get, assignments_url).to_return(body: assignments_body, status: 200)
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

    stub_request(:get, assignments_url).to_return(body: assignments_body, status: 200)
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

    stub_request(:get, assignments_url).to_return(body: assignments_body, status: 200)
    stub_request(:get, next_report_url).to_return(body: next_report_body, status: 200)
    stub_request(:get, toggl_url).to_return(body: '', status: 200)

    expect_any_instance_of(TTY::Prompt).to receive(:select).with('Which assignment do you want to sync?')
      .and_return('all')

    described_class.new(options).execute(output: output)

    expect(output.string).to include 'Something went wrong.'
  end
end
