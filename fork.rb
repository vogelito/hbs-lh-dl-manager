#!/usr/bin/ruby

pid = Process.fork
if pid.nil? then
  puts "child"
  $stdin.close
  $stdout.close
  $stderr.close
  # In child
  exec "dl.rb #{ARGV[0]} #{ARGV[1]} > out/#{ARGV[2]}.log 2>&1"
else
  puts "parent"
  # In parent
  Process.detach(pid)
end

