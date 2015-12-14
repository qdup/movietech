class AddNewsSearchToSmDirectory < ActiveRecord::Migration
  def change
    add_column :sm_directories, :news_search_term, :string
  end
end
