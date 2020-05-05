require 'faraday'
require 'json'

module Sfctl
  module Starfish
    module Client
      def self.conn(endpoint, token)
        raise 'Before continue please pass endpoint and token.' if endpoint.nil? || token.nil?

        headers = {
          'Content-Type' => 'application/json',
          'X-Starfish-Auth' => token
        }
        Faraday.new(url: "#{endpoint}/api/v1", headers: headers) do |builder|
          builder.request :retry
          builder.adapter :net_http
        end
      end

      def self.parsed_response(response)
        [response.status == 200, JSON.parse(response.body)]
      end

      def self.check_authorization(endpoint, token)
        response = conn(endpoint, token).get('profile')
        response.status == 200
      end

      def self.account_info(endpoint, token)
        response = conn(endpoint, token).get('profile')
        parsed_response(response)
      end

      def self.account_assignments(endpoint, all, token)
        api_conn = conn(endpoint, token)
        response = all ? api_conn.get('assignments?all=1') : api_conn.get('assignments')
        parsed_response(response)
      end

      def self.next_report(endpoint, token, assignment_id)
        api_conn = conn(endpoint, token)
        response = api_conn.get("assignments/#{assignment_id}/next_report")
        parsed_response(response)
      end

      def self.update_next_report(endpoint, token, assignment_id, items)
        api_conn = conn(endpoint, token)
        response = api_conn.put("assignments/#{assignment_id}/next_report", JSON.generate(items: items))
        response.status == 204
      end
    end
  end
end
