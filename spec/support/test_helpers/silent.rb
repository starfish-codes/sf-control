module TestHelpers
  module Silent
    def silent_run(*args)
      out = Tempfile.new('sfctl-cmd')
      result = system(*args, out: out.path)

      return if result

      out.rewind
      raise "#{args.join} failed:\n#{out.read}"
    end
  end
end
