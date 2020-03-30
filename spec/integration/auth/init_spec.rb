RSpec.describe "`sfctl auth init` command", type: :cli do
  it "executes `sfctl auth help init` command successfully" do
    output = `sfctl auth help init`
    expected_output = <<-OUT
Usage:
  sfctl init

Options:
  -h, [--help], [--no-help]  # Display usage information

Command description...
    OUT

    expect(output).to eq(expected_output)
  end
end
