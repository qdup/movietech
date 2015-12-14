class SmDirectory < ActiveRecord::Base
  has_many :instagram_hashtags
  has_many :twitter_hashtags
  validates :tmdb_id, uniqueness: true

end
