require 'sfctl/commands/time/providers/get'
require 'tempfile'

RSpec.describe Sfctl::Commands::Time::Providers::Get, type: :unit do
  let(:config_file) { '.sfctl' }
  let(:output) { StringIO.new }
  let(:options) do
    { 'no-color' => true }
  end
  let(:toggl_provider) { 'toggl' }
  let(:harvest_provider) { 'harvest' }

  before do
    stub_const('Sfctl::Command::CONFIG_PATH', tmp_path(config_file))
  end

  it 'should shown an error if .sfctl is not initialized' do
    described_class.new(options).execute(output: output)

    expect(output.string).to include 'Please authentificate before continue.'
  end

  it 'should get providers' do
    config_path = fixtures_path(config_file)
    ::FileUtils.cp(config_path, tmp_path(config_file))

    described_class.new(options).execute(output: output)

    expect(output.string).to include toggl_provider
    expect(output.string).to include 'test_toggl_access_token'

    expect(output.string).to include harvest_provider
    expect(output.string).to include 'test_harvest_account_id'
    expect(output.string).to include 'test_harvest_access_token'
  end

  it 'should return a message that provider is not set' do
    ::FileUtils.touch tmp_path(config_file)
    File.write tmp_path(config_file), "---\naccess_token: correctToken"

    described_class.new(options).execute(output: output)

    expect(output.string).to include "Provider #{toggl_provider} is not set."
  end
end
