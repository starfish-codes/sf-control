RSpec.describe "'sfctl account' command", type: :cli do
  it "executes 'sfctl account' command successfully" do
    expected_output = <<~HEREDOC
      Commands:
        sfctl account assignments     # This command will list all of your assignme...
        sfctl account help [COMMAND]  # Describe subcommands or one specific subcom...
        sfctl account info            # This will read your profile data and give y...

    HEREDOC

    output = `sfctl account --no-color`
    expect(output).to eq expected_output
  end
end
