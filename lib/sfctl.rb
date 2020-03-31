require 'sfctl/version'

module Sfctl
  require 'ostruct'

  def self.configuration
    @configuration ||= OpenStruct.new
  end

  def self.configure
    yield(configuration)
  end

  class Error < StandardError; end
end

Sfctl.configure do |config|
  config.starfish_api_url = ENV['STARFISH_API_URL'] || 'https://preview.starfish.team/api/v1/'
end
