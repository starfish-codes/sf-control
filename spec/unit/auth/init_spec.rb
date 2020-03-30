require 'sfctl/commands/auth/init'

RSpec.describe Sfctl::Commands::Auth::Init do
  it "executes `auth init` command successfully" do
    output = StringIO.new
    options = {}
    command = Sfctl::Commands::Auth::Init.new(options)

    command.execute(output: output)

    expect(output.string).to eq("OK\n")
  end
end
