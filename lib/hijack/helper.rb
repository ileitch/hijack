module Hijack
  module Helper
    class << self
      def helpers
        methods.find_all {|meth| meth =~ /^hijack_/}
      end

      def find_helper(statements)
        helpers.include?(statements.strip) ? statements.strip : nil
      end

      def helpers_like(str)
        found = helpers.find_all { |helper| helper =~ Regexp.new(str) }
        found.empty? ? nil : found
      end

      def hijack_mute(remote)
        Hijack::Console::OutputReceiver.mute
        true
      end

      def hijack_unmute(remote)
        Hijack::Console::OutputReceiver.unmute
        true
      end

      def hijack_debug_mode(remote)
        hijack_mute(remote)
        require 'rubygems'
        require 'ruby-debug'
        remote.evaluate(<<-RB)
          require 'rubygems'
          require 'ruby-debug'
          Debugger.start_remote
        RB
        true
      end

      def hijack_debug_start(remote)
        Debugger.start_client
        true
      end
    end
  end
end
