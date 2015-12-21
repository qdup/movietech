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


  task load_daily_fb_stats_from_sm_directory: :environment do
    load_daily_fb_stats_from_sm_directory(datekey_req)
  end

  task load_daily_twitter_stats_from_sm_directory: :environment do
    load_daily_twitter_stats_from_sm_directory(datekey_req)
  end

  task load_daily_klout_stats_from_sm_directory: :environment do
    load_daily_klout_stats_from_sm_directory(datekey_req)
  end

  task load_daily_instagram_stats_from_sm_directory: :environment do
    load_daily_instagram_stats_from_sm_directory(datekey_req)
  end

  task update_daily_ag_scores_from_sm_directory: :environment do
    update_daily_ag_scores_from_sm_directory(datekey_req)
  end


  task load_daily_sm_aggregate_stats_from_directory: :environment do
    load_daily_fb_stats_from_sm_directory(datekey_req)
    load_daily_twitter_stats_from_sm_directory(datekey_req)
    load_daily_klout_stats_from_sm_directory(datekey_req)
    load_daily_instagram_stats_from_sm_directory(datekey_req)
    update_daily_ag_scores_from_sm_directory(datekey_req)
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

# table enumerate stats update starts here
def load_daily_fb_stats_from_sm_directory(datekey_req)
  # get get a fb token ...
  # https://graph.facebook.com/oauth/access_token?client_id={app_id}&client_secret={app_secret}&grant_type=client_credentials
  # returns access_token=xxxxxxxx|xxxxxxxxxx
  save_cnt = 0
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
    SmDirectory.all.each do |sm_dir_record|
      if sm_dir_record.fb_id && sm_dir_record.tmdb_id
        sleep(0.5)
        puts "Handling page name: #{sm_dir_record.fb_page_name}"
        fb_url_w_alias = fb_graph_url_base + sm_dir_record.fb_id
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
          # curr_sm_data = SmData.find_or_create_by(tmdb_id: curr_tmdb_id)
          curr_sm_data = SmData.where(:tmdb_id => sm_dir_record.tmdb_id, :date_key => datekey_req).first_or_create

          curr_sm_data.date_key = datekey_req unless curr_sm_data.date_key

          json_resp = JSON.parse(response.body)

          curr_fb_likes = json_resp['likes'].to_i
          curr_fb_talk_about =  json_resp['talking_about_count'].to_i
          curr_fb_id =  sm_dir_record.fb_id #json_resp['id']

          curr_sm_data.fb_id = curr_fb_id
          curr_sm_data.fb_likes = curr_fb_likes
          curr_sm_data.fb_talk_about = curr_fb_talk_about
          curr_sm_data.tmdb_id = sm_dir_record.tmdb_id
          curr_sm_data.fb_page_name = sm_dir_record.fb_page_name
          curr_sm_data.save

          puts "Likes: #{curr_fb_likes.to_s}"
          puts "Talk about count: #{curr_fb_talk_about.to_s}"
          puts "FB id: #{curr_fb_id.to_s}"
          puts "Tmdb id: #{sm_dir_record.tmdb_id.to_s}"
          puts "FB page name: #{sm_dir_record.fb_page_name.to_s}"

          save_cnt += 1
        end
      end
    end
  end
  puts "FB stats update completed. Added/updated #{save_cnt.to_s} records."
end

