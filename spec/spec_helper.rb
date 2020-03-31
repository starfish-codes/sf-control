if ENV['COVERAGE'] || ENV['BUILDKITE']
  require 'simplecov'

  SimpleCov.start do
    command_name 'spec'
    add_filter 'spec'
    add_filter '/lib/sfctl/command.rb'
  end
end

require 'bundler/setup'
require 'sfctl'
require 'open3'
require 'webmock/rspec'

Dir[File.join('.', 'spec', 'support', '**', '*.rb')].sort.each { |f| require f }

WebMock.disable_net_connect!

RSpec.configure do |config|
  config.include(TestHelpers::Paths)
  config.include(TestHelpers::Silent)
  config.after(:example, type: :cli) do
    FileUtils.rm_rf(tmp_path)
  end
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.max_formatted_output_length = 500
  end
end
