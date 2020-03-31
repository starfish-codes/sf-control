RSpec.describe "'sfctl auth init' command", type: :cli do
  it "executes 'sfctl auth init -h' command successfully" do
    expected_output = <<-HEREDOC
Usage:
  sfctl auth init [TOKEN]

Options:
  -h, [--help], [--no-help]  

Description:
  Before you can use sfctl, you need to authenticate with Starfish.team by providing an access token, which can be created on the profile page of your account.
HEREDOC

    output = `sfctl auth init -h`
    expect(output.delete("\n").squeeze).to eq expected_output.delete("\n").squeeze
  end
end
