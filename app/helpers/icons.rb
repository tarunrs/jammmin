# ICONS 

ICONS = {
  :song => "/images/icons/staff.png",
  :jam => "/images/icons/8thnote.png",
  :notifications => "/images/icons/notification.png",
  :following => "/images/icons/follow2.png",
  :followers => "/images/icons/followers1.png",
  :profile => "/images/icons/profile-header.png",
  :profile1 => "/images/icons/profile1.png",
  :manage => "/images/icons/manage1.png",
  :jammmin => "/images/icons/miniicon.png",
  :add => "/images/icons/add.png",
  :like => "/images/icons/like.png",
  :unlike => "/images/icons/unlike1.png",
  :play => "/images/icons/play.png",
  :play2 => "/images/icons/play1.png",
  :comments => "/images/icons/comments4.png",
  :user => "/images/icons/user.png",
  :collaborators => "/images/icons/collaborate.png",
  :update => "/images/icons/update.png",
  :message => "/images/icons/msg.png",
  :home => "/images/icons/home.png",
  :help => "/images/icons/help1.png",
  :jam_page => "/images/icons/jampage.png",
  :song_page => "/images/icons/songpage1.png",
  :back => "/images/icons/back1.png",
  :refresh => "/images/icons/refresh.png",
  :unfollow => "/images/icons/unfollow1.png",
  :login => "/images/icons/login1.png",
  :logout => "/images/icons/logout1.png"
}

def add_icon(icon=false)
  "<img src='/images/common/icon.png'>"
end

def medium_icon(icon='/images/common/icon.png')
  "<img src='#{icon}' height=32 width=32>"
end

def small_icon(icon='/images/common/icon.png')
  "<div class='small-icon'><img src='#{icon}' height='100%' width='100%'></div>"
end

def header_icon(icon)
  "<img src='#{icon}' height='30px'>"  
end

def icon(id, type=:small)
  img_path = get_img_path(id)
  str = "#{type}_icon('#{img_path}')"
  eval(str)
end

def get_img_path(id)
  return ICONS[id] if ICONS[id]
  webserver_root = ENV["WEBSERVER_ROOT"]
  png_path = "#{webserver_root}/public/images/icons/#{id.to_s}.png"  
  return "/images/icons/#{id.to_s}.png" if File.exists?(png_path)
end



def add_icon_with_pad(icon=false)
  "<span class='left-float pad-right-10'>#{add_icon(icon)}</span>"
end
