module TestHelpers
  module Paths
    def gem_root
      File.expand_path("#{File.dirname(__FILE__)}/..")
    end

    def dir_path(*args)
      path = File.join(gem_root, *args)
      FileUtils.mkdir_p(path) unless File.exist?(path)
      File.realpath(path)
    end

    def tmp_path(*args)
      File.join(dir_path('../../tmp'), *args)
    end

    def fixtures_path(*args)
      File.join(dir_path('../../spec/fixtures'), *args)
    end

    def within_dir(target, &block)
      ::Dir.chdir(target, &block)
    end
  end
end
