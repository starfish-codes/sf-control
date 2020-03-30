require 'sfctl/commands/auth/bye'

RSpec.describe Sfctl::Commands::Auth::Bye do
  it "executes `auth bye` command successfully" do
    output = StringIO.new
    options = {}
    command = Sfctl::Commands::Auth::Bye.new(options)

    command.execute(output: output)

    expect(output.string).to eq("OK\n")
  end
end
