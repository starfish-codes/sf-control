RSpec.describe "'sfctl account info' command", type: :cli do
  it "executes 'sfctl account info -h' command successfully" do
    expected_output = <<~HEREDOC
      Usage:
        sfctl account info

      Options:
        -h, [--help], [--no-help]  

      This will read your profile data and give you an overview of your account.
    HEREDOC

    output = `sfctl account info -h`
    expect(output).to eq expected_output
  end
end
