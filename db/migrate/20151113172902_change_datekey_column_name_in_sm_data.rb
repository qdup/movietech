class ChangeDatekeyColumnNameInSmData < ActiveRecord::Migration
  def change
    rename_column :sm_data, :datekey, :date_key
  end
end
