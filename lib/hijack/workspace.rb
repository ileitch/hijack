module Hijack
  Readline.completion_proc = Proc.new do |input|
    bind = IRB.conf[:MAIN_CONTEXT].workspace.binding
    if helpers = Helper.helpers_like(input)
      OutputReceiver.mute_momentarily
      helpers
    else
      IRB::InputCompletor::CompletionProc.call(input)
    end
  end

  class Workspace < IRB::WorkSpace
    attr_accessor :remote, :pid
    def evaluate(context, statements, file = __FILE__, line = __LINE__)
      if statements =~ /IRB\./
        super
      elsif statements.strip =~ /^(exit|quit)/
        remote.evaluate('Hijack.stop') rescue nil
        super
      elsif helper = Hijack::Helper.find_helper(statements)
        Hijack::Helper.send(helper, remote)
      else
        begin
          result = remote.evaluate(statements)
        rescue DRb::DRbConnError => e
          puts "=> Lost connection to #{@pid}!"
          exit 1
        end
        if result.kind_of?(DRb::DRbUnknown)
          puts "=> Hijack: Unable to dump unknown object type '#{result.name}', try inspecting it instead."
          return nil
        end
        result
      end
    end
  end
end
