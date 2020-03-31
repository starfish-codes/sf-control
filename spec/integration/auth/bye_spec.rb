RSpec.describe "'sfctl auth bye' command", type: :cli do
  it "executes 'sfctl auth bye -h' command successfully" do
    expected_output = <<~HEREDOC
      Usage:
        sfctl auth bye

      Options:
        -h, [--help], [--no-help]  # ...

      Log out by either removing the config file.
    HEREDOC

    output = `sfctl auth bye -h`
    expect(output).to eq(expected_output)
  end
end
