class RemoveTwitterHashtagColumnFromSmDirectory < ActiveRecord::Migration
  def change
    remove_column :sm_directories, :twitter_hashtag
  end
end
