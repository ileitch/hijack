# Based on gdb.rb by Jamis Buck, thanks Jamis!

module Hijack
  class GDB
    def initialize(pid)
      @verbose = Hijack.options[:gdb_debug]
      exec_path = File.join(Config::CONFIG['bindir'], Config::CONFIG['RUBY_INSTALL_NAME'] + Config::CONFIG['EXEEXT'])
      @gdb = IO.popen("gdb -q #{exec_path} #{pid} 2>&1", 'r+')
      wait
    end

    def attached_to_ruby_process?
      backtrace.any? {|line| line =~ /ruby_run/}
    end

    def main_thread_blocked_by_join?
      backtrace.any? {|line| line =~ /rb_thread_join/}
    end

    def eval(cmd)
      set_trap_pending
      set_breakpoint
      continue
      clear_breakpoint
      call("(void)rb_eval_string(#{cmd.strip.gsub(/"/, '\"').inspect})")
    end

    def detach
      exec('detach')
      exec('quit')
      @gdb.close
    end

  protected
    def backtrace
      @backtrace ||= exec('bt').reverse
    end

    def set_trap_pending
      exec("set variable (int)rb_trap_pending=1")
    end

    def set_breakpoint
      exec("break rb_trap_exec")
    end

    def clear_breakpoint
      exec("clear rb_trap_exec")
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
