RSpec.describe "'sfctl time providers' command", type: :cli do
  it "executes 'sfctl time providers' command successfully" do
    expected_output = <<~HEREDOC
      Commands:
        sfctl providers get                # Read which providers are configured on...
        sfctl providers help [COMMAND]     # Describe subcommands or one specific s...
        sfctl providers set                # Set the configuration required for the...
        sfctl providers unset              # Unset the configuration of a provider.
        sfctl time help [COMMAND]          # Describe subcommands or one specific s...
        sfctl time init                    # You can use the following command to c...
        sfctl time providers [SUBCOMMAND]  # Manage providers.

    HEREDOC

    output = `sfctl time --no-color`
    expect(output).to eq expected_output
  end
end
