RSpec.describe "`sfctl auth` command", type: :cli do
  it "executes `sfctl help auth` command successfully" do
    output = `sfctl help auth`
    expected_output = <<-OUT
Commands:
    OUT

    expect(output).to eq(expected_output)
  end
end
