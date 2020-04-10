require 'sfctl/commands/auth/init'

RSpec.describe Sfctl::Commands::Auth::Init, type: :unit do
  let(:config_file) { '.sfctl' }
  let(:output) { StringIO.new }
  let(:options) do
    {
      'no-color' => true,
      'starfish-host' => 'https://starfish.team'
    }
  end
  let(:check_auth_url) { "#{options['starfish-host']}/api/v1/profile" }
  let(:ask_text) { "Access token(#{options['starfish-host']}):" }

  before do
    stub_const('Sfctl::Command::CONFIG_PATH', tmp_path(config_file))
  end

  it 'should do nothing if token is not correct' do
    stub_request(:get, check_auth_url).to_return(body: { 'error': 'forbidden' }.to_s, status: 403)

    expect_any_instance_of(TTY::Prompt).to receive(:ask).with(ask_text, required: true).and_return('wrongToken')

    command = described_class.new(options)

    command.execute(output: output)

    expected_output = 'Token is not accepted, please make sure you copy and paste it correctly.'
    expect(output.string).to include(expected_output)
    expect(File.file?(tmp_path(config_file))).to be_falsey
  end

  it 'should create a config file' do
    response_body = { 'email' => 'test-user@mail.com', 'name' => 'Test User' }.to_s
    stub_request(:get, check_auth_url).to_return(body: response_body, status: 200)

    expect_any_instance_of(TTY::Prompt).to receive(:ask).with(ask_text, required: true).and_return('correctToken')

    command = described_class.new(options)

    command.execute(output: output)

    expect(output.string).to include 'Credentials are accepted.'
    expect(File.file?(tmp_path(config_file))).to be_truthy
  end
end
