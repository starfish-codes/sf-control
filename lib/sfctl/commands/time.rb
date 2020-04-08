require 'thor'

module Sfctl
  module Commands
    class Time < Thor
      namespace :time

      desc 'sync', 'Synchronize data with providers.'
      method_option :help, aliases: '-h', type: :boolean,
                           desc: 'Display usage information'
      method_option :dry_run, aliases: '-dry-run', type: :boolean, default: false,
                              desc: 'Check the data first respectively prevent data from being overwritten'
      method_option :touchy, aliases: '-touchy', type: :boolean, default: false,
                             desc: 'The synchronizsation will be skipped if there is preexisting data.'
      long_desc <<~HEREDOC
        It will gets for each assignment the next reporting segment from starfish.team
        and loads the corresponding time reports from the provider.
      HEREDOC
      def sync(*)
        if options[:help]
          invoke :help, ['sync']
        else
          require_relative 'time/sync'
          Sfctl::Commands::Time::Sync.new(options).execute
        end
      end

      desc 'init',
           'You can use the following command to create a .sflink file that will store your project configuration.'
      long_desc <<~HEREDOC
        You can use the following command to create a .sflink file that will store your project configuration.\n
        Although sensitive data is stored in the main .sfctl directory
        we'd like to recommend to not add the .sflink file to your version control system.
      HEREDOC
      method_option :help, aliases: '-h', type: :boolean
      def init(*)
        if options[:help]
          invoke :help, ['init']
        else
          require_relative 'time/init'
          Sfctl::Commands::Time::Init.new(options).execute
        end
      end

      require_relative 'time/providers'
      register Sfctl::Commands::Time::Providers, 'providers', 'providers [SUBCOMMAND]', 'Manage providers.'

      require_relative 'time/connections'
      register Sfctl::Commands::Time::Connections, 'connections', 'connections [SUBCOMMAND]', 'Manage connections.'
    end
  end
end
