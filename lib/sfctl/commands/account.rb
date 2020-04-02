require 'thor'

module Sfctl
  module Commands
    class Account < Thor
      namespace :account

      desc 'assignments', 'This command will list all of your assignments that are currently active.'
      method_option :help, aliases: '-h', type: :boolean,
                           desc: 'Display usage information'
      method_option :all, aliases: '-a', type: :boolean, default: false,
                          desc: 'If you want to read all assignments you have to provide this flag'
      def assignments(*)
        if options[:help]
          invoke :help, ['assignments']
        else
          require_relative 'account/assignments'
          Sfctl::Commands::Account::Assignments.new(options).execute
        end
      end

      desc 'info', 'This will read your profile data and give you an overview of your account.'
      method_option :help, aliases: '-h', type: :boolean
      def info(*)
        if options[:help]
          invoke :help, ['info']
        else
          require_relative 'account/info'
          Sfctl::Commands::Account::Info.new(options).execute
        end
      end
    end
  end
end
