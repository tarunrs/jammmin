class Notification < ActiveRecord::Base
  
  before_save {|record| record.created_at = Time.now}
  has_many :user_notifications, :dependent => :destroy
  has_many :users, :through => :user_notifications
  
  # Mapping of Notifications-Types to ICONs
  ICON = {
    :user_follows => :following,
    :comment => :comments,
    :jam_tag => :jam,
    :new_message => :msg,
    :song_invite => :song,
    :song_publish => :song,
    :jam_comment => :jam,
    :song_message => :comments,
    :jam_added_to_song => :add,
    :badge_added => :update,
    :say_mention => :say
  }
  
  def self.add(data={}, notification_type="update")
    self.create({:data_str => data.to_json, :notification_type => notification_type})
  end
  
  def add_users(users)
    users.each {|user|
      UserNotification.create({:user_id => user.id, :notification_id => self.id})
    }
  end
  
  def icon
    self.class::ICON[self.notification_type.to_sym] || self.notification_type.to_sym
  end
  
  def data
    NotificationData.new(self.data_str.eval_json) rescue nil
  end
  
  def read(user)
    user_notifications.find{|un| un.user_id = user.id}.read
  end
  
  def self.delete_by_data(key, value)
    self.all.select{|n| n.data.data[key] == value}.each(&:destroy)
  end
  
  class NotificationData
    attr_accessor :data
    
    def initialize(data)
      @data = data
    end
    
    def user
      User.find(@data["user_id"]) rescue nil
    end
    
    def users
      @data["users_ids"].map{|user_id| User.find(user_id)} rescue nil
    end
    
    def song
      Song.find(@data["song_id"]) rescue nil
    end
    
    def jam
      Jam.find(@data["jam_id"]) rescue nil
    end
    
    def message
      UserMessageStream.find(@data["message_id"]) rescue nil      
    end
    
    def song_message
      SongManageMessage.find(@data["song_message_id"]) rescue nil      
    end   
    
    def comment
      Comment.find(@data["comment_id"]) rescue nil
    end 
    
    def badge
      Badge.new(@data["badge_id"]) rescue nil
    end    
    
    def follower
      Follower.find(@data["follower_id"]) rescue nil
    end

    def say
      Say.find(@data["say_id"]) rescue nil
    end

  end

end
