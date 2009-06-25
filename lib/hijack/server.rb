module Hijack
  def self.provide(context)
    puts ">> Providing evaluation within the context of #{context.inspect}."
    puts Thread.object_id
    DRb.start_service(socket_for(Process.pid), Context.new(context))
  end

  def self.socket_for(pid)
    "drbunix://tmp/hijack.#{pid}.sock"
  end

  class Context
    def initialize(context)
      @context = context
    end

    def evaluate(rb)
      $stdout = output = StringIO.new
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
end
