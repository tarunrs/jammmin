class School < ActiveRecord::Base
  validates_presence_of :name, :handle
  validates_uniqueness_of :handle
  has_many :school_users
  has_many :users, :through => :school_users
  has_many :school_admins 
  has_many :admins, :through => :school_admins
 
  def add_user(user)
    SchoolUser.add(self, user)
  end
  
  def remove_user(user)
    school_user = SchoolUser.find_by_user_id_and_school_id(user.id, self.id)
    school_user.destroy if school_user
  end
  
  def jams
    users.map(&:jams).flatten.uniq.sort_by{|jam| -(jam.id)}
  end
  
  def songs
    users.map(&:songs).flatten.uniq.sort_by{|song| -(song.id)}
  end
  
  def update_info(info)
    self.name = info[:name]
    self.address = info[:address]
    self.phone_number = info[:phone_number]
    self.save
  end
  
  def invite(email)
    Invite.add_for_school(self, email, nil)
  end
  
  def add_admin(user)
    SchoolAdmin.add(self, user)
  end
  
  class << self
    def add(data)
      self.create(data)
    end
  
    def with_handle(handle)
      self.find_by_handle(handle)
    end
  end
  
end
