class ChangeSmDataFbIdColumn < ActiveRecord::Migration
  def change
    change_column :sm_data, :fb_id,  :string
  end
end
