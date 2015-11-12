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
  require 'csv'
  desc 'Check EP Download Status'
  task load_daily_gmail_stats: :environment do
    load_daily_gmail_stats
  end
  task load_fb_likes_talk_about_stats: :environment do
    load_fb_likes_talk_about_stats
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

def load_fb_likes_talk_about_stats
  # get get a fb token ...
  # https://graph.facebook.com/oauth/access_token?client_id={app_id}&client_secret={app_secret}&grant_type=client_credentials
  # returns access_token=xxxxxxxx|xxxxxxxxxx
  fb_graph_url_base = "https://graph.facebook.com/"

  fb_token_action = 'oauth/access_token'
  fb_token_url = fb_graph_url_base + fb_token_action
  conn = Faraday.new(url: fb_token_url, ssl: { verify: false }) do |faraday|
    faraday.request :url_encoded             # form-encode POST params
    faraday.response :logger                 # log requests to STDOUT
    faraday.adapter Faraday.default_adapter  # make requests with Net::HTTP
  end
  response = conn.get do |req|
    req.headers['Content-Type'] = 'application/json'
    req.params['client_id'] = ENV['FB_APP_ID']
    req.params['client_secret'] = ENV['FB_APP_SECRET']
    req.params['grant_type'] = 'client_credentials'
  end

  fb_token = response.body.partition('access_token=').last if response.body.present?

  if response.status == 200  && fb_token.present?
    # https://graph.facebook.com/RevenantMovie?fields=likes,talking_about_count&access_token=<access_token>
    # returns
    # {
    #   likes: 122615,
    #   talking_about_count: 22026,
    #   id: "568876783246225"
    # }


    file = File.open("lib/meta_input.csv", "r:ISO-8859-1")
    csv_text = file
    csv = CSV.parse(csv_text, :headers => true)
    csv.each do |record|
      unless record['Facebook Page Name'].blank?
        sleep(0.5)
        fb_alias = record['Facebook Page Name'].gsub(/\s+/, "")
        puts "Handling page name: #{fb_alias}"
        fb_url_w_alias = fb_graph_url_base + fb_alias
        conn = Faraday.new(url: fb_url_w_alias, ssl: { verify: false }) do |faraday|
          faraday.request :url_encoded             # form-encode POST params
          faraday.response :logger                 # log requests to STDOUT
          faraday.adapter Faraday.default_adapter  # make requests with Net::HTTP
        end

        response = conn.get do |req|
          req.headers['Content-Type'] = 'application/json'
          req.params['fields'] = 'likes,talking_about_count'
          req.params['access_token'] = fb_token
        end

        if response.status == 200
          json_resp = JSON.parse(response.body)
          likes = json_resp['likes']
          talk_about_count =  json_resp['talking_about_count']
          fb_id =  json_resp['id']

          puts "Likes: #{likes}"
          puts "Talk about count: #{talk_about_count}"
          puts "FB id: #{fb_id.to_s}"
        end


      end
    end
  end

end
