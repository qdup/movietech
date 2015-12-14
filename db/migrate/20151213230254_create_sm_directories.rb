class CreateSmDirectories < ActiveRecord::Migration
  def change
    create_table :sm_directories do |t|
      t.integer :tmdb_id
      t.string :title
      t.string :fb_page_name
      t.string :fb_id
      t.string :twitter_hashtag
      t.string :twitter_id
      t.string :instagram_handle
      t.string :instagram_id
      t.integer :klout_id
      t.datetime :release_date
      t.timestamps
    end
  end
end
