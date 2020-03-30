# frozen_string_literal: true

require_relative '../../command'
require "tty-prompt"
require "tty-file"

module Sfctl
  module Commands
    class Auth
      class Bye < Sfctl::Command
        def initialize(options)
          @options = options
        end

        def execute(input: $stdin, output: $stdout)
          prompt = TTY::Prompt.new
          reset_config! if prompt.yes?('Are you sure?')
        end

        private

        def reset_config!
          TTY::File.remove_file CONFIG_PATH
        end
      end
    end
  end
end
