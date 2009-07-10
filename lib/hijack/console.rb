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
      script, ruby_version, platform, hijack_version = @remote.evaluate('[$0, RUBY_VERSION, RUBY_PLATFORM, Hijack.version]').result
      if hijack_version != Hijack.version
        puts "!! WARNING: Remote process is running #{hijack_version} yet you are connecting with #{Hijack.version}."
      end
      puts "=> Hijacked #{@name} (#{script}) (ruby #{ruby_version} [#{platform}])"
    end

    def mirror_remote
      # Attempt to require all files currently loaded by the remote process so DRb can dump as many objects as possible.
      #
      # We have to first require everything in reverse order and then in the original order.
      # This is because when you require file_a.rb which first sets a constant then requires file_b.rb
      # the $" array will contain file_b.rb before file_a.rb. But if we require file_b.rb before file_a.rb
      # we'll get a missing constant error.
      load_path, loaded_files = @remote.evaluate('[$:, $"]').result
      to_load = (loaded_files - $").uniq
      return if to_load.empty?
      completion_percentage = 0
      str = '=> Mirroring remote process: '
      percent_str = ''
      $stdout.write(str)
      $stdout.flush
      $:.clear
      $:.push(*load_path)
      orig_stderr = $stderr
      $stderr = File.open('/dev/null')
      (to_load.reverse + to_load).each_with_index do |file, i|
        begin
          require file
        rescue Exception, LoadError
        end
        $stdout.write("\b" * percent_str.size)
        $stdout.flush
        percent_str = "#{(((i + 1) / (to_load.size * 2).to_f) * 100.0).round}%"
        $stdout.write(percent_str)
        $stdout.flush
      end
      $stderr = orig_stderr
      $stdout.write("\b" * (str.size + percent_str.size))
      $stdout.flush
    end

    def start_irb
      ARGV.replace ["--simple-prompt"]
      IRB.setup(nil)
      workspace = DRbWorkspace.new
      workspace.remote = @remote
      workspace.remote_name = @name
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
    attr_accessor :remote, :remote_name
    def evaluate(context, statements, file = __FILE__, line = __LINE__)
      if statements =~ /(IRB\.|exit)/
        super
      else
        begin
          evaluation = remote.evaluate(statements)
        rescue DRb::DRbConnError
          puts "=> Lost connection to #{@remote_name}!"
          exit 1
        end
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




