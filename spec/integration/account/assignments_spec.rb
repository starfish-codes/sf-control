RSpec.describe "'sfctl account assignments' command", type: :cli do
  it "executes 'sfctl account assignments -h' command successfully" do
    expected_output = <<~HEREDOC
      Usage:
        sfctl account assignments

      Options:
        -h, [--help], [--no-help]  # Display usage information
        -a, [--all], [--no-all]    # If you want to read all assignments you have to provide this flag

      This command will list all of your assignments that are currently active.
    HEREDOC

    output = `sfctl account assignments -h`
    expect(output).to eq expected_output
  end
end
