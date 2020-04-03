require 'sfctl/commands/time/providers/get'
require 'tempfile'

RSpec.describe Sfctl::Commands::Time::Providers::Get, type: :unit do
  let(:link_config_file) { '.sflink' }
  let(:output) { StringIO.new }
  let(:options) do
    { 'no-color' => true }
  end
  let(:toggl_provider) { 'toggl' }

  before do
    stub_const('Sfctl::Command::LINK_CONFIG_PATH', tmp_path(link_config_file))
  end

  it 'should shown an error if .sflink is not initialized' do
    described_class.new(options).execute(output: output)

    expect(output.string).to include 'Please initialize time before continue.'
  end

  it 'should get providers' do
    access_token = 'test_access_token'

    link_config_path = fixtures_path(link_config_file)
    ::FileUtils.cp(link_config_path, tmp_path(link_config_file))

    described_class.new(options).execute(output: output)

    expect(output.string).to include toggl_provider
    expect(output.string).to include access_token
  end

  it 'should return a message that provider is not set' do
    ::FileUtils.touch tmp_path(link_config_file)

    described_class.new(options).execute(output: output)

    expect(output.string).to include "Provider #{toggl_provider} is not set."
  end
end
