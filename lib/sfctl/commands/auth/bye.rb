# frozen_string_literal: true

require_relative '../../command'
require 'tty-prompt'
require 'tty-file'

module Sfctl
  module Commands
    class Auth
      class Bye < Sfctl::Command
        def initialize(*); end

        def execute(*)
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
