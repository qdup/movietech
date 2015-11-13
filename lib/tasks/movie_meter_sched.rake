require 'redis'
require "json"
require 'typhoeus'
require 'typhoeus/adapters/faraday'
require 'hashie'
require "#{Rails.root}/app/helpers/application_helper"
include ApplicationHelper

namespace :movie_meter_sched do
  require 'csv'

  datekey_req = Date.today

  desc 'Check EP Download Status'
  task load_daily_gmail_stats: :environment do
    load_daily_gmail_stats
  end

  task load_daily_fb_stats: :environment do
    load_daily_fb_stats(datekey_req)
  end

  task load_daily_twitter_stats: :environment do
    load_daily_twitter_stats(datekey_req)
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

def load_daily_fb_stats(datekey_req)
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
      unless record['Facebook Page Name'].blank? || record['TMDB_ID'].blank?
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
          curr_tmdb_id = record['TMDB_ID'].to_i
          # curr_sm_data = SmData.find_or_create_by(tmdb_id: curr_tmdb_id)
          curr_sm_data = SmData.where(:tmdb_id => curr_tmdb_id, :datekey => datekey_req).first_or_create
          json_resp = JSON.parse(response.body)
          curr_fb_likes = json_resp['likes'].to_i
          curr_fb_talk_about =  json_resp['talking_about_count'].to_i
          curr_fb_id =  json_resp['id']

          curr_sm_data.fb_id = curr_fb_id
          curr_sm_data.fb_likes = curr_fb_likes
          curr_sm_data.fb_talk_about = curr_fb_talk_about
          curr_sm_data.tmdb_id = curr_tmdb_id

          curr_sm_data.save

          puts "Likes: #{curr_fb_likes.to_s}"
          puts "Talk about count: #{curr_fb_talk_about.to_s}"
          puts "FB id: #{curr_fb_id.to_s}"
          puts "Tmdb id: #{curr_tmdb_id.to_s}"

        end
      end
    end
  end
end

def load_daily_twitter_stats(datekey_req)
  # https://graph.facebook.com/RevenantMovie?fields=likes,talking_about_count&access_token=<access_token>
    # returns
    # {
    #   likes: 122615,
    #   talking_about_count: 22026,
    #   id: "568876783246225"
    # }
  key = ENV['TWITTER_KEY']
  secret = ENV['TWITTER_SECRET']

  encoded_auth = Base64.strict_encode64("#{key}:#{secret}")

  # token response: "{\"token_type\":\"bearer\",\"access_token\":\"returned_token\"}"
  twitter_api_url_base = "https://api.twitter.com/"

  twitter_token_action = 'oauth2/token/'
  twitter_token_url = twitter_api_url_base + twitter_token_action
  conn = Faraday.new(url: twitter_token_url, ssl: { verify: false }) do |faraday|
    faraday.request :url_encoded             # form-encode POST params
    faraday.response :logger                 # log requests to STDOUT
    faraday.adapter Faraday.default_adapter  # make requests with Net::HTTP
  end

  response = conn.post do |request|
    request.headers['Content-Type'] = 'application/x-www-form-urlencoded;charset=UTF-8'
    request.headers['Authorization'] = "Basic #{encoded_auth}"
    request.params['grant_type'] = 'client_credentials'
  end
  result = CGI::escapeHTML(response.body)
  result = result.partition('access_token&quot;:&quot;').last
  result = result.split('&quot')
  twitter_token = result.first


  # Get https://api.twitter.com/1.1/users/show.json?screen_name=RevenantMovie
  # In headers of get request add:
  # Authorization: Bearer {access_token}

  # Look for “status_count” and “followers_count”

  twitter_handle =  'TheHungerGames'  #record['Twitter Handle'].gsub(/\s+/, "")
  puts "Handling twitter page name: #{twitter_handle}"
  twitter_url_w_alias = twitter_api_url_base + '1.1/users/show.json'
  conn = Faraday.new(url: twitter_url_w_alias, ssl: { verify: false }) do |faraday|
    faraday.request :url_encoded             # form-encode POST params
    faraday.response :logger                 # log requests to STDOUT
    faraday.adapter Faraday.default_adapter  # make requests with Net::HTTP
  end


  response = conn.get do |req|
    req.headers['Content-Type'] = 'application/json'
    req.headers['Authorization'] = "Bearer #{twitter_token}"
    req.params['screen_name'] = twitter_handle
  end

  json_resp = JSON.parse(response.body)
  curr_statuses_count = json_resp['statuses_count'].to_i
  curr_followers_count = json_resp['followers_count'].to_i

  if response.status == 200

    file = File.open("lib/meta_input.csv", "r:ISO-8859-1")
    csv_text = file
    csv = CSV.parse(csv_text, :headers => true)
    csv.each do |record|
      unless record['Twitter Handle'].blank? || record['TMDB_ID'].blank?
        sleep(0.5)

        curr_tmdb_id = record['TMDB_ID'].to_i
        twitter_handle = record['Twitter Handle'].gsub(/\s+/, "")
        puts "Handling page name: #{twitter_handle}"

        response = conn.get do |req|
          req.headers['Content-Type'] = 'application/json'
          req.headers['Authorization'] = "Bearer #{twitter_token}"
          req.params['screen_name'] = twitter_handle
        end

        json_resp = JSON.parse(response.body)
        curr_statuses_count = json_resp['statuses_count'].to_i
        curr_followers_count = json_resp['followers_count'].to_i
        curr_twitter_id = json_resp['id']

        if response.status == 200
          curr_tmdb_id = record['TMDB_ID'].to_i
          # curr_sm_data = SmData.find_or_create_by(tmdb_id: curr_tmdb_id)
          curr_sm_data = SmData.where(:tmdb_id => curr_tmdb_id, :datekey => datekey_req).first_or_create
          json_resp = JSON.parse(response.body)
          curr_twitter_followers = curr_statuses_count
          curr_twitter_statuses =  curr_followers_count
          curr_twitter_id =  json_resp['id']

          curr_sm_data.twitter_id = curr_twitter_id
          curr_sm_data.twitter_statuses = curr_twitter_statuses
          curr_sm_data.twitter_followers = curr_twitter_followers
          curr_sm_data.tmdb_id = curr_tmdb_id

          curr_sm_data.twitter_id
          curr_sm_data.twitter_hashtag
          curr_sm_data.twitter_page_name

          curr_sm_data.save

          puts "Twitter id: #{curr_twitter_id.to_s}"
          puts "Twitter statuses about count: #{curr_twitter_statuses.to_s}"
          puts "Twitter followers: #{curr_twitter_followers.to_s}"
          puts "Tmdb id: #{curr_tmdb_id.to_s}"

        end
      end
    end
  end
end
