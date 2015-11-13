class AddTmdbIdColumnToSmData < ActiveRecord::Migration
  def change
    add_column :sm_data, :tmdb_id, :integer
  end
end
