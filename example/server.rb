require '../lib/hijack'

thread = Thread.new do
  puts "Hijack Example Server"
  puts '====================='
  puts ">> PID #{Process.pid}"
  Hijack.provide(self)
  puts ">> Waiting for a client to connect..."
  while true
    sleep 1
  end
end

thread.join