require "mechanize"
require "nokogiri"
require 'fileutils'
require 'filemagic'
require 'mime/types'
require 'readline'
require 'highline/import'

#Note: Script will save downloads to "out_<date>" folder in current working directory.

#HBS Usernamne:
#user = Readline.readline("Username: ", true)
#HBS Password:
#pass = ask("Password: ") { |q| q.echo = false }
#Course id (found in URL of LH if you open a course after "?ou="
#eg: https://lh.hbs.edu/d2l/lp/homepage/home.d2l?ou=51719
#course_id = Readline.readline("Course ID: ", true)

#END of config
################


#url = 'https://lh.hbs.edu/d2l/lms/content/print/print_download.d2l?ou=' + course_id
#out_folder = "out_" + Time.now.strftime("%y%m%d") + '/' + course_id + '/'
#preview_url = 'https://lh.hbs.edu/d2l/lms/content/preview.d2l?ou='+course_id+'&tId='

def sanitize_filename(filename)
  if !filename.nil?
    return filename.to_s.gsub(/[\r\n]/,'').gsub(/[^0-9A-Za-z%.\,'\-_ \(\)\[\]\&\+]/, '_').gsub(/_+/,'_').gsub(/_$/,'')
  end
end

def log_die(msg)
  puts msg
  Process.exit 1
end

errors = ""
a = Mechanize.new { |agent| agent.user_agent_alias = "Mac Safari" }
a.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE

puts "Starting..."

fm = FileMagic.new(:mime_type)
p_login = a.get('https://secure.hbs.edu/login/index.html')
form = p_login.form
form['username'] = user
form['password'] = pass

p_success = form.submit 

html_doc = Nokogiri::HTML(p_success.body)

log_die("Unable to log in") if html_doc.css("h2").text != 'You Are Logged In'

puts "Logged in"

# get list of courses
hash = Hash.new
a.get('https://lh.hbs.edu').body.scan(/<a href="\/d2l\/lp\/ouHome\/home.d2l\?ou=(\d+)" title="Enter ([^"]+)">/) {|x,y| hash[x] = y }
log_die("Unable to find courses") if hash.length == 0
puts "You are enrolled in the following courses"
hash.keys.each do |x|
  puts "#{x} #{hash[x]}"
end

p_toc = a.get(url).body
toc_doc = Nokogiri::HTML(p_toc)
cnt = 1
toc_doc.css('tr.d_ggl1').each do |itm|
  i_title = itm.css('td.d_gn').text
  puts sanitize_filename i_title
  i_lastchild = itm.parent.last_element_child
  i_child = itm.next_element
  has_validchild=false
  while !i_child.nil? && i_child['class'] != 'd_ggl1' && i_child != i_lastchild
    has_validchild=true
    out_curfolder = out_folder+('%03d ' % cnt.to_s)+sanitize_filename(i_title)+'/'
    FileUtils.mkpath(out_curfolder) unless Dir.exists?(out_curfolder)
    dl_link = i_child.css('a.D2LLink')
    puts " > " + dl_link.text
    dl_file = preview_url + dl_link.attr('onclick').text.match(/PreviewTopic\((\d+)\,/)[1]
    puts " >> " + dl_file
    content_url = Nokogiri::HTML(a.get(dl_file).body).css('#frContentFile').attr('src').text
    puts " >+ " + content_url
    begin
      file_content = a.get(content_url)
      file_type = fm.buffer(file_content.body)
      file_ext = MIME::Types[file_type].first.extensions.first
      puts " ># " + file_type+ ' --> ' + file_ext
      file_content.save(out_curfolder+sanitize_filename(dl_link.text)+'.'+file_ext)
    rescue
      errors << content_url + "\n"
    end

    i_child = i_child.next_element
  end
  cnt = cnt+1 unless !has_validchild
end

if errors != "" 
  puts "ERRORS:\n"+errors
end
puts "Done without errors"


