module Hijack
  class Payload
    def self.inject(pid)
      gdb = GDB.new(pid)
      unless gdb.attached_to_ruby_process?
        puts "\n=> #{pid} doesn't appear to be a Ruby process!"
        exit 1
      end
      gdb.eval(payload(pid))
      gdb.detach
    end

    def self.payload(pid)
      <<-EOS
        require 'stringio'
        require 'drb'

        unless defined?(Hijack)
          module Hijack
            module CopiedOutput
            end

            module CopiedStdout
              def self.orig=(obj)
                @@orig = obj
              end

              def self.remote=(obj)
                @@remote = obj
              end

              def self.write(str)
                @@remote.write('stdout', str)
                @@orig.write(str)
              end

              def self.puts(str)
                @@remote.puts('stdout', str)
                @@orig.puts(str)
              end
            end

            module CopiedStderr
              def self.orig=(obj)
                @@orig = obj
              end

              def self.remote=(obj)
                @@remote = obj
              end


              def self.write(str)
                @@remote.write('stderr', str)
                @@orig.write(str)
              end

              def self.puts(str)
                @@remote.puts('stderr', str)
                @@orig.puts(str)
              end
            end

            class OutputCopier
              def self.start(pid)
                remote = DRbObject.new(nil, 'drbunix://tmp/hijack.' + pid + '.sock')
                CopiedStdout.remote = remote
                CopiedStderr.remote = remote
                CopiedStdout.orig = $stdout
                CopiedStderr.orig = $stderr
                $stdout = CopiedStdout
                $stderr = CopiedStderr
              end
            end

            class Evaluator
              attr_writer :enabled

              def initialize(context)
                @context = context
                @enabled = false
              end

              def evaluate(rb)
                return unless @enabled
                if rb =~ /__hijack_output_receiver_ready_([\\d]+)/
                  OutputCopier.start($1)
                  return
                end
                @context.instance_eval(rb)
              end
            end

            def self.start(context)
              return if @service && @service.alive?
              evaluator = Hijack::Evaluator.new(context)
              @service = DRb.start_service('#{Hijack.socket_for(pid)}', evaluator)
              File.chmod(0600, '#{Hijack.socket_path_for(pid)}')
              # TODO: This could just as easily be called by the client...
              evaluator.enabled = true
            end
          end
        end
        __hijack_context = self
        Signal.trap('USR1') { Hijack.start(__hijack_context) }
      EOS
    end
  end
end
