class Micropost < ActiveRecord::Base
	belongs_to :user
	default_scope -> { order('created_at DESC') }
	validates :content, presence: true, length: { maximum: 140 }
	validates :user_id, presence: true

	# Returns microposts from the users being followed by the given user.
	# Для бОльших сайтов, вам, вероятно, потребуется генерировать поток асинхронно с помощью фонового процесса.
	def self.from_users_followed_by(user)
		# [1, 2, 3, 4].map { |i| i.to_s }
		# [1, 2, 3, 4].map(&:to_s)
		# [1, 2, 3, 4].map(&:to_s).join(', ')
		# User.first.followed_users.map(&:id)
		# Фактически, так как конструкции такого вида очень полезны, Active Record обеспечивает ее по умолчанию:
		# User.first.followed_user_ids
		# Здесь метод followed_user_ids синтезирован библиотекой Active Record на основе 
		# ассоциации has_many :followed_users (Листинг 11.10); в результате, для получения 
		# id соответствующих коллекции user.followed_users, нам достаточно добавить _ids 
		# к названию ассоциации.
    	followed_user_ids = "SELECT followed_id FROM relationships
                     		 WHERE follower_id = :user_id"
    	# where("user_id IN (?) OR user_id = ?", followed_user_ids, user)
    	# рефакторинг для большого числа сообщений
    	where("user_id IN (:followed_user_ids) OR user_id = :user_id",
          	   followed_user_ids: followed_user_ids, user_id: user)
  	end
end
