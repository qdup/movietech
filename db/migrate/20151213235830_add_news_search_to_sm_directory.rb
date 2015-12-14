class AddNewsSearchToSmDirectory < ActiveRecord::Migration
  def change
    add_column :sm_directory, :news_search_term, :string
  end
end
