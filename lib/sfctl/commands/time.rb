require 'thor'

module Sfctl
  module Commands
    class Time < Thor
      namespace :time

      desc 'init',
           'You can use the following command to create a .sflink file that will store your project configuration.'
      long_desc <<~DESC
        You can use the following command to create a .sflink file that will store your project configuration.\n
        Although sensitive data is stored in the main .sfctl directory
        we'd like to recommend to not add the .sflink file to your version control system.
      DESC
      method_option :help, aliases: '-h', type: :boolean
      def init(*)
        if options[:help]
          invoke :help, ['init']
        else
          require_relative 'time/init'
          Sfctl::Commands::Time::Init.new(options).execute
        end
      end
    end
  end
end
