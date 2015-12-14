class CreateTwitterHashtags < ActiveRecord::Migration
  def change
    create_table :twitter_hashtags do |t|
      t.string :value
      t.references :sm_directory, index: true
      t.timestamps
    end
  end
end
