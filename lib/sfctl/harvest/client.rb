require 'faraday'
require 'json'

module Sfctl
  module Harvest
    module Client
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

      def self.parsed_response(response, key)
        [response.status == 200, JSON.parse(response.body)[key]]
      end

      def self.projects(account_id, token)
        response = conn(account_id, token).get('projects')
        parsed_response(response, 'projects')
      end

      def self.tasks(account_id, token)
        response = conn(account_id, token).get('tasks')
        parsed_response(response, 'tasks')
      end

      def self.time_entries(account_id, token, params)
        response = conn(account_id, token).get('time_entries', params)
        parsed_response(response, 'time_entries')
      end
    end
  end
end
