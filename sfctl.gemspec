require_relative 'lib/sfctl/version'

Gem::Specification.new do |spec|
  spec.name = 'sfctl'
  spec.license = 'MIT'
  spec.version = Sfctl::VERSION
  spec.authors = ['Serhii Rudik', 'Markus Kuhnt']
  spec.email = ['hello@starfish.codes']
  spec.homepage = 'https://github.com/alphatier-works/sfctl'
  spec.summary = 'sfctl is a command line interface for the Starfish API.'
  # spec.homepage      = ''
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata = {
    "bug_tracker_uri"   => "https://github.com/alphatier-works/sfctl/issues",
    "source_code_uri"   => "https://github.com/alphatier-works/sfctl",
  }

  # Add sfctl's dependencies
  spec.add_runtime_dependency 'faraday', '~> 1.0'
  spec.add_runtime_dependency 'pastel', '~> 0.7'
  spec.add_runtime_dependency 'rake', '~> 12.0'
  spec.add_runtime_dependency 'thor', '~> 1.0'
  spec.add_runtime_dependency 'tty-box', '~> 0.5.0'
  spec.add_runtime_dependency 'tty-color', '~> 0.5.1'
  spec.add_runtime_dependency 'tty-command', '~> 0.9.0'
  spec.add_runtime_dependency 'tty-config', '~> 0.4.0'
  spec.add_runtime_dependency 'tty-cursor', '~> 0.7.1'
  spec.add_runtime_dependency 'tty-editor', '~> 0.5.1'
  spec.add_runtime_dependency 'tty-file', '~> 0.8.0'
  spec.add_runtime_dependency 'tty-font', '~> 0.5.0'
  spec.add_runtime_dependency 'tty-link', '~> 0.1.1'
  spec.add_runtime_dependency 'tty-logger', '~> 0.3.0'
  spec.add_runtime_dependency 'tty-markdown', '~> 0.6.0'
  spec.add_runtime_dependency 'tty-pager', '~> 0.12.1'
  spec.add_runtime_dependency 'tty-pie', '~> 0.3.0'
  spec.add_runtime_dependency 'tty-platform', '~> 0.3.0'
  spec.add_runtime_dependency 'tty-progressbar', '~> 0.17.0'
  spec.add_runtime_dependency 'tty-prompt', '~> 0.21.0'
  spec.add_runtime_dependency 'tty-reader', '~> 0.7.0'
  spec.add_runtime_dependency 'tty-screen', '~> 0.8.1'
  spec.add_runtime_dependency 'tty-spinner', '~> 0.9.3'
  spec.add_runtime_dependency 'tty-table', '~> 0.11.0'
  spec.add_runtime_dependency 'tty-tree', '~> 0.4.0'
  spec.add_runtime_dependency 'tty-which', '~> 0.4.2'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
