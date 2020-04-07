require 'thor'

module Sfctl
  module Commands
    class Auth < Thor
      namespace :auth

      desc 'bye', 'Log out by either removing the config file.'
      method_option :help, aliases: '-h', type: :boolean, desc: '...'
      def bye(*)
        if options[:help]
          invoke :help, ['bye']
        else
          require_relative 'auth/bye'
          Sfctl::Commands::Auth::Bye.new(options).execute
        end
      end

      desc 'init [TOKEN]', 'Authenticate with Starfish.team'
      long_desc <<~HEREDOC
        Before you can use sfctl, you need to authenticate with Starfish.team by providing an access token,
        which can be created on the profile page of your account.
      HEREDOC
      method_option :help, aliases: '-h', type: :boolean
      def init(access_token)
        if options[:help]
          invoke :help, ['init']
        else
          require_relative 'auth/init'
          Sfctl::Commands::Auth::Init.new(access_token, options).execute
        end
      end
    end
  end
end
