require 'sfctl/commands/auth/bye'

RSpec.describe Sfctl::Commands::Auth::Bye, type: :unit do
  subject(:command) { described_class.new }

  let(:config_file) { '.sfctl' }

  before do
    config_path = fixtures_path(config_file)
    ::FileUtils.cp(config_path, tmp_path(config_file))
    expect(File.file?(tmp_path(config_file))).to be_truthy
    stub_const('Sfctl::Command::CONFIG_PATH', tmp_path(config_file))
  end

  it 'removes config file' do
    expect_any_instance_of(TTY::Prompt).to receive(:yes?).and_return(true)

    command.execute

    expect(File.file?(tmp_path(config_file))).to be_falsey
  end

  it 'should do nothing' do
    expect_any_instance_of(TTY::Prompt).to receive(:yes?).and_return(false)

    command.execute

    expect(File.file?(tmp_path(config_file))).to be_truthy
  end
end
