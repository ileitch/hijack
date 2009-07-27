module Hijack
  class Workspace < IRB::WorkSpace
    attr_accessor :remote, :pid
    def evaluate(context, statements, file = __FILE__, line = __LINE__)
      if statements =~ /(IRB\.|exit)/
        super
      else
        begin
          result = remote.evaluate(statements)
        rescue DRb::DRbConnError
          puts "=> Lost connection to #{@pid}!"
          exit 1
        end
        if result.kind_of?(DRb::DRbUnknown)
          puts "=> Hijack: Can't dump an object type that does not exist locally, try inspecting it instead."
          return nil
        end
        result
      end
    end
  end
end
