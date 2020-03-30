RSpec.describe "`sfctl auth bye` command", type: :cli do
  it "executes `sfctl auth help bye` command successfully" do
    output = `sfctl auth help bye`
    expected_output = <<-OUT
Usage:
  sfctl bye

Options:
  -h, [--help], [--no-help]  # Display usage information

Command description...
    OUT

    expect(output).to eq(expected_output)
  end
end
