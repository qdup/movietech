class AddMaxScoresToDailyEtl < ActiveRecord::Migration
  def change
    rename_column :daily_etls, :max_daily_ag_score, :max_ag_score
    add_column :daily_etls, :max_fb_likes, :integer
    add_column :daily_etls, :max_fb_talk_about, :integer
    add_column :daily_etls, :max_twitter_follows, :integer
    add_column :daily_etls, :max_inst_followed_by, :integer
  end
end