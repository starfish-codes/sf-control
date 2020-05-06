require 'sfctl/commands/time/connections/get'

RSpec.describe Sfctl::Commands::Time::Connections::Get, type: :unit do
  let(:link_config_file) { '.sflink' }
  let(:output) { StringIO.new }
  let(:options) do
    { 'no-color' => true }
  end

  before do
    stub_const('Sfctl::Command::LINK_CONFIG_PATH', tmp_path(link_config_file))
  end

  it 'should shown an error if .sflink is not initialized' do
    described_class.new(options).execute(output: output)

    error_message = 'Please initialize time before continue and ensure that your account authenticated.'
    expect(output.string).to include error_message
  end

  it 'should return a message that connections are not set' do
    ::FileUtils.touch tmp_path(link_config_file)

    described_class.new(options).execute(output: output)

    expect(output.string).to include 'You have no connections. Please add them before continue.'
  end

  it 'should get connections' do
    toggl_assignment_name = 'Test assignment'
    harvest_assignment_name = 'Test assignment 2'

    link_config_path = fixtures_path(link_config_file)
    ::FileUtils.cp(link_config_path, tmp_path(link_config_file))

    described_class.new(options).execute(output: output)

    expect(output.string).to include "Connection: #{toggl_assignment_name}"
    expect(output.string).to include "Connection: #{harvest_assignment_name}"
  end
end
