class AddInstagramColumnsToSmData < ActiveRecord::Migration
  def change
    add_column :sm_data, :inst_id, :string
    add_column :sm_data, :inst_followed_by, :integer
    add_column :sm_data, :inst_follows, :integer
    add_column :sm_data, :inst_hash_tag, :string
    add_column :sm_data, :inst_tag_media_count, :integer
  end
end
