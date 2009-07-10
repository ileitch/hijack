$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'hijack'

NAME = 'Example'

Hijack.provide(self, :name => NAME)


puts <<-EOS
Welcome to the Hijack example!

You can now connect to this process, e.g:

$ hijack Example
=> Hijacked Example (example.rb) (ruby 1.8.7 [i686-darwin9])
>> 
EOS

while true
  sleep 1
end
