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
      # TODO: Implement me
      true
    end

    def eval(cmd)
      call("(void)rb_eval_string(#{cmd.strip.gsub(/"/, '\"').inspect})")
    end

    def detach
      @gdb.puts('detach')
      wait
      @gdb.puts('quit')
      @gdb.close
    end

  protected
    def call(cmd)
      puts "(gdb) call #{cmd}" if @verbose
      @gdb.puts("call #{cmd}")
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
    end
  end
end
