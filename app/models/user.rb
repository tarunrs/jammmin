class User < ActiveRecord::Base

  has_many :jam_artists, :foreign_key => "artist_id"
  has_many :played_in_jams, :through => :jam_artists, :source => "jam"
  has_many :song_managers, :foreign_key => "manager_id"
  has_many :followers, :foreign_key => "follows_user_id"
  has_many :followed_by, :through => :followers
  has_many :following, :class_name => "Follower", :foreign_key => "user_id"
  has_many :follows, :through => :following
  has_many :registered_songs, :class_name => "Song", :foreign_key => "registered_user_id"
  has_many :registered_jams, :class_name => "Jam", :foreign_key => "registered_user_id"
  has_many :likes
  has_many :UserMessageStreamMaps, :dependent => :destroy
  has_many :message_streams, :through => :UserMessageStreamMaps
  has_many :contains_genres, :class_name => "ContainsGenre", :dependent => :destroy, :finder_sql => %q(
    select * from contains_genres 
    where for_type='user' and 
    for_type_id=#{id}
  )
  has_many :user_notifications, :order => "id DESC"
  has_many :notifications, :through => :user_notifications, :order => "id DESC"
  has_many :user_badges, :dependent => :destroy
  has_one :facebook_policy, :class_name => "FacebookShare"
  has_one :twitter_policy, :class_name => "TwitterShare"
  validates_uniqueness_of :username, :message => "has already been registered"
  
  # Sets the created_at attr
  before_save {|record| record.created_at = Time.now}

  def after_create
    feed = Feed.add({:user_ids => [self.id]}, "user_created", "public")
    feed.add_users([self])
  end
  
  def send_acknowledgement
    cmd = "ruby #{ENV["WEBSERVER_ROOT"]}/scripts/mail/account_acknowledgement.rb #{self.id}"
    run(cmd)
  end
  
  def update_basic_info(info)
    self.update_attributes(info)
  end

  def collaborators
    artists = jams.map(&:artists).flatten.uniq.reject do |user| user == self end
  end

  def songs
    participated_songs = jams.map(&:song).compact
    (participated_songs + registered_songs + manages_songs).uniq.sort_by{|song| -(song.id)}
  end
  
  def jams
    (played_in_jams + registered_jams).uniq
  end 
  
  def displayable_jams
    jams.select(&:displayable?)
  end
  
  def manages_songs
    SongManager.find_all_by_manager_id(self.id).map(&:song)
  end
  
  def my_song_jams
    jams.select{|jam| jam.song_jam and (jam.added_by_user == jam.creator or jam.added_by_user_id.nil?)}
  end
  
  def published_jams
    jams.select(&:published)
  end
  
  def inprogress_jams
    jams.reject{|jam| jam.published or jam.song_jam}
  end
  
  def added_by_others_jams
    jams.reject{|jam| jam.added_by_user_id.nil? or jam.added_by_user_id == self.id}
  end
  
  def published_songs
    songs.select(&:published?)
  end
  
  def in_progress_songs
    songs.reject(&:published?)    
  end
  
  def collaborators
    (songs + jams).map(&:artists).flatten.uniq.reject do |user| user == self end
  end
  
  def personal_info
    attributes
  end
  
  def likes_jams
    likes.select{ |like| like.for_type == 'jam'}.map{|jam_like| Jam.find(jam_like.for_type_id)}
  end
  
  def likes_songs
    likes.select{ |like| like.for_type == 'song'}.map{|song_like| Song.find(song_like.for_type_id)}
  end
  
  def likes_song?(song)
    likes_songs.include?(song)
  end
  
  def likes_jam?(jam)
    likes_jams.include?(jam)    
  end
  
  def follows?(user)
    follows.include?(user)
  end 
  
  # Determines the Feeds for the User
  def feeds(limit=20)
    range = Range.new(0, (limit.to_i - 1))
    my_feeds = (Feed.find_by_sql [
        "SELECT f.*",
        "FROM feeds f, user_feeds uf",
        "WHERE (f.scope='global')",
        "ORDER BY created_at DESC"
      ].join(' ')).uniq
    followings_updates = self.follows.map(&:updates).flatten
    (my_feeds + followings_updates).uniq.sort_by(&:created_at).reverse[range] # Aggregate of User's feeds and followings updates
  end
  
  # Determines the Updates for the User
  def updates(limit=20)
    range = Range.new(0, limit.to_i)
    (Feed.find_by_sql [
        "SELECT f.*",
        "FROM feeds f, user_feeds uf",
        "WHERE f.id = uf.feed_id",
        "AND uf.user_id=#{self.id}",
        "AND (f.scope = 'public' OR f.scope = 'protected' OR f.scope = 'global')",
        "ORDER BY created_at DESC"
      ].join(' ')
    ).uniq.sort_by(&:created_at).reverse[range]
  end
  
  def url
    "http://www.jammm.in/" + self.username
  end
  
  def unread_messages
    self.message_streams.map{|ms| ms.unread_messages(self)}.flatten
  end
  
  def unread_song_messages
    self.manages_songs.map{|song|
      song.unread_messages(self)
    }.flatten
  end
  
  def total_unread_messages
    unread_messages.size + unread_song_messages.size
  end
  
  def genres
    contains_genres.map(&:genre)
  end
  
  def instruments
    Instrument.fetch("user", self.id)
  end
  
  def is_password?(str)
    md5(str) == self.password
  end
  
  def change_password(password)
    raise 'Password needs to be atleast of length 5' if password.length < 5
    self.password = md5(password)
    self.save
  end
  
  def change_profile_picture(file)
    storage_dir = ENV['STORAGE_DIR']
    filename = new_file_handle_name(false)
    delete_profile_picture
    full_file_name = storage_dir + "/" + filename
    File.copy(file.path, full_file_name)
    self.profile_picture_file_handle = filename
    self.save
    sleep(3)
    puts ENV.inspect
    puts "------------------------------------------"
    puts `ls -la /home/jammmin/storage`
    puts "------------------------------------------"
    puts "File: exists? : #{File.exists?(full_file_name)}"
    temp_img = Image.new(self.profile_picture)
    temp_img.resize_and_crop(150, 130)
    true
  rescue
    sleep(3)
    temp_img = Image.new(self.profile_picture)
    temp_img.resize_and_crop(150, 130)
    true
  end
  
  def delete_profile_picture
    file_handle = profile_picture_file_handle
    return if not file_handle
    file = get_storage_file(file_handle)
    return if not file
    File.delete(file.path)
  end
  
  def profile_picture
    return (ENV["WEBSERVER_ROOT"] + "/public/images/icons/user3.png") if not profile_picture_file_handle
    get_storage_file_path(profile_picture_file_handle)
  end

  def profile_picture_url
    "/#{self.username}/profile_picture?#{self.profile_picture_file_handle.to_s}"
  end
  
  def increment_counter
    self.log_in_counter ||= 0
    self.log_in_counter += 1
    self.save
  end
  
  def invite(email)
    raise "You have ran out of invites. Please wait a couple of days and will receive more." if invites_remaining < 1
    raise "Please enter a valid email address" if email.blank? or email.nil?
    invite = Invite.add(email, self)
    decrement_invites_remaining
  end
  
  def decrement_invites_remaining
    self.invites_remaining -= 1
    self.save
  end
  
  def update_share_policy(site, policy)
    share = eval("#{site.capitalize}Share").find_by_user_id(self.id)
    # updates a default set of policy keys
    policy = {:jam_like => false, :jam_publish => false, :song_like => false, :song_publish => false}.update(policy.keys_to_sym)
    share.update_attributes(policy)
  end
  
  def unread_notifications
    user_notifications.select{|un| not un.read}.map(&:notification)
  end
  
  def read_notifications(count=:all)
    user_notifications.select(&:read).first(count).map(&:notification)
  end
  
  def set_last_read_song_messages_to_now
    song_managers.each(&:set_last_read_messages_to_now)
  end
  
  def mark_notifications_as_read
    sql("update user_notifications set read=true where user_id=#{self.id}")
  end
  
  def get_sorted_update
    update = {}
    look_for = {:messages => "new_message", :song_messages => "song_message", :invites => "song_invite"}
    notifications = self.unread_notifications
    look_for.each {|k,v|
      update[k] = notifications.select{|n| n.notification_type == v}
      notifications -= update[k]
    }
    update[:general] = notifications
    update
  end
  
  def badges
    user_badges.map(&:badge)
  end
  
  def add_badge(badge)
    raise "not a badge" if not badge
    UserBadge.create({:user_id => self.id, :badge_id => badge.id})
  end
  
end