def load_daily_twitter_stats_from_sm_directory(datekey_req)
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


  if twitter_token.present?

    SmDirectory.all.each do |sm_dir_record|
      if sm_dir_record.twitter_id && sm_dir_record.tmdb_id
        sleep(0.5)

        curr_twitter_handle = sm_dir_record.twitter_handle
        puts "Handling twitter id: #{sm_dir_record.twitter_id }"

        twitter_url_w_alias = twitter_api_url_base + '1.1/users/show.json'
        conn = Faraday.new(url: twitter_url_w_alias, ssl: { verify: false }) do |faraday|
          faraday.request :url_encoded             # form-encode POST params
          faraday.response :logger                 # log requests to STDOUT
          faraday.adapter Faraday.default_adapter  # make requests with Net::HTTP
        end

        response = conn.get do |req|
          req.headers['Content-Type'] = 'application/json'
          req.headers['Authorization'] = "Bearer #{twitter_token}"
          req.params['screen_name'] = curr_twitter_handle
          req.params['id'] = sm_dir_record.twitter_id
        end

        if response.status == 200
          curr_tmdb_id = sm_dir_record.tmdb_id
          curr_sm_data = SmData.where(:tmdb_id => curr_tmdb_id, :date_key => datekey_req).first_or_create
          curr_sm_data.date_key = datekey_req unless curr_sm_data.date_key

          json_resp = JSON.parse(response.body)

          curr_twitter_statuses = json_resp['statuses_count'].to_i
          curr_twitter_followers = json_resp['followers_count'].to_i

          curr_twitter_id =  sm_dir_record.twitter_id

          curr_sm_data.twitter_id = curr_twitter_id
          curr_sm_data.twitter_statuses = curr_twitter_statuses
          curr_sm_data.twitter_followers = curr_twitter_followers
          curr_sm_data.tmdb_id = sm_dir_record.tmdb_id
          curr_sm_data.twitter_handle = curr_twitter_handle

          if sm_dir_record.twitter_hashtags.first.present?
            curr_twitter_hashtag = sm_dir_record.twitter_hashtags.first.value
            # inst_url = "https://api.instagram.com/v1/tags/#{curr_twitter_hashtag_value}"

            # conn = Faraday.new(url: inst_url, ssl: { verify: false }) do |faraday|
            #   faraday.request :url_encoded             # form-encode POST params
            #   faraday.response :logger                 # log requests to STDOUT
            #   faraday.adapter Faraday.default_adapter  # make requests with Net::HTTP
            # end

            # response = conn.get do |request|
            #   request.headers['Content-Type'] = 'application/x-www-form-urlencoded;charset=UTF-8'
            #   request.params['access_token'] = ENV['INSTAGRAM_TOKEN']
            # end

            curr_sm_data.twitter_hashtag = curr_twitter_hashtag if curr_twitter_hashtag
          end

          curr_sm_data.save

          puts "Twitter id: #{curr_twitter_id.to_s}"
          puts "Twitter statuses about count: #{curr_twitter_statuses.to_s}"
          puts "Twitter followers: #{curr_twitter_followers.to_s}"
          puts "Tmdb id: #{sm_dir_record.tmdb_id.to_s}"

        end
      end
    end
  end
end

