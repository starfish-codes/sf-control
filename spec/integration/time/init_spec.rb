RSpec.describe "'sfctl time init' command", type: :cli do
  it "executes 'sfctl time init -h' command successfully" do
    expected_output = <<~HEREDOC
      Usage:
        sfctl time init

      Options:
        -h, [--help], [--no-help]  

      Description:
        You can use the following command to create a .sflink file that will store your project configuration.

        Although sensitive data is stored in the main .sfctl directory
        we'd like to recommend to not add the .sflink file to your version control system.
    HEREDOC

    output = `sfctl time init -h`
    expect(output.delete("\n").squeeze).to eq expected_output.delete("\n").squeeze
  end
end
