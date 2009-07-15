module Hijack
  class Evaluation
    attr_reader :result, :output
    def initialize(result, output)
      @result = result
      @output = output
    end
  end

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
            class Evaluator
              attr_writer :enabled

              def initialize(context)
                @context = context
                @enabled = false
              end

              def evaluate(rb)
                return unless @enabled
                output = StringIO.new
                $stdout = output
                Evaluation.new(@context.instance_eval(rb), output.string)
              end
            end

            class Evaluation
              attr_reader :result, :output
              def initialize(result, output)
                @result = result
                @output = output
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
