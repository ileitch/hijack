$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'hijack'

  puts <<-EOS
Welcome to Hijack!
==================

This example demonstrates how to use Hijack in your long-running apps.
All you need to do is call Hijack.provide(self) before your app enters its main loop,
you'll then be able to connect to the app via the command 'hijack <PID>'.
Instead of using the process ID to connect with, you can instead give your Hijacked app a name,
for example: Hijack.provide(self, :name => 'HijackExample').

Open up a new terminal window and run 'hijack Example' to connect to this process.
You'll then have access to the context of this app just as if it were a local IRB session!

Example:

$ hijack Example
=> Hijacked Example (example.rb) (ruby 1.8.7 [i686-darwin9])
>> puts self
main
=> nil
>> puts Process.pid
1234
=> nil
>> 1 + 1
=> 2
EOS

Hijack.provide(self, :name => 'Example')

while true
  sleep 1
end
