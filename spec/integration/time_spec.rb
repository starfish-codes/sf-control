RSpec.describe "'sfctl time providers' command", type: :cli do
  xit "executes 'sfctl time providers' command successfully" do
    expected_output = <<~HEREDOC
      Commands:
        sfctl connections add                # This command will add a connection between a provider and an assignment.
        sfctl connections get                # List all known connections in that project.
        sfctl connections help [COMMAND]     # Describe subcommands or one specific subcommand
        sfctl providers get                  # Read which providers are configured on your system.
        sfctl providers help [COMMAND]       # Describe subcommands or one specific subcommand
        sfctl providers set                  # Set the configuration required for the provider to authenticate a call to their API.
        sfctl providers unset                # Unset the configuration of a provider.
        sfctl time connections [SUBCOMMAND]  # Manage connections.
        sfctl time help [COMMAND]            # Describe subcommands or one specific subcommand
        sfctl time init                      # You can use the following command to create a .sflink file that will store your project configuration.
        sfctl time providers [SUBCOMMAND]    # Manage providers.
        sfctl time sync                      # Synchronize data with providers.

    HEREDOC

    output = `sfctl time --no-color`
    expect(output).to eq expected_output
  end
end
