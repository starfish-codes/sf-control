require 'thor'

module Sfctl
  module Commands
    class Time
      class Providers < Thor
        namespace :providers

        desc 'set', 'Set the configuration required for the provider to authenticate a call to their API.'
        method_option :help, aliases: '-h', type: :boolean
        def set(*)
          if options[:help]
            invoke :help, ['set']
          else
            require_relative 'providers/set'
            Sfctl::Commands::Time::Providers::Set.new(options).execute
          end
        end

        desc 'unset', 'Unset the configuration of a provider.'
        method_option :help, aliases: '-h', type: :boolean
        def unset(*)
          if options[:help]
            invoke :help, ['unset']
          else
            require_relative 'providers/unset'
            Sfctl::Commands::Time::Providers::Unset.new(options).execute
          end
        end

        desc 'get', 'Read which providers are configured on your system.'
        method_option :help, aliases: '-h', type: :boolean
        def get(*)
          if options[:help]
            invoke :help, ['get']
          else
            require_relative 'providers/get'
            Sfctl::Commands::Time::Providers::Get.new(options).execute
          end
        end
      end
    end
  end
end
