class User < ActiveRecord::Base
	has_many :microposts, dependent: :destroy
	
	has_many :relationships, foreign_key: "follower_id", dependent: :destroy
	has_many :followed_users, through: :relationships, source: :followed # источником массива followed_users является множество followed ids
	
	has_many :reverse_relationships, foreign_key: "followed_id",
                                   class_name:  "Relationship", # мы должны включить имя класса для этой ассоциации, потому что иначе Rails будет искать несуществующий класс ReverseRelationship.
                                   dependent:   :destroy
  has_many :followers, through: :reverse_relationships, source: :follower

	has_secure_password
	before_save { self.email = email.downcase }
	before_create :create_remember_token

	validates :name, presence: true, length: { maximum: 50 }
	VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
	validates :email, presence: true, format: { with: VALID_EMAIL_REGEX },
					  uniqueness: { case_sensitive: false }
	
	validates :password, length: { minimum: 6 }

	def following?(other_user)
    	relationships.find_by(followed_id: other_user.id)
  	end

  	def follow!(other_user)
    	self.relationships.create!(followed_id: other_user.id)
  	end

  	def unfollow!(other_user)
    	relationships.find_by(followed_id: other_user.id).destroy!
  	end

    def feed
    	# Это предварительное решение. См. полную реализацию в "Following users".
    	#Micropost.where("user_id = ?", id) # Знак вопроса гарантирует, что id корректно маскирован прежде чем быть включенным в лежащий в его основе SQL запрос, что позволит избежать серьезной дыры в безопасности называемой SQL инъекция.
      Micropost.from_users_followed_by(self)
  	end

    def User.new_remember_token
    	SecureRandom.urlsafe_base64
  	end

  	def User.encrypt(token)
    	Digest::SHA1.hexdigest(token.to_s)
  	end

  	private

    	def create_remember_token
      		self.remember_token = User.encrypt(User.new_remember_token)
    	end
end
