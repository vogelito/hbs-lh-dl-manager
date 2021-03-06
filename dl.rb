#!/usr/bin/ruby

require "mechanize"
require "nokogiri"
require 'fileutils'
require 'filemagic'
require 'mime/types'
require 'readline'
require 'highline/import'

def sanitize_filename(filename)
  if !filename.nil?
    return filename.to_s.gsub(/[\r\n]/,'').gsub(/[^0-9A-Za-z%.\,'\-_ \(\)\[\]\&\+]/, '_').gsub(/_+/,'_').gsub(/_$/,'')
  end
end

def log_die(msg)
  puts msg
  Process.exit 1
end

def lock(file)
  # Attempts an exclusive lock and returns immediately. Returns false if
  # an exclusive lock was not obtained.
  f = File.open(file, File::RDWR|File::CREAT, 0644)
  locked = f.flock(File::LOCK_NB|File::LOCK_EX)
  log_die("unable to lock file #{file}") if !locked

  return f
end

# Get HBS credentials
zip_file = false
if ARGV.length == 2
  user = ARGV[0].strip
  pass = ARGV[1].strip
  zip_file = true
  require "./ZipFileGenerator.rb"
else
  user = Readline.readline("Username: ", true)
  pass = ask("Password: ") { |q| q.echo = false }
end

errors = ""
a = Mechanize.new { |agent| agent.user_agent_alias = "Mac Safari" }
a.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE

puts "Starting..."
STDOUT.flush

u = user.gsub(/@.*/, "")
lock_file = "out/#{u}.lock"
lf = lock(lock_file)

fm = FileMagic.new(:mime_type)
p_login = a.get('https://secure.hbs.edu/login/index.html')
form = p_login.form
form['username'] = user
form['password'] = pass

zip_folder = "out/#{u}_#{Time.now.to_i}#{rand(1000)}"
output_file = "out/#{u}.zip"
File.delete(output_file) if File.exist?(output_file)

p_success = form.submit 

html_doc = Nokogiri::HTML(p_success.body)

log_die("Unable to log in") if html_doc.css("h2").text != 'You Are Logged In'

puts "Logged in"
STDOUT.flush

# get list of courses
hash = Hash.new
a.get('https://lh.hbs.edu').body.scan(/<a href="\/d2l\/lp\/ouHome\/home.d2l\?ou=(\d+)" title="Enter ([^"]+)">/) {|x,y| hash[x] = y }
log_die("Unable to find courses") if hash.length == 0
puts "You are enrolled in #{hash.length} courses"
STDOUT.flush
hash.keys.each do |course_id|
  puts "Fetching: #{course_id} #{hash[course_id]}"
  STDOUT.flush
  url = 'https://lh.hbs.edu/d2l/lms/content/print/print_download.d2l?ou=' + course_id
  out_folder = zip_folder + '/' + sanitize_filename(hash[course_id]) + '/'
  preview_url = 'https://lh.hbs.edu/d2l/lms/content/preview.d2l?ou='+course_id+'&tId='
  p_toc = a.get(url).body
  toc_doc = Nokogiri::HTML(p_toc)
  cnt = 1
  toc_doc.css('tr.d_ggl1').each do |itm|
    i_title = itm.css('td.d_gn').text
    puts sanitize_filename i_title
    STDOUT.flush
    i_lastchild = itm.parent.last_element_child
    i_child = itm.next_element
    has_validchild=false
    while !i_child.nil? && i_child['class'] != 'd_ggl1' && i_child != i_lastchild
      has_validchild=true
      out_curfolder = out_folder+('%03d ' % cnt.to_s)+sanitize_filename(i_title)+'/'
      FileUtils.mkpath(out_curfolder) unless Dir.exists?(out_curfolder)
      dl_link = i_child.css('a.D2LLink')
      puts " > " + dl_link.text
      STDOUT.flush
      dl_file = preview_url + dl_link.attr('onclick').text.match(/PreviewTopic\((\d+)\,/)[1]
      puts " >> " + dl_file
      STDOUT.flush
      content_url = Nokogiri::HTML(a.get(dl_file).body).css('#frContentFile').attr('src').text
      puts " >+ " + content_url
      STDOUT.flush
      begin
        file_content = a.get(content_url)
        file_type = fm.buffer(file_content.body)
        file_ext = MIME::Types[file_type].first.extensions.first
        puts " ># " + file_type+ ' --> ' + file_ext
        STDOUT.flush
        file_content.save(out_curfolder+sanitize_filename(dl_link.text)+'.'+file_ext)
      rescue
        errors << content_url + "\n"
      end

      i_child = i_child.next_element
    end
    cnt = cnt+1 unless !has_validchild
  end
end

if errors != "" 
  puts "ERRORS:\n"+errors
  STDOUT.flush
else
  puts "Finished downloading without errors"
  STDOUT.flush
end

if zip_file
  zf = ZipFileGenerator.new(zip_folder, output_file)
  zf.write()
  FileUtils.chmod(644, output_file)
end

puts "Zip file available: #{output_file}"
STDOUT.flush
lf.close
