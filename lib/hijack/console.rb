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

    def connect
      @remote = DRbObject.new(nil, Hijack.socket_for(@name))
      script, version, platform = @remote.evaluate('[$0, RUBY_VERSION, RUBY_PLATFORM]').result
      puts "=> Hijacked #{@name} (#{script}) (ruby #{version} [#{platform}])"
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
      statements =~ /(IRB\.|exit)/ ? super : remote.evaluate(statements).result
    end
  end
end




