RSpec.describe "'sfctl time providers' command", type: :cli do
  xit "executes 'sfctl time providers  -h' command successfully" do
    expected_output = <<~HEREDOC
      Commands:
        sfctl providers get             # Read which providers are configured on your system.
        sfctl providers help [COMMAND]  # Describe subcommands or one specific subcommand
        sfctl providers set             # Set the configuration required for the provider to authenticate a call to their API.
        sfctl providers unset           # Unset the configuration of a provider.

    HEREDOC

    output = `sfctl time providers -h --no-color`
    expect(output).to eq expected_output
  end
end
