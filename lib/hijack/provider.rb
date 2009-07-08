module Hijack
  def self.provide(context, options={})
    name = options[:name] ? options[:name] : Process.pid
    if File.exists?(socket_for(name))
      $stderr.write("Socket file #{socket_for(name)} already exists! Hijack disabled.")
    else
      DRb.start_service(socket_for(name), Context.new(context))
    end
  end

  class Context
    def initialize(context)
      @context = context
    end

    def evaluate(rb)
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
end
