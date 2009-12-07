

def partial(page, options={})
  page = page.to_s
  puts "page is: " + page
  return "&nbsp;" if page.empty? or not page or page.nil? or page.split("/").include?('nil')
  erb(:"#{page}", options.update({:layout => false}))
end

def redirect_home
  redirect '/account'
end

def redirect_signin
  redirect '/signin'
end

def redirect_manage_jam(jam)
  redirect "/jam/#{jam.id}/manage"
end

def redirect_manage_song(song)
  redirect "/song/#{song.id}/manage"
end

def show_profile(username)
  redirect "/#{username}"
end

def section_header(text, options={})
  [
    "<div>",
      "<span class='float-left bold'>#{text.capitalize}</span>",
    "</div>",
    "<hr class='thin'>"
  ].join('')
end

def add_feed_item(text)
end

def add_menu_entry(text, link, image_url)
	"<div>
		<a title='#{text}' href='#{link}' class='bold grey display-inline'>
		  <div>
  		  <span class='float-left'>#{text}</span>
	  	  <span class='float-right'>#{add_icon()}</span>
	  	</div>
		</a>
	</div>"
end


def add_link(text, href='', options={})
  class_names = "simple-link " + (options[:class_names] or "")
  "<span class='#{class_names} display-inline'><a href='#{href}'>#{text}</a></span>"
end

def link(text, options={})
  options[:class] = "simple-link display-inline " + (options[:class] || "")
  attrs = options.map{|k,v| "#{k.to_s}='#{v}'"}.join(' ')
  "<span #{attrs}>" + text + "</span>"
end

def add_icon(icon=false)
  "<img src='/images/common/icon.png'>"
end

def add_icon_with_pad(icon=false)
  "<span class='left-float pad-right-10'>#{add_icon(icon)}</span>"
end

def add_field_name(text)
  "<span class='display-inline bold grey'>" + text + ":</span>"
end

def add_profile_link(user)
  add_link(user.name, ("/" + user.username)) rescue ""
end
alias profile_link add_profile_link

def jam_link(jam)
  add_link(jam.name, ("/jam/" + jam.id.to_s))
end

def song_link(song)
  add_link(song.name, ("/song/" + song.id.to_s))
end

def list_artists(artists)
  partial(:'common/list_artists', {:locals => {:artists => artists}})
end

def manage_if_not_signed_in
  redirect_signin if not session[:username]
end

def display_published
  "<span class='bold display-inline' style='color: green'>PUBLISHED</span>"
end

def display_unpublished
  "<span class='bold display-inline' style='color: red'>UNPUBLISHED</span>"  
end

def display_jam_type(jam)
  return "Song Jam" if jam.jam_type == :song_jam
  jam.jam_type == :published ? "Published" : "Unpublished"
end

def session_user? 
  @session_user if @session_user
end

def load_player(player_type=nil)
  partial("common/player", {:locals => {:player_type => player_type}})
end

def format_lyrics(lyrics)
  return "" if not lyrics
  lyrics.gsub("\n", "<br>")
end

load 'helpers/profile.rb'
