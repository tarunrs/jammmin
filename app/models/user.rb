class User < ActiveRecord::Base

  has_many :jam_artists, :foreign_key => "artist_id"
  has_many :played_in_jams, :through => :jam_artists, :source => "jam"
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
  has_many :user_notifications
  has_many :notifications, :through => :user_notifications, :order => "id DESC"
  validates_uniqueness_of :username, :message => "has already been registered"
  
  # Sets the created_at attr
  before_save {|record| record.created_at = Time.now}

  def after_create
    feed = Feed.add({:user_ids => [self.id]}, "user_created", "public")
    feed.add_users([self])
  end
  
  def update_basic_info(info)
    self.update_attributes(info)
  end

  def collaborators
    artists = jams.map(&:artists).flatten.uniq.reject do |user| user == self end
  end

  def songs
    participated_songs = jams.map(&:song).compact
    (participated_songs + registered_songs).uniq
  end
  
  def jams
    (played_in_jams + registered_jams).uniq
  end 
  
  def published_jams
    jams.select(&:published)
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
        "AND (f.scope = 'public' OR f.scope = 'protected')",
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
  
  def genres
    contains_genres.map(&:genre)
  end
  
  def instruments
    Instrument.fetch("user", self.id)
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
    File.copy(file.path, storage_dir + "/" + filename)
    self.profile_picture_file_handle = filename
    self.save
  end
  
  def delete_profile_picture
    file_handle = profile_picture_file_handle
    return if not file_handle
    file = get_storage_file(file_handle)
    return if not file
    File.delete(file.path)
  end
  
  def profile_picture
    return (ENV["WEBSERVER_ROOT"] + "/public/images/icons/user2.png") if not profile_picture_file_handle
    get_storage_file_path(profile_picture_file_handle)
  end
  
  def increment_counter
    self.log_in_counter ||= 0
    self.log_in_counter += 1
    self.save
  end
  
end
