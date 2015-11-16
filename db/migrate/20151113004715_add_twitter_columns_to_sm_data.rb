class AddTwitterColumnsToSmData < ActiveRecord::Migration
  def change
    add_column :sm_data, :twitter_id, :string
    add_column :sm_data, :twitter_statuses, :integer
    add_column :sm_data, :twitter_followers, :integer
  end
end
