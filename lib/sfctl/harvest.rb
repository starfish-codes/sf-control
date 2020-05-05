require 'faraday'
require 'json'

module Sfctl
  module Harvest
    API_V2_PATH = 'api/v2/'.freeze

    def self.conn(account_id, token)
      raise 'Please set Harvest provider before continue.' if account_id.nil? || token.nil?

      headers = {
        'Content-Type' => 'application/json',
        'Harvest-Account-ID' => account_id,
        'Authorization' => "Bearer #{token}"
      }

      Faraday.new(url: "https://api.harvestapp.com/#{API_V2_PATH}", headers: headers) do |builder|
        builder.request :retry
        builder.adapter :net_http
      end
    end
  end
end
