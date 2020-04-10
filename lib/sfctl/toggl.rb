require 'faraday'
require 'json'

module Sfctl
  module Toggl
    def self.conn(token)
      raise 'Please set toggl provider before continue.' if token.nil?

      headers = {
        'Content-Type' => 'application/json'
      }
      Faraday.new(url: "https://#{token}:api_token@www.toggl.com/api/v8/", headers: headers) do |builder|
        builder.request :retry
        builder.adapter :net_http
      end
    end

    def self.parsed_response(response)
      [response.status == 200, JSON.parse(response.body)]
    end

    def self.workspaces(token)
      response = conn(token).get('workspaces')
      parsed_response(response)
    end

    def self.workspace_projects(token, workspace_id)
      response = conn(token).get("workspaces/#{workspace_id}/projects")
      parsed_response(response)
    end

    def self.time_entries(token, params)
      response = conn(token).get('time_entries', params)
      parsed_response(response)
    end
  end
end
