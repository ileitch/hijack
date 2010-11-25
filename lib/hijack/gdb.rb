# Based on gdb.rb by Jamis Buck, thanks Jamis!

module Hijack
  class GDB
    def initialize(pid)
      @pid = pid
      @verbose = Hijack.options[:debug]
      @exec_path = File.join(Config::CONFIG['bindir'], Config::CONFIG['RUBY_INSTALL_NAME'] + Config::CONFIG['EXEEXT'])
      attach
    end

    def eval(cmd)
      call("(void)rb_eval_string(#{cmd.strip.gsub(/"/, '\"').inspect})")
    end

    def detach
      return unless @gdb
      exec('detach')
      exec('quit')
      @backtrace = nil
      @gdb.close
      @gdb = nil
    end

  protected

    def attach
      loop do
        @gdb = IO.popen("gdb -q #{@exec_path} #{@pid} 2>&1", 'r+')
        wait
        if backtrace.first =~ /previous frame inner to this frame/i
          detach
          sleep 0.1
        else
          break
        end
      end
      
      # TODO: Check for "Unable to attach to process-id 44528: No child processes (10)"
      ensure_main_thread_not_blocked_by_join
      set_breakpoint
      continue
      delete_breakpoint
    end
    
    def set_breakpoint
      exec("break rb_call")
    end

    def delete_breakpoint
      exec("delete breakpoints")
    end

    def ensure_main_thread_not_blocked_by_join
      if backtrace.any? {|line| line =~ /rb_thread_join/}
        puts "\n=> Unable to hijack #{@pid} because the main thread is blocked waiting for another thread to join."
        puts "=> Check that you are using the most recent version of hijack, a newer version may have solved this shortcoming."
        detach
        exit 1
      end
    end

    def ensure_attached_to_ruby_process
      unless backtrace.any? {|line| line =~ /(rb|ruby)_/}
        puts "\n=> #{@pid} doesn't appear to be a Ruby process!"
        detach
        exit 1
      end
    end

    def backtrace
      @backtrace ||= exec('bt').reverse
    end

    def continue
      exec('continue')
    end

    def call(cmd)
      exec("call #{cmd}")
    end

    def exec(str)
      puts("(gdb) #{str}") if @verbose
      @gdb.puts(str)
      wait
    end

    def wait
      lines = []
      line = ''
      while result = IO.select([@gdb])
        next if result.empty?
        c = @gdb.read(1)
        break if c.nil?
        line << c
        break if line == "(gdb) " || line == " >"
        if line[-1] == ?\n
          lines << line
          line = ""
        end
      end
      puts lines.map { |l| "> #{l}" } if @verbose
      lines
    end
  end
end
