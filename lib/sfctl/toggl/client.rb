require 'faraday'
require 'json'

module Sfctl
  module Toggl
    module Client
      DEFAULT_API_PATH = 'api/v8/'.freeze
      REPORTS_API_PATH = 'reports/api/v2/'.freeze

      def self.conn(token, api = 'default')
        raise 'Please set toggl provider before continue.' if token.nil?

        api_path = api == 'reports' ? REPORTS_API_PATH : DEFAULT_API_PATH

        headers = { 'Content-Type' => 'application/json' }
        Faraday.new(url: "https://#{token}:api_token@api.track.toggl.com/#{api_path}", headers: headers) do |builder|
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

      def self.project_tasks(token, project_id)
        response = conn(token).get("workspaces/#{project_id}/tasks")

        return [] if response.body.length.zero?

        parsed_response(response)
      end

      def self.time_entries(token, params)
        params[:user_agent] = 'api_test'
        response = conn(token, 'reports').get('details', params)
        parsed_response(response)
      end
    end
  end
end
