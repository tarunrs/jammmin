
app_root = ENV['WEBSERVER_ROOT']
libs = `ls #{app_root}/lib`.split("\n")
puts 'libs are: ' + libs.inspect
libs.each do |lib| require "#{app_root}/lib/#{lib}" end

# Include List

to_load = [Utils, UserUtils, Extensions, SongUtils, JamUtils]

to_load.each do |lib| include lib end
  

