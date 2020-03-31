require 'sfctl/commands/auth/init'

RSpec.describe Sfctl::Commands::Auth::Init do
  let(:config_file) { '.sfctl' }
  let(:output) { StringIO.new }
  let(:options) do
    {
      'no-color' => true
    }
  end

  before do
    stub_const('Sfctl::Command::CONFIG_PATH', tmp_path(config_file))
  end

  it 'should do nothing if token is not correct' do
    expect_any_instance_of(described_class).to receive(:token_valid?).and_return(false)

    command = described_class.new('wrongToken', options)

    command.execute(output: output)

    expected_output = 'Token is not accepted, please make sure you copy and paste it correctly.'
    expect(output.string).to include(expected_output)
    expect(File.file?(tmp_path(config_file))).to be_falsey
  end

  it 'should create a config file' do
    expect_any_instance_of(described_class).to receive(:token_valid?).and_return(true)

    command = described_class.new('correctToken', options)

    command.execute(output: output)

    expect(output.string).to include 'Credentials are accepted.'
    expect(File.file?(tmp_path(config_file))).to be_truthy
    ::FileUtils.rm(tmp_path(config_file))
  end
end
