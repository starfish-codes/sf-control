# frozen_string_literal: true

require 'thor'
require 'pastel'
require 'tty-font'

module Sfctl
  # Handle the application command line parsing
  # and the dispatch to various command objects
  #
  # @api public
  class CLI < Thor
    # Error raised by this runner
    Error = Class.new(StandardError)

    def help(*args)
      font = TTY::Font.new(:standard)
      pastel = Pastel.new(enabled: !options['no-color'])
      puts pastel.yellow(font.write('sfctl'))
      super
    end

    class_option :"no-color", type: :boolean, default: false, desc: 'Disable colorization in output'
    class_option :"starfish-host", type: :string, default: 'https://starfish.team',
                                   desc: 'The starfish API endpoint',
                                   banner: 'HOST'

    desc 'version', 'sfctl version'
    def version
      require_relative 'version'
      puts "v#{Sfctl::VERSION}"
    end
    map %w[--version -v] => :version

    require_relative 'commands/account'
    register Sfctl::Commands::Account, 'account', 'account [SUBCOMMAND]', 'Account information for Starfish.team'

    require_relative 'commands/auth'
    register Sfctl::Commands::Auth, 'auth', 'auth [SUBCOMMAND]', 'Authentication with Starfish.team'
  end
end
