RSpec.describe "'sfctl time' command", type: :cli do
  it "executes 'sfctl time' command successfully" do
    expected_output = <<~HEREDOC
      Commands:
        sfctl time help [COMMAND]  # Describe subcommands or one specific subcommand
        sfctl time init            # You can use the following command to create a ...

    HEREDOC

    output = `sfctl time --no-color`
    expect(output).to eq expected_output
  end
end
