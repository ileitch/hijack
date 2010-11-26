module Hijack
  class OutputReceiver
    def self.pid
      @pid
    end
    
    def self.start(remote)
      @started = true
      @instance = new(remote)
      @pid = fork do
        @instance.start
      end
    end
    
    def self.started?
      @started
    end
    
    def self.stop
      Process.kill("KILL", @pid)
      Process.waitpid(@pid)
    end

    def self.mute
      Process.kill(Signal.list["USR1"], @pid) if started?
    end
    
    def self.unmute
      Process.kill(Signal.list["USR2"], @pid) if started?
    end
    
    def self.mute_momentarily
      Process.kill(Signal.list["HUP"], @pid) if started?
    end

    def initialize(remote)
      @remote = remote
    end
    
    def start
      setup_signal_traps
      DRb.start_service(Hijack.socket_for(Process.pid), self)
      @remote.evaluate("__hijack_output_receiver_ready_#{Process.pid}")
      DRb.thread.join
    end
        
    def setup_signal_traps
      Signal.trap("USR1") { mute }
      Signal.trap("USR2") { unmute }
      Signal.trap("HUP")  { mute_momentarily }
    end
    
    def mute
      @mute = true
      @explicit_mute = true
    end
    
    def unmute
      @mute = false
      @explicit_mute = false
    end
    
    def mute_momentarily
      @mute = true
      Thread.new do 
        sleep 3
        @mute = false unless @explicit_mute
      end
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