require 'faraday'
require 'json'

module Sfctl
  module Starfish
    def self.conn(token)
      headers = {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{token}"
      }
      Faraday.new(url: Sfctl.configuration.starfish_api_url, headers: headers) do |builder|
        builder.request :retry
        builder.adapter :net_http
      end
    end

    def self.check_authorization(token)
      response = conn(token).get('profile')
      response.status == 200
    end
  end
end
