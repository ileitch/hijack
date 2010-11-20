module Hijack
  class OutputReceiver
    attr_reader :pid
    
    def self.start(remote)
      @instance = new(remote)
      @instance.start
    end
    
    def self.stop
      @instance.stop if @instance
    end

    def self.mute
      @instance.mute if @instance
    end
    
    def self.unmute
      @instance.unmute if @instance
    end

    def initialize(remote)
      @remote = remote
    end
    
    def start
      @pid = fork do
        setup_signal_traps
        DRb.start_service(Hijack.socket_for(Process.pid), self)
        @remote.evaluate("__hijack_output_receiver_ready_#{Process.pid}")
        DRb.thread.join
      end
    end
    
    def stop
      Process.kill("KILL", @pid)
      Process.waitpid(@pid)
    end
    
    def setup_signal_traps
      Signal.trap("USR1") { @mute = true }
      Signal.trap("USR2") { @mute = false }
    end
    
    def mute
      Process.kill("USR1", @pid)
    end
    
    def unmute
      Process.kill("USR2", @pid)
    end
    
    def write(io, str)
      return if @mute
      get_io(io).write(str)
    end
    
    def puts(io, str)
      return if @mute
      get_io(io).puts(str)
    end

    def get_io(io)
      case io.to_s
      when 'stdout'
        $stdout
      when 'stderr'
        $stderr
      else
        raise "get_io cannot handle '#{io}'"
      end
    end
  end
end