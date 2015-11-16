class AddSmColumnsToSmData < ActiveRecord::Migration
  def change
    add_column :sm_data, :movie_title, :string
    add_column :sm_data, :fb_page_name, :string
    add_column :sm_data, :fb_handle, :string
    add_column :sm_data, :twitter_handle, :string
    add_column :sm_data, :twitter_hashtag, :string
    add_column :sm_data, :twitter_page_name, :string
    add_column :sm_data, :instagram_id, :string
    add_column :sm_data, :instagram_handle, :string
    add_column :sm_data, :instagram_hashtag, :string
    add_column :sm_data, :klout_id, :string
    add_column :sm_data, :release_date, :datetime
  end
end
