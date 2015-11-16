class AddKloutColumnsToSmData < ActiveRecord::Migration
  def change
    add_column :sm_data, :klout_score, :decimal, :precision => 20, :scale => 17
    add_column :sm_data, :klout_day_change, :decimal, :precision => 20, :scale => 17
    add_column :sm_data, :klout_week_change, :decimal, :precision => 20, :scale => 17
    add_column :sm_data, :klout_month_change, :decimal, :precision => 20, :scale => 17
  end
end