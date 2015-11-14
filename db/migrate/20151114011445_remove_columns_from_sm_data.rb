class RemoveColumnsFromSmData < ActiveRecord::Migration
  def change
    remove_column :sm_data, :fb_handle
    remove_column :sm_data, :twitter_page_name
    remove_column :sm_data, :instagram_id
    remove_column :sm_data, :instagram_handle
    remove_column :sm_data, :instagram_hashtag
    add_column :sm_data, :inst_handle, :string
  end
end

