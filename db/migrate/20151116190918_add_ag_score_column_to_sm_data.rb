class AddAgScoreColumnToSmData < ActiveRecord::Migration
  def change
    add_column :sm_data, :aggregate_score, :decimal
  end
end
