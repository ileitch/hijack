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
    Array.new(1000000).collect {|i| "#{i}"}
    do_shit(i+=1)
  end
end

t.join