class Song < ActiveRecord::Base
  has_many :song_jams, :dependent => :destroy
  has_many :jams, :through => :song_jams
  has_many :song_managers, :dependent => :destroy
  has_many :managers, :through => :song_managers
  belongs_to :creator, :class_name => "User", :foreign_key => "registered_user_id"
  has_one :song_lyric, :dependent => :destroy
  has_many :comments, :class_name => "Comment", :dependent => :destroy, :finder_sql => %q(
    select * from comments 
    where for_type='song' and 
    for_type_id=#{id}
  )
  has_many :liked_by, :class_name => "User", :finder_sql => %q(
      SELECT "users".* FROM "users"  
      INNER JOIN "likes" ON "users".id = "likes".user_id    
      WHERE (("likes".for_type_id = #{id}))
  )
  
  after_destroy :remove_tenticles

  include SongUtils
  
  def after_create
    add_to_manager_list
    feed = Feed.add({:song_id => self.id, :user_ids => [self.creator.id]}, "song_created")
    feed.add_users([self.creator])
  end
  
  def artists
    jams.map(&:artists).flatten.uniq
  end
  
  def add_to_manager_list
    add_manager(creator)
  end
  
  def remove_tenticles
    delete_file_handle
  end
  
  def file
    File.open(file_handle_path(self)) rescue nil
  end
  
  def flattened_file
    File.open(flattened_file_handle_path(self)) rescue nil    
  end
  
  def delete_file_handle
    File.delete(self.file.path) if self.file_handle
    self.file_handle = nil
    self.save
  rescue
    nil
  end
  
  def delete_flattened_file_handle 
    File.delete(self.flatten_file.path) if self.flatten_file_handle
    self.flattened_file_handle = nil
    self.save
  rescue
    nil  
  end
  
  def file_handle_exists?
    file_handle and File.exists?(file_handle_path(self))
  end
  
  def flattened_file_handle_exists?
    true if flattened_file_handle
  end
  
  def flatten_jams(jams=[])
    process_id = ProcessInfo.available_process_id
    cmd = [
        "ruby",
        "#{APP_ROOT}/scripts/flatten_song.rb",
        "--jams=#{jams.map(&:id).join(',')}",
        "--song=#{self.id}",
        "--process_id=#{process_id}"
    ].join(' ')
    run(cmd)
    process_id
  end
  
  def publish
    self.delete_file_handle if self.file_handle_exists?  
    song_jams.each do |song_jam|
      song_jam.is_flattened ? song_jam.activate : song_jam.deactivate
    end
    new_file_handle = new_file_handle_name
    utils_make_copy_of_file_handle(self.flattened_file_handle, new_file_handle)
    self.file_handle = new_file_handle
    self.save
  end
  
  def published
    song_jams.any?(&:active?)
  end
  
  def unpublish
    song_jams.each(&:deactivate)
    delete_file_handle
  end
  
  def like(user)
    Like.add(user, 'song', self.id)
  end
  
  def unlike(user)
    Like.remove(user, 'song', self.id)
  end
  
  def add_lyrics(user, lyrics)
    SongLyric.add(user, self, lyrics)
  end
  
  def lyrics
    song_lyric.lyrics rescue nil
  end
  
  def self.published_songs
    self.find_all.select(&:published)
  end
  
  def add_jam(jam)
    raise "You cannot add this jam as it does not have a mp3 uploaded" if not jam.file_handle
    jam2 = jam.make_copy(jam.name + " (copy for song: #{self.name})") if jam.published or jam.song_jam # Adds a copy of a jam to the song, if jam already published
    SongJam.create({:song_id => self.id, :jam_id => jam2.id})
  end
  
  def remove_jam(jam)
    SongJam.find_by_song_id_and_jam_id(self.id, jam.id).destroy
  end
  
  def add_to_song(song)
    self.jams.each do |jam|
      song.add_jam(jam)
    end
  end
  
  def add_music(music_type, music_id)
    music_obj = music_type.find_by_id(music_id)
    music_obj.add_to_song(self)
  end
  
  def genres
    Genre.fetch("song", self.id)
  end
  
  def song_picture
    return (ENV["WEBSERVER_ROOT"] + "/public/images/icons/8thnote.png") if not song_picture_file_handle
    get_storage_file_path(song_picture_file_handle)
  end
  
  def change_song_picture(file)
    storage_dir = ENV['STORAGE_DIR']
    filename = new_file_handle_name(false)
    delete_storage_file(self.song_picture_file_handle) if song_picture_file_handle
    File.copy(file.path, storage_dir + "/" + filename)
    self.song_picture_file_handle = filename
    self.save
  end
  
  def song_picture_url
    "/song/#{self.id}/song_picture?#{self.song_picture_file_handle.to_s}"
  end
  
  def tags
    Tag.fetch('song', self.id)
  end
  
  
end
