module Hijack
  class Workspace < IRB::WorkSpace
    attr_accessor :remote, :pid
    def evaluate(context, statements, file = __FILE__, line = __LINE__)
      if statements =~ /(IRB\.|exit)/
        super
      else
        begin
          evaluation = remote.evaluate(statements)
        rescue DRb::DRbConnError
          puts "=> Lost connection to #{@pid}!"
          exit 1
        end
        if evaluation.kind_of?(DRb::DRbUnknown)
          puts "=> Hijack: Can't dump an object type that does not exist locally, try inspecting it instead."
          nil
        else
          $stdout.write(evaluation.output)
          $stdout.flush
          evaluation.result
        end
      end
    end
  end
end
