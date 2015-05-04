#!/usr/bin/ruby

require 'cgi'

cgi = CGI.new("html3")

h = cgi.params
e = h['email']
lhp = h['lhp']
u = e[0].gsub(/@.*/, "")
if e == nil
  puts cgi.header
  puts "
<html>
  <head>
    <title>LH Course Content DL Manager</title>
  </head>
  <body>
    An unknown error occurred...
  </body>
</html>"
else
#  puts cgi.header
#  puts "yayy"
#  puts lhp
  pid = Process.fork
  if pid.nil? then
    $stdin.close
    $stdout.close
    $stderr.close
    # In child
    exec "fork.rb #{e} #{lhp} #{u}"
  else
    # In parent
    Process.detach(pid)
  end
  puts cgi.header("Location" => "wait.php?e=#{u}") 
end
