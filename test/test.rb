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
    Array.new(3000000).collect {|n| "#{n}"}
    do_shit(i+=1)
  end
end

t.join