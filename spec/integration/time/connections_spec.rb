RSpec.describe "'sfctl time connections' command", type: :cli do
  xit "executes 'sfctl time connections  -h' command successfully" do
    expected_output = <<~HEREDOC
      Commands:
        sfctl connections add             # This command will add a connection between a provider and an assignment.
        sfctl connections get             # List all known connections in that project.
        sfctl connections help [COMMAND]  # Describe subcommands or one specific subcommand

    HEREDOC

    output = `sfctl time connections -h --no-color`
    expect(output).to eq expected_output
  end
end
