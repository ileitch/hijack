require 'irb'

module Hijack
  class Console
    def self.start(name)
      new(name)
    end

    def initialize(name)
      @name = name
      @remote = nil
      if File.exists?(Hijack.socket_path_for(@name))
        connect
        start_irb
      else
        puts "=> Unable to connect: #{Hijack.socket_path_for(@name)} does not exist!"
      end
    end

  protected
    def connect
      @remote = DRbObject.new(nil, Hijack.socket_for(@name))
      mirror_remote
      script, version, platform = @remote.evaluate('[$0, RUBY_VERSION, RUBY_PLATFORM]').result
      puts "=> Hijacked #{@name} (#{script}) (ruby #{version} [#{platform}])"
    end

    def mirror_remote
      # Attempt to require all files currently loaded by the remote process so DRb can dump as many objects as possible.
      str = "=> Mirroring remote process..."
      $stdout.write(str)
      $stdout.flush
      load_path, loaded_files = @remote.evaluate('[$:, $"]').result
      $:.clear
      $:.push(*load_path)

      # We have to first require everything in reverse order and then in the original order.
      # This is because when you require file_a.rb which first sets a constant then requires file_b.rb
      # the $" array will contain file_b.rb before file_a.rb. But if we require file_b.rb before file_a.rb
      # we'll get a missing constant error.
      orig_stderr = $stderr
      $stderr = File.open('/dev/null')
      to_load = (loaded_files - $").uniq
      to_load.reverse.map do |file|
        begin
          require file
        rescue Exception, LoadError
        end
      end
      to_load.map do |file|
        begin
          require file
        rescue Exception, LoadError
        end
      end
      $stderr = orig_stderr
      $stdout.write("\b" * str.size)
      $stdout.flush
    end

    def start_irb
      ARGV.replace ["--simple-prompt"]
      IRB.setup(nil)
      workspace = DRbWorkspace.new
      workspace.remote = @remote
      irb = IRB::Irb.new(workspace)
      @CONF = IRB.instance_variable_get(:@CONF)
      @CONF[:IRB_RC].call irb.context if @CONF[:IRB_RC]
      @CONF[:MAIN_CONTEXT] = irb.context
      @CONF[:PROMPT_MODE] = :SIMPLE
      trap('SIGINT') { irb.signal_handle }
      catch(:IRB_EXIT) { irb.eval_input }
    end
  end

  class DRbWorkspace < IRB::WorkSpace
    attr_accessor :remote
    def evaluate(context, statements, file = __FILE__, line = __LINE__)
      if statements =~ /(IRB\.|exit)/
        super
      else
        evaluation = remote.evaluate(statements)
        if evaluation.kind_of?(DRb::DRbUnknown)
          puts "=> Hijack: Can't dump an object type that does not exist locally, try inspecting it instead."
          nil
        else
          $stdout.write(evaluation.output)
          $stdout.flush
          evaluation.result
        end
      end
    end
  end
end




