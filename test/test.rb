#!/usr/bin/ruby

class SomeClass
end

def do_shit(i)
  puts i
end

p Process.pid

t = Thread.new do
  i = 0
  loop do
    sleep 1
    do_shit(i+=1)
  end
end

t.join