# Based on gdb.rb by Jamis Buck, thanks Jamis!

module Hijack
  class GDB
    def initialize(pid)
      @pid = pid
      @verbose = Hijack.options[:debug]
      @exec_path = File.join(Config::CONFIG['bindir'], Config::CONFIG['RUBY_INSTALL_NAME'] + Config::CONFIG['EXEEXT'])
      attach_outside_gc
    end

    def eval(cmd)
      call("(void)rb_eval_string(#{cmd.strip.gsub(/"/, '\"').inspect})")
    end

    def quit
      return unless @gdb
      detach
      exec('quit')
      @backtrace = nil
      @gdb.close
      @gdb = nil
    end

  protected

    def previous_frame_inner_to_this_frame?
      backtrace.first =~ /previous frame inner to this frame/i
    end

    def attach_outside_gc
      @gdb = IO.popen("gdb -q #{@exec_path} #{@pid} 2>&1", 'r+')
      wait
      ensure_attached_to_ruby_process
      attached = false

      3.times do |i|
        attach unless i == 0

        if previous_frame_inner_to_this_frame? || during_gc?
          detach
          sleep 0.1
        else
          attached = true
          break
        end
      end

      unless attached
        puts
        puts "=> Tried 3 times to attach to #{@pid} whilst GC wasn't running but failed."
        puts "=> This means either the process calls GC.start frequently or GC runs are slow - try hijacking again."
        exit 1
      end

      # TODO: Check for "Unable to attach to process-id 44528: No child processes (10)"
      ensure_main_thread_not_blocked_by_join
    end
    
    def during_gc?
      backtrace.any? { |line| line =~ /garbage_collect/i }
    end
    
    def detach
      exec("detach")
    end
    
    def attach
      exec("attach #{@pid}")
    end
    
    def ensure_main_thread_not_blocked_by_join
      if backtrace.any? { |line| line =~ /rb_thread_join/ }
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
