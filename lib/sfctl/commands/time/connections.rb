require 'thor'

module Sfctl
  module Commands
    class Time
      class Connections < Thor
        namespace :connections

        desc 'add', 'This command will add a connection between a provider and an assignment.'
        method_option :help, aliases: '-h', type: :boolean
        def add(*)
          if options[:help]
            invoke :help, ['add']
          else
            require_relative 'connections/add'
            Sfctl::Commands::Time::Connections::Add.new(options).execute
          end
        end

        desc 'get', 'List all known connections in that project.'
        method_option :help, aliases: '-h', type: :boolean
        def get(*)
          if options[:help]
            invoke :help, ['get']
          else
            require_relative 'connections/get'
            Sfctl::Commands::Time::Connections::Get.new(options).execute
          end
        end
      end
    end
  end
end
