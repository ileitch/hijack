module Hijack
  module Helper
    class << self
      def helpers
        ['hijack_mute', 'hijack_unmute']
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
    end
  end
end
