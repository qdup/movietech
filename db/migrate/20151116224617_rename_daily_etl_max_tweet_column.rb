class RenameDailyEtlMaxTweetColumn < ActiveRecord::Migration
  def change
    rename_column :daily_etls, :max_twitter_follows, :max_twitter_followers
  end
end
