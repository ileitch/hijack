module Hijack
  def self.provide(context, options={})
    name = options[:name] ? options[:name] : Process.pid
    if File.exists?(socket_for(name))
      $stderr.write("Socket file #{socket_for(name)} already exists! Hijack disabled.")
    else
      evaluator = Evaluator.new(context)
      DRb.start_service(socket_for(name), evaluator)
      File.chmod(0600, Hijack.socket_path_for(name))
      evaluator.enabled = true
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
