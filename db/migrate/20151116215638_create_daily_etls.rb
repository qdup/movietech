class CreateDailyEtls < ActiveRecord::Migration
  def change
    create_table :daily_etls do |t|
      t.decimal :max_daily_ag_score
      t.datetime :datekey
      t.timestamps
    end
  end
end
