require 'sfctl/commands/time/providers/set'

RSpec.describe Sfctl::Commands::Time::Providers::Set, type: :unit do
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

  it 'should ask for replace if toggl provider alredy defined' do
    config_path = fixtures_path(config_file)
    ::FileUtils.cp(config_path, tmp_path(config_file))
    expect(File.file?(tmp_path(config_file))).to be_truthy

    expect_any_instance_of(TTY::Prompt).to receive(:select).and_return(toggl_provider)
    expect_any_instance_of(TTY::Prompt).to receive(:yes?).with('Do you want to replace it?').and_return(false)

    described_class.new(options).execute(output: output)

    expect(File.read(tmp_path(config_file))).to include toggl_provider
  end

  it 'should ask for replace if harvest provider alredy defined' do
    config_path = fixtures_path(config_file)
    ::FileUtils.cp(config_path, tmp_path(config_file))
    expect(File.file?(tmp_path(config_file))).to be_truthy

    expect_any_instance_of(TTY::Prompt).to receive(:select).and_return(harvest_provider)
    expect_any_instance_of(TTY::Prompt).to receive(:yes?).with('Do you want to replace it?').and_return(false)

    described_class.new(options).execute(output: output)

    expect(File.read(tmp_path(config_file))).to include harvest_provider
  end

  it 'should set a new toggl provider' do
    access_token = 'test_toggl_access_token'

    ::FileUtils.touch tmp_path(config_file)
    File.write tmp_path(config_file), "---\naccess_token: correctToken"

    expect_any_instance_of(TTY::Prompt).to receive(:select).and_return(toggl_provider)

    expect_any_instance_of(TTY::Prompt).not_to receive(:yes?).with('Do you want to replace it?')

    expect_any_instance_of(TTY::Prompt).to receive(:ask)
      .with("Your access token at [#{toggl_provider}]:", required: true)
      .and_return(access_token)

    expect_any_instance_of(TTY::Prompt).to receive(:yes?).with('Is that information correct?').and_return(true)

    described_class.new(options).execute(output: output)

    expect(output.string).to include 'Everything saved.'

    expect(File.file?(tmp_path(config_file))).to be_truthy
    file_data = File.read(tmp_path(config_file))
    expect(file_data).to include toggl_provider
    expect(file_data).to include access_token
  end

  it 'should set a new harvest provider' do
    account_id = 'new_harvest_account_id'
    access_token = 'new_harvest_access_token'

    ::FileUtils.touch tmp_path(config_file)
    File.write tmp_path(config_file), "---\naccess_token: correctToken"

    expect_any_instance_of(TTY::Prompt).to receive(:select).and_return(harvest_provider)

    expect_any_instance_of(TTY::Prompt).not_to receive(:yes?).with('Do you want to replace it?')

    expect_any_instance_of(TTY::Prompt).to receive(:ask)
      .with("Your Account ID at [#{harvest_provider}]:", required: true)
      .and_return(account_id)

    expect_any_instance_of(TTY::Prompt).to receive(:ask)
      .with("Your Token at [#{harvest_provider}]:", required: true)
      .and_return(access_token)

    expect_any_instance_of(TTY::Prompt).to receive(:yes?).with('Is that information correct?').and_return(true)

    described_class.new(options).execute(output: output)

    expect(output.string).to include 'Everything saved.'

    expect(File.file?(tmp_path(config_file))).to be_truthy
    file_data = File.read(tmp_path(config_file))
    expect(file_data).to include harvest_provider
    expect(file_data).to include account_id
    expect(file_data).to include access_token
  end
end
