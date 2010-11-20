module Hijack
  class Payload
    def self.inject(pid)
      gdb = nil
      trap('SIGINT') do
        puts
        @received_sigint = true
      end
      gdb = GDB.new(pid)
      gdb.eval(payload(pid))
      gdb.detach
      exit if @received_sigint
    end

    def self.payload(pid)
      <<-RUBY
        require 'stringio'
        require 'drb'

        debug = #{Hijack.options[:debug] || false}
        if debug || !defined?(Hijack)
          puts 'Hijack: Debugging enabled' if debug
          module Hijack
            class OutputCopier
              def self.remote
                @remote
              end

              def self.stop
                @remote = nil
                [$stdout, $stderr].each do |io|
                  if io.respond_to?(:write_with_copying)
                    class << io
                      alias_method :write, :write_without_copying
                      remove_method :write_with_copying
                    end
                  end
                end
              end

              def self.start(pid)
                @remote = DRbObject.new(nil, 'drbunix://tmp/hijack.' + pid + '.sock')
                p @remote if Hijack.debug?

                class << $stdout
                  def write_with_copying(str)
                    write_without_copying(str)
                    begin
                      Hijack::OutputCopier.remote.write('stdout', str)
                    rescue Exception => e
                      write_without_copying(e.message) if Hijack.debug?
                      Hijack.stop
                    end
                  end
                  alias_method :write_without_copying, :write
                  alias_method :write, :write_with_copying
                end

                class << $stderr
                  def write_with_copying(str)
                    write_without_copying(str)
                    begin
                      Hijack::OutputCopier.remote.write('stderr', str)
                    rescue Exception => e
                      write_without_copying(e.message) if Hijack.debug?
                      Hijack.stop
                    end
                  end
                  alias_method :write_without_copying, :write
                  alias_method :write, :write_with_copying
                end
              end
            end

            class Evaluator
              def initialize(context)
                @context = context
                @file = __FILE__
              end

              def evaluate(rb)
                if rb =~ /__hijack_output_receiver_ready_([\\d]+)/
                  OutputCopier.start($1)
                elsif rb =~ /__hijack_get_remote_file_name/
                  @file
                elsif rb =~ /__hijack_exit/
                  Hijack.stop
                else
                  @context.instance_eval(rb)
                end
              end
            end

            def self.debug?
              @debug
            end

            def self.start(context, debug)
              return if @service && @service.alive?
              @debug = debug
              evaluator = Hijack::Evaluator.new(context)
              @service = DRb.start_service('#{Hijack.socket_for(pid)}', evaluator)
              File.chmod(0600, '#{Hijack.socket_path_for(pid)}')
            end

            def self.stop
              begin
                OutputCopier.stop
                @service.stop_service
                @service = nil
              rescue Exception
              end
            end
          end
        end
        Hijack.start(self, #{Hijack.options[:debug] || false})
      RUBY
    end
  end
end
