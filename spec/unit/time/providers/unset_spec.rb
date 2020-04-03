require 'sfctl/commands/time/providers/unset'

RSpec.describe Sfctl::Commands::Time::Providers::Unset, type: :unit do
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

  it 'should ask for replace if provider alredy defined' do
    ::FileUtils.touch tmp_path(link_config_file)

    expect_any_instance_of(TTY::Prompt).to receive(:select).and_return(toggl_provider)

    described_class.new(options).execute(output: output)

    expect(output.string).to include "[#{toggl_provider}] is already deleted from configuration."
  end

  it 'should set a new toggl provider' do
    link_config_path = fixtures_path(link_config_file)
    ::FileUtils.cp(link_config_path, tmp_path(link_config_file))
    expect(File.file?(tmp_path(link_config_file))).to be_truthy

    expect_any_instance_of(TTY::Prompt).to receive(:select).and_return(toggl_provider)
    expect_any_instance_of(TTY::Prompt).to receive(:yes?).with('Do you want to remove the delete the configuration?')
      .and_return(true)

    described_class.new(options).execute(output: output)

    expect(output.string).to include "Configuration for provider [#{toggl_provider}] was successfully deleted."

    access_token = 'test_access_token'
    file_data = File.read(tmp_path(link_config_file))
    expect(file_data).to include 'providers:'
    expect(file_data).not_to include toggl_provider
    expect(file_data).not_to include access_token
  end
end
