RSpec.describe "'sfctl time sync' command", type: :cli do
  it "executes 'sfctl time sync -h' command successfully" do
    expected_output = <<~HEREDOC
      Usage:
        sfctl time sync

      Options:
        -h, [--help], [--no-help]              # Display usage information
        -dry-run, [--dry-run], [--no-dry-run]  # Check the data first respectively prevent data from being overwritten
        -touchy, [--touchy], [--no-touchy]     # The synchronizsation will be skipped if there is preexisting data.
        -all, [--all], [--no-all]              # Skip selecting assignments and sync all of them.

      Description:
        It will gets for each assignment the next reporting segment from starfish.team and loads the corresponding
        time reports from the provider.
    HEREDOC

    output = `sfctl time sync -h`
    expect(output.delete("\n").squeeze).to eq expected_output.delete("\n").squeeze
  end
end
