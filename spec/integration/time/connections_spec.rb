RSpec.describe "'sfctl time connections' command", type: :cli do
  it "executes 'sfctl time connections  -h' command successfully" do
    expected_output = <<~HEREDOC
      Commands:
        sfctl connections add             # This command will add a connection betw...
        sfctl connections get             # List all known connections in that proj...
        sfctl connections help [COMMAND]  # Describe subcommands or one specific su...

    HEREDOC

    output = `sfctl time connections -h --no-color`
    expect(output).to eq expected_output
  end
end