def load_daily_klout_stats_from_sm_directory(datekey_req)
  arr_klout_saved = []
  arr_klout_missing = []
  if true

    SmDirectory.all.each do |sm_dir_record|
      if sm_dir_record.twitter_id && sm_dir_record.tmdb_id
        sleep(0.5)

        curr_tmdb_id = sm_dir_record.tmdb_id
        twitter_handle = sm_dir_record.twitter_handle
        puts "Handling klout score for twitter handle: #{twitter_handle.to_s}"

        url = 'http://api.klout.com/v2/identity.json/twitter'
        conn = Faraday.new(url: url, ssl: { verify: false }) do |faraday|
          faraday.request :url_encoded             # form-encode POST params
          faraday.response :logger                 # log requests to STDOUT
          faraday.adapter Faraday.default_adapter  # make requests with Net::HTTP
        end

        response = conn.get do |req|
          req.headers['Content-Type'] = 'application/json'
          req.params['key'] = ENV['KLOUT_KEY']
          req.params['screenName'] = twitter_handle
        end

        if response.status == 200

          json_resp = JSON.parse(response.body)

          curr_klout_id = json_resp['id']

          url = "http://api.klout.com/v2/user.json/#{curr_klout_id}"
          conn = Faraday.new(url: url, ssl: { verify: false }) do |faraday|
            faraday.request :url_encoded             # form-encode POST params
            faraday.response :logger                 # log requests to STDOUT
            faraday.adapter Faraday.default_adapter  # make requests with Net::HTTP
          end

          response = conn.get do |req|
            req.headers['Content-Type'] = 'application/json'
            req.params['key'] = ENV['KLOUT_KEY']
          end

          # {
          #   kloutId: "242068504768050526",
          #   nick: "RevenantMovie",
          #   score: {
          #     score: 62.503448553824015,
          #     bucket: "60-69"
          #   },
          #   scoreDeltas: {
          #     dayChange: 0.01744018332874475,
          #     weekChange: 0.21050426206365813,
          #     monthChange: 0.4487790604834956
          #   }
          # }

          json_resp = JSON.parse(response.body)
          curr_klout_score = json_resp['score']['score']
          curr_klout_day_change = json_resp['scoreDeltas']['dayChange']
          curr_klout_week_change = json_resp['scoreDeltas']['weekChange']
          curr_klout_month_change = json_resp['scoreDeltas']['monthChange']

          curr_sm_data = SmData.where(:tmdb_id => curr_tmdb_id, :date_key => datekey_req).first_or_create
          curr_sm_data.date_key = datekey_req unless curr_sm_data.date_key

          curr_sm_data.klout_id = curr_klout_id
          curr_sm_data.klout_score = curr_klout_score.to_f if curr_klout_score
          curr_sm_data.klout_day_change = curr_klout_day_change.to_f if curr_klout_day_change
          curr_sm_data.klout_week_change = curr_klout_week_change.to_f if curr_klout_week_change
          curr_sm_data.klout_month_change = curr_klout_month_change.to_f if curr_klout_month_change

          curr_sm_data.tmdb_id = curr_tmdb_id

          curr_sm_data.release_date = sm_dir_record.release_date

          curr_sm_data.save

          puts "klout id: #{curr_klout_id.to_s}"
          puts "klout  score: #{curr_klout_score.to_s}"
          puts "klout klout_day_change: #{curr_klout_day_change.to_s}"
          puts "klout klout_week_change: #{curr_klout_week_change.to_s}"
          puts "klout klout_month_change: #{curr_klout_month_change.to_s}"

          puts "Tmdb id: #{curr_tmdb_id.to_s}"

          arr_klout_saved <<  twitter_handle
        else
          arr_klout_missing <<  sm_dir_record.tmdb_id
        end
      else
        arr_klout_missing <<  sm_dir_record.tmdb_id
      end
    end
  end
  puts "found: #{arr_klout_saved.size.to_s}"
  arr_klout_saved.each {|handle| puts handle.to_s}
  puts "missing: #{arr_klout_missing.size.to_s}"
  arr_klout_missing.each {|handle| puts handle.to_s}

end


