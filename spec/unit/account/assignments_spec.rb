require 'sfctl/commands/account/assignments'

RSpec.describe Sfctl::Commands::Account::Assignments, type: :unit do
  let(:config_file) { '.sfctl' }
  let(:output) { StringIO.new }
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
    command.execute(output: output)

    expect(output.string).to include('Please authentificate before continue.')
  end

  it 'should do nothing if assignments could not be fetched' do
    config_path = fixtures_path(config_file)
    ::FileUtils.cp(config_path, tmp_path(config_file))
    expect(::File.file?(tmp_path(config_file))).to be_truthy

    stub_request(:get, assignments_url).to_return(body: '{"error":"forbidden"}', status: 403)

    command = described_class.new(options)
    command.execute(output: output)

    expect(output.string).to include('Something went wrong. Unable to fetch assignments')
  end

  context 'success response' do
    before :each do
      config_path = fixtures_path(config_file)
      ::FileUtils.cp(config_path, tmp_path(config_file))
      expect(::File.file?(tmp_path(config_file))).to be_truthy
    end

    after :each do
      expect(output.string).to include(name)
      expect(output.string).to include(service)
      expect(output.string).to include(budget.to_s)
      expect(output.string).to include(unit)
      expect(output.string).to include(start_date)
      expect(output.string).to include(end_date)
    end

    it 'should print an active assignments' do
      skip 'Fails on CI. Need to fix.'

      stub_request(:get, assignments_url).to_return(body: response_body, status: 200)

      command = described_class.new(options)
      command.execute(output: output)
    end

    it 'should print all assignments' do
      skip 'Fails on CI. Need to fix.'

      options['all'] = true

      stub_request(:get, "#{assignments_url}?all=1").to_return(body: response_body, status: 200)

      command = described_class.new(options)
      command.execute(output: output)
    end
  end
end
