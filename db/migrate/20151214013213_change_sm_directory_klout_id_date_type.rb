class ChangeSmDirectoryKloutIdDateType < ActiveRecord::Migration
  def change
    change_column :sm_directories, :klout_id, :string
  end
end
