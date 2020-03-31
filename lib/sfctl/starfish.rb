require 'faraday'
require 'json'

module Sfctl
  module Starfish
    def self.conn(endpoint, token)
      headers = {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{token}"
      }
      Faraday.new(url: "#{endpoint}/api/v1", headers: headers) do |builder|
        builder.request :retry
        builder.adapter :net_http
      end
    end

    def self.check_authorization(endpoint, token)
      return false if endpoint.nil? || token.nil?

      response = conn(endpoint, token).get('profile')
      response.status == 200
    end
  end
end
