# frozen_string_literal: true

require 'thor'

module Sfctl
  module Commands
    class Auth < Thor

      namespace :auth

      desc 'bye', 'Log out by either removing the config file.'
      method_option :help, aliases: '-h', type: :boolean,
                           desc: '...'
      def bye(*)
        if options[:help]
          invoke :help, ['bye']
        else
          require_relative 'auth/bye'
          Sfctl::Commands::Auth::Bye.new(options).execute
        end
      end

      desc 'init [TOKEN]', 'Authenticate with Starfish.team'
      long_desc <<-DESC
        Before you can use sfctl, you need to authenticate with Starfish.team by providing an access token,
        which can be created on the profile page of your account.
      DESC
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




# sfctl auth init
# You wil be promted to enter your access token that you've generated on the profile page.
#
# Starfish.team access token: YOUR_TOKEN
# After entering your token, you will receive confirmation that the credentials were accepted. In case your token is not accepted, please make sure you copy and paste it correctly.
#
# Your token is valid 👍
# As a consequece a .sfctl directory will be created in your $HOME and all data is stored for further use. You can safely copy this folder to other machines to replicate the access. Just be aware this is giving the user controlling the directory access to your starfish account.
#
# You can log out by either removing the config directory or by executing the following command:
#
# sfctl auth bye
