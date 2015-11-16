class CreateSmData < ActiveRecord::Migration
  def change
    create_table :sm_data do |t|

      t.timestamps
    end
  end
end
