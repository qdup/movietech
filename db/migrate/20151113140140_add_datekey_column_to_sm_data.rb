class AddDatekeyColumnToSmData < ActiveRecord::Migration
  def change
    add_column :sm_data, :datekey, :datetime
  end
end