def load_daily_instagram_stats_from_sm_directory(datekey_req)
  # insta C_ID: 199ebfca8daf4c95b251855eeee7fdbf
  # insta C_Secret: 0580667f0f044705af147803949940a1
  # access_token=1385479434.199ebfc.e4aeb1c63a8e4872b3b07faebddc0592

  # 1.https://instagram.com/oauth/authorize/
  # ?client_id=[CLIENT_ID_HERE]
  # &redirect_uri=[REDIRECT_URI_HERE]
  # &response_type=token

  # https://api.instagram.com/v1/users/search?access_token=1385479434.199ebfc.e4aeb1c63a8e4872b3b07faebddc0592&q=revenantmovie&count=1

  # {
  #   meta: {
  #     code: 200
  #   },
  #   data: [
  #     {
  #       username: "revenantmovie",
  #       profile_picture: "https://igcdn-photos-e-a.akamaihd.net/hphotos-ak-xta1/t51.2885-19/s150x150/12132877_1614162835511876_2015553513_a.jpg",
  #       id: "1421556630",
  #      full_name: ""
  #     }
  #   ]
  # }

  # https://api.instagram.com/v1/users/1421556630?access_token=[ACCESS_TOKEN_HERE]&q=revenantmovie&count=1
  save_cnt = 0
  if true

    SmDirectory.all.each do |sm_dir_record|
      if sm_dir_record.instagram_id && sm_dir_record.tmdb_id
        sleep(0.5)

        curr_tmdb_id = sm_dir_record.tmdb_id
        curr_inst_handle = sm_dir_record.instagram_handle
        inst_url = "https://api.instagram.com/v1/users/search"

        conn = Faraday.new(url: inst_url, ssl: { verify: false }) do |faraday|
          faraday.request :url_encoded             # form-encode POST params
          faraday.response :logger                 # log requests to STDOUT
          faraday.adapter Faraday.default_adapter  # make requests with Net::HTTP
        end

        response = conn.get do |request|
          request.headers['Content-Type'] = 'application/x-www-form-urlencoded;charset=UTF-8'
          request.params['access_token'] = ENV['INSTAGRAM_TOKEN']
          request.params['q'] = curr_inst_handle
          request.params['count'] = 'token'
        end

        json_resp = JSON.parse(response.body)

        if response.status == 200
          curr_inst_id = sm_dir_record.instagram_id #json_resp['data'].first['id']
          curr_tmdb_id = sm_dir_record.tmdb_id
          curr_sm_data = SmData.where(:tmdb_id => curr_tmdb_id, :date_key => datekey_req).first_or_create
          curr_sm_data.date_key = datekey_req unless curr_sm_data.date_key
          # get follower count
          # {"meta"=>{"code"=>200},
          # "data"=>
          #  {"username"=>"thehungergames",
          #   "bio"=>"Nothing Can Prepare You For The End. THE HUNGER GAMES: #MockingjayPart2 – In Theaters November 20, 2015",
          #   "website"=>"http://hungrgam.es/mockingjaytix",
          #   "profile_picture"=>"https://scontent.cdninstagram.com/hphotos-xft1/t51.2885-19/s150x150/11410737_1632448463696163_1389905072_a.jpg",
          #   "full_name"=>"The Hunger Games",
          #   "counts"=>{"media"=>1465, "followed_by"=>1056853, "follows"=>24},
          #   "id"=>"253760693"}}
          # https://api.instagram.com/v1/users/1421556630?access_token=[ACCESS_TOKEN_HERE]&q=revenantmovie&count=1

          inst_url = "https://api.instagram.com/v1/users/#{curr_inst_id}"

          conn = Faraday.new(url: inst_url, ssl: { verify: false }) do |faraday|
            faraday.request :url_encoded             # form-encode POST params
            faraday.response :logger                 # log requests to STDOUT
            faraday.adapter Faraday.default_adapter  # make requests with Net::HTTP
          end

          response = conn.get do |request|
            request.headers['Content-Type'] = 'application/x-www-form-urlencoded;charset=UTF-8'
            request.params['access_token'] = ENV['INSTAGRAM_TOKEN']
            request.params['q'] = curr_inst_handle
            request.params['count'] = 'token'
          end

          binding.pry

          if response.status == 200

            binding.pry

            json_resp = JSON.parse(response.body)

            # "data"=>counts"=>{"media"=>1465, "followed_by"=>1056853, "follows"=>24}

            curr_inst_media =  json_resp['data']['counts']['media']
            curr_inst_followed_by = json_resp['data']['counts']['followed_by']
            curr_inst_follows = json_resp['data']['counts']['follows']

            curr_sm_data.inst_id = curr_inst_id
            curr_sm_data.inst_followed_by = curr_inst_followed_by.to_i
            curr_sm_data.inst_follows = curr_inst_follows.to_i
            curr_sm_data.inst_handle = curr_inst_handle

            binding.pry

            #get hash tag count
            if sm_dir_record.instagram_hashtags.first.present?

              curr_inst_hashtag = sm_dir_record.instagram_hashtags.first.value

              inst_url = "https://api.instagram.com/v1/tags/#{curr_inst_hashtag}"

              conn = Faraday.new(url: inst_url, ssl: { verify: false }) do |faraday|
                faraday.request :url_encoded             # form-encode POST params
                faraday.response :logger                 # log requests to STDOUT
                faraday.adapter Faraday.default_adapter  # make requests with Net::HTTP
              end

              response = conn.get do |request|
                request.headers['Content-Type'] = 'application/x-www-form-urlencoded;charset=UTF-8'
                request.params['access_token'] = ENV['INSTAGRAM_TOKEN']
              end

              if response.status == 200

                # note: returned hashtag is returned  downcase
                # curr_inst_hashtag => MockingjayPart2
                # {"meta"=>{"code"=>200}, "data"=>{"media_count"=>179700, "name"=>"mockingjaypart2"}}
                curr_sm_data.inst_hash_tag = curr_inst_hashtag
                json_resp = JSON.parse(response.body)
                curr_inst_tag_media_count  = json_resp['data']['media_count']
                curr_sm_data.inst_tag_media_count = curr_inst_tag_media_count.to_i
              end
            end
          end

          binding.pry

          curr_sm_data.save

          save_cnt += 1
          puts "instagram id: #{curr_inst_id.to_s}"
          puts "instagram follower count: #{curr_inst_followed_by.to_s}"
          puts "instagram follows: #{curr_inst_follows.to_s}"
          puts "instagram hash tag: #{curr_inst_hashtag.to_s}"

          puts "instagram tag media count: #{curr_inst_tag_media_count.to_s}"

          puts "Tmdb id: #{curr_tmdb_id.to_s}"

        end
      end
    end
  end
