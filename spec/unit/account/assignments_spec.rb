require 'sfctl/commands/account/assignments'

RSpec.describe Sfctl::Commands::Account::Assignments, type: :unit do
  let(:config_file) { '.sfctl' }
  let(:output_io) { StringIO.new }
  let(:options) do
    {
      'no-color' => true,
      'starfish-host' => 'https://starfish.team',
      'all' => false
    }
  end
  let(:assignments_url) { "#{options['starfish-host']}/api/v1/assignments" }
  let(:id) { 1 }
  let(:name) { 'Test assignment' }
  let(:service) { 'Engineering' }
  let(:budget) { 40 }
  let(:unit) { 'hour' }
  let(:start_date) { '2020-02-01' }
  let(:end_date) { '2020-05-15' }
  let(:response_body) do
    <<~HEREDOC
      {
        "assignments": [
          {
            "budget": #{budget},
            "end_date": "#{end_date}",
            "id": #{id},
            "name": "#{name}",
            "service": "#{service}",
            "start_date": "#{start_date}",
            "unit":"#{unit}"
          }
        ]
      }
    HEREDOC
  end

  before do
    stub_const('Sfctl::Command::CONFIG_PATH', tmp_path(config_file))
  end

  it 'should do nothing if config file not exists' do
    expect(::File.file?(tmp_path(config_file))).to be_falsey

    command = described_class.new(options)
    command.execute(output: output_io)

    expect(output_io.string).to include('Please authentificate before continue.')
  end

  it 'should do nothing if assignments could not be fetched' do
    config_path = fixtures_path(config_file)
    ::FileUtils.cp(config_path, tmp_path(config_file))
    expect(::File.file?(tmp_path(config_file))).to be_truthy

    stub_request(:get, assignments_url).to_return(body: '{"error":"forbidden"}', status: 403)

    command = described_class.new(options)
    command.execute(output: output_io)

    expect(output_io.string).to include('Something went wrong. Unable to fetch assignments')
  end

  context 'success response' do
    let(:expected_table) do
      <<~HEREDOC
        ┌─────────────────────────────┐
        │ Assignment: #{name} │
        ├─────────────────────────────┤
        │ Service: #{service}        │
        │ Start:   #{start_date}         │
        │ End:     #{end_date}         │
        │ Budget:  #{budget} #{unit}            │
        └─────────────────────────────┘
      HEREDOC
    end

    before :each do
      config_path = fixtures_path(config_file)
      ::FileUtils.cp(config_path, tmp_path(config_file))
      expect(::File.file?(tmp_path(config_file))).to be_truthy
    end

    it 'should print an active assignments' do
      stub_request(:get, assignments_url).to_return(body: response_body, status: 200)

      expect_any_instance_of(TTY::Table).to receive(:render).and_return(expected_table)

      command = described_class.new(options)

      command.execute(output: output_io)

      expect(output_io.string).to eq "#{expected_table}\n"
    end

    it 'should print all assignments' do
      options['all'] = true

      stub_request(:get, "#{assignments_url}?all=1").to_return(body: response_body, status: 200)

      expect_any_instance_of(TTY::Table).to receive(:render).and_return(expected_table)

      command = described_class.new(options)

      command.execute(output: output_io)

      expect(output_io.string).to eq "#{expected_table}\n"
    end
  end
end
