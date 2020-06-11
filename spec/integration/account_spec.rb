RSpec.describe "'sfctl account' command", type: :cli do
  xit "executes 'sfctl account' command successfully" do
    expected_output = <<~HEREDOC
      Commands:
        sfctl account assignments     # This command will list all of your assignments that are currently active.
        sfctl account help [COMMAND]  # Describe subcommands or one specific subcommand
        sfctl account info            # This will read your profile data and give you an overview of your account.

    HEREDOC

    output = `sfctl account --no-color`
    expect(output).to eq expected_output
  end
end
