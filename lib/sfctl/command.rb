# frozen_string_literal: true

require 'forwardable'
require 'tty-config'

module Sfctl
  class Command
    extend Forwardable

    CONFIG_FILENAME = '.sfctl'
    CONFIG_PATH = "#{Dir.home}/#{CONFIG_FILENAME}"
    LINK_CONFIG_FILENAME = '.sflink'
    LINK_CONFIG_PATH = "#{Dir.pwd}/#{LINK_CONFIG_FILENAME}"

    TOGGL_PROVIDER = 'toggl'
    PROVIDERS_LIST = [
      TOGGL_PROVIDER
    ].freeze

    def_delegators :command, :run

    # Main configuration
    # @api public
    def config
      @config ||= begin
        config = TTY::Config.new
        config.append_path Dir.home
        config
      end
    end

    def save_config!
      config.write(CONFIG_PATH, format: :yaml, force: true)
    end

    def read_config
      config.read(CONFIG_PATH, format: :yaml)
    end

    def access_token
      read_config['access_token']
    end

    def config_present?(output)
      read_config
    rescue TTY::Config::ReadError
      output.puts Pastel.new(enabled: !@options['no-color']).red('Please authentificate before continue.')
      false
    end

    def read_link_config
      config.read(LINK_CONFIG_PATH, format: :yaml)
    end

    def save_link_config!
      config.write(LINK_CONFIG_PATH, format: :yaml, force: true)
    end

    def link_config_present?(output)
      read_link_config
    rescue TTY::Config::ReadError
      output.puts Pastel.new(enabled: !@options['no-color']).red('Please initialize time before continue.')
      false
    end

    # Execute this command
    #
    # @api public
    def execute(*)
      raise(
        NotImplementedError,
        "#{self.class}##{__method__} must be implemented"
      )
    end

    # The external commands runner
    #
    # @see http://www.rubydoc.info/gems/tty-command
    #
    # @api public
    def command(**options)
      require 'tty-command'
      TTY::Command.new(options)
    end

    # The cursor movement
    #
    # @see http://www.rubydoc.info/gems/tty-cursor
    #
    # @api public
    # def cursor
    #   require 'tty-cursor'
    #   TTY::Cursor
    # end

    # Open a file or text in the user's preferred editor
    #
    # @see http://www.rubydoc.info/gems/tty-editor
    #
    # @api public
    # def editor
    #   require 'tty-editor'
    #   TTY::Editor
    # end

    # Terminal output paging
    #
    # @see http://www.rubydoc.info/gems/tty-pager
    #
    # @api public
    # def pager(**options)
    #   require 'tty-pager'
    #   TTY::Pager.new(options)
    # end

    # Terminal platform and OS properties
    #
    # @see http://www.rubydoc.info/gems/tty-pager
    #
    # @api public
    # def platform
    #   require 'tty-platform'
    #   TTY::Platform.new
    # end

    # The interactive prompt
    #
    # @see http://www.rubydoc.info/gems/tty-prompt
    #
    # @api public
    # def prompt(**options)
    #   require 'tty-prompt'
    #   TTY::Prompt.new(options)
    # end

    # Get terminal screen properties
    #
    # @see http://www.rubydoc.info/gems/tty-screen
    #
    # @api public
    # def screen
    #   require 'tty-screen'
    #   TTY::Screen
    # end

    # The unix which utility
    #
    # @see http://www.rubydoc.info/gems/tty-which
    #
    # @api public
    # def which(*args)
    #   require 'tty-which'
    #   TTY::Which.which(*args)
    # end

    # Check if executable exists
    #
    # @see http://www.rubydoc.info/gems/tty-which
    #
    # @api public
    # def exec_exist?(*args)
    #   require 'tty-which'
    #   TTY::Which.exist?(*args)
    # end
  end
end
