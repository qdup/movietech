class AddTwitterHandleToSmDirectory < ActiveRecord::Migration
  def change
    add_column :sm_directories, :twitter_handle, :string
  end
end
