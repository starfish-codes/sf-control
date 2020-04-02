require 'sfctl/commands/time/init'

RSpec.describe Sfctl::Commands::Time::Init, type: :unit do
  let(:link_config_file) { '.sflink' }
  let(:output) { StringIO.new }
  let(:options) do
    {
      'no-color' => true
    }
  end

  before do
    stub_const('Sfctl::Command::LINK_CONFIG_PATH', tmp_path(link_config_file))
  end

  it 'should do nothing if file is already created' do
    link_config_path = fixtures_path(link_config_file)
    ::FileUtils.cp(link_config_path, tmp_path(link_config_file))
    expect(File.file?(tmp_path(link_config_file))).to be_truthy

    described_class.new(options).execute(output: output)

    expect(output.string).to include '.sflink is already created.'
  end

  it 'should create a link config file' do
    described_class.new(options).execute(output: output)

    expect(output.string).to include '.sflink successfully created.'
    expect(File.file?(tmp_path(link_config_file))).to be_truthy
  end
end
