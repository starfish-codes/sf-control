RSpec.describe "'sfctl auth' command", type: :cli do
  it "executes 'sfctl auth' command successfully" do
    expected_output = <<-HEREDOC
Commands:
  sfctl auth bye             # Log out by either removing the config file.
  sfctl auth help [COMMAND]  # Describe subcommands or one specific subcommand
  sfctl auth init [TOKEN]    # Authenticate with Starfish.team

HEREDOC

    output = `sfctl auth --no-color`
    expect(output).to eq expected_output
  end
end
