class AddFbColumnsToSmData < ActiveRecord::Migration
  def change
    add_column :sm_data, :fb_id, :integer
    add_column :sm_data, :fb_likes, :integer
    add_column :sm_data, :fb_talk_about, :integer
  end
end
