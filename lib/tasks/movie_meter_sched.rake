require 'redis'
require "json"
require 'typhoeus'
require 'typhoeus/adapters/faraday'
require 'hashie'
require "#{Rails.root}/app/helpers/application_helper"
include ApplicationHelper
# require 'trello'
# require 'uri'
# require 'net/http'
# require "net/ftp"

namespace :movie_meter_sched do
  desc 'Check EP Download Status'
  task load_daily_gmail_stats: :environment do
    load_daily_gmail_stats
  end
end

def load_daily_gmail_stats
  # https://ajax.googleapis.com/ajax/services/search/news?v=1.0&q=The+Revenant

  movie_title = "The Revenant"
  gnews_url_base = "https://ajax.googleapis.com/ajax/services/search/news"

  # {
  # "responseData": {
  #   "results": [
  #       {...},
  #       {...},
  #       {...}
  #    ],
  #    "cursor": {...}
  #   },
  #   "responseDetails": null,
  #   "responseStatus": 200
  # }
  conn = Faraday.new(url: gnews_url_base, ssl: { verify: false }) do |faraday|
    faraday.request :url_encoded             # form-encode POST params
    faraday.response :logger                 # log requests to STDOUT
    faraday.adapter Faraday.default_adapter  # make requests with Net::HTTP
  end
  response = conn.get do |req|
    req.headers['Content-Type'] = 'application/json'
    req.params = { v: '1.0', q: movie_title }
  end

  if response.status == 200
    json_resp = JSON.parse(response.body)

    news_results = json_resp['responseData']['results']
    puts "Total new_items found for movie title #{movie_title}: #{news_results.size.to_s}\n\n"
    news_results.each do |news_item_json|
      news_item = Hashie::Mash.new  news_item_json
      puts "title: #{news_item.title}\n"
      puts "published Date: #{news_item.publishedDate}\n"
      puts "Location: #{news_item.location}\n"
      puts "content: #{news_item.content}\n\n"
    end
  end

end