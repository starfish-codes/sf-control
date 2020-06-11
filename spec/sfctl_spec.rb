RSpec.describe Sfctl, type: :cli do
  it 'has a version number' do
    expect(Sfctl::VERSION).not_to be nil
  end

  xit "executes 'sfctl' command successfully" do
    expected_output = <<~HEREDOC
               __          _     _ 
        ___   / _|   ___  | |_  | |
       / __| | |_   / __| | __| | |
       \\__ \\ |  _| | (__  | |_  | |
       |___/ |_|    \\___|  \\__| |_|
                                   
      Commands:
        sfctl account [SUBCOMMAND]  # Account information for Starfish.team
        sfctl auth [SUBCOMMAND]     # Authentication with Starfish.team
        sfctl help [COMMAND]        # Describe available commands or one specific command
        sfctl time [SUBCOMMAND]     # Time reports
        sfctl version               # sfctl version

      Options:
        [--no-color]            # Disable colorization in output
        [--starfish-host=HOST]  # The starfish API endpoint
                                # Default: https://app.starfish.team

    HEREDOC

    output = `sfctl --no-color`
    expect(output).to eq expected_output
  end
end