end

def update_daily_ag_scores_from_sm_directory(datekey_req)
  # override current date: rake movie_meter_sched:update_daily_ag_scores['Nov 13 2015']
  fb_likes_total = SmData.where(:date_key => datekey_req).sum(:fb_likes)
  fb_talk_about_total = SmData.where(:date_key => datekey_req).sum(:fb_talk_about)
  twitter_followers_total = SmData.where(:date_key => datekey_req).sum(:twitter_followers)
  inst_followed_by_total = SmData.where(:date_key => datekey_req).sum(:inst_followed_by)

  fb_likes_total_percentage = 0
  fb_talk_about_percentage = 0
  twitter_followers_percentage = 0
  inst_followed_by_total_percentage = 0
  ag_score_total = 0
  max_score = 0
  max_fb_likes = 0
  max_fb_talk_about = 0
  max_twitter_followers = 0
  max_inst_followed_by = 0

  if true
    SmDirectory.all.each do |sm_dir_record|
      if sm_dir_record.fb_page_name && sm_dir_record.tmdb_id
        curr_tmdb_id = sm_dir_record.tmdb_id
        curr_sm_data = SmData.find_by(tmdb_id: curr_tmdb_id, date_key: datekey_req)
        if curr_sm_data
          curr_fb_likes_share =  curr_sm_data.fb_likes ? curr_sm_data.fb_likes/fb_likes_total.to_f : 0
          curr_fb_talk_about_share =  curr_sm_data.fb_talk_about ? curr_sm_data.fb_talk_about/fb_talk_about_total.to_f : 0
          curr_twitter_followers_share =  curr_sm_data.twitter_followers ? curr_sm_data.twitter_followers/twitter_followers_total.to_f : 0
          curr_inst_followed_by_share = curr_sm_data.inst_followed_by ? curr_sm_data.inst_followed_by/inst_followed_by_total.to_f : 0

          curr_ag_score = (curr_fb_likes_share + curr_fb_talk_about_share + curr_twitter_followers_share + curr_inst_followed_by_share)/4
          curr_sm_data.aggregate_score = curr_ag_score
          curr_sm_data.save

          puts "tmdb: #{curr_tmdb_id} aggregate_score for date: #{datekey_req.to_s} #{curr_ag_score * 100}%"

          fb_likes_total_percentage = fb_likes_total_percentage + curr_fb_likes_share
          ag_score_total = ag_score_total + curr_ag_score

          max_score = curr_ag_score if curr_ag_score > max_score
          max_fb_likes = curr_sm_data.fb_likes if curr_sm_data.fb_likes  && curr_sm_data.fb_likes > max_fb_likes
          max_fb_talk_about = curr_sm_data.fb_talk_about if curr_sm_data.fb_talk_about && curr_sm_data.fb_talk_about > max_fb_talk_about
          max_twitter_followers = curr_sm_data.twitter_followers if curr_sm_data.twitter_followers && curr_sm_data.twitter_followers > max_twitter_followers
          max_inst_followed_by = curr_sm_data.inst_followed_by if curr_sm_data.inst_followed_by && curr_sm_data.inst_followed_by > max_inst_followed_by
        end
      end
    end
  end

  curr_etl = DailyEtl.where(datekey: datekey_req).first_or_create
  curr_etl.max_ag_score = max_score
  curr_etl.max_fb_likes = max_fb_likes
  curr_etl.max_fb_talk_about = max_fb_talk_about
  curr_etl.max_twitter_followers = max_twitter_followers
  curr_etl.max_inst_followed_by = max_inst_followed_by
  curr_etl.save

  puts "max_score: #{max_score.to_s}"
  puts "max_fb_talk_aboutmax_fb_talk_about: #{max_fb_talk_about.to_s}"
  puts "max_twitter_followers: #{max_twitter_followers.to_s}"
  puts "fb_likes_total_percentage: #{fb_likes_total_percentage.to_s}"
  puts "max_inst_followed_by: #{max_inst_followed_by.to_s}"
  puts "ag_score_total: #{ag_score_total.to_s}"

end



