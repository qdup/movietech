require 'redis'
require "json"
require 'typhoeus'
require 'typhoeus/adapters/faraday'
require 'hashie'
require "#{Rails.root}/app/helpers/application_helper"

class DirectoryProcessor

  def initialize(directory_request)
    @directory = directory_request
  end

  def assign_social_media_ids
    assign_fb_id if @directory.fb_page_name && !@directory.fb_id
    assign_twitter_id if @directory.twitter_handle && !@directory.twitter_id
    assign_instagram_id if @directory.twitter_handle && !@directory.instagram_id
  end

  def assign_fb_id
    return if @directory.fb_id

    @fb_page_name = @directory.fb_page_name
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

    @fb_token = response.body.partition('access_token=').last if response.body.present?

    if response.status == 200  && @fb_token.present?
      fb_url_w_alias = fb_graph_url_base + @fb_page_name
      conn = Faraday.new(url: fb_url_w_alias, ssl: { verify: false }) do |faraday|
        faraday.request :url_encoded             # form-encode POST params
        faraday.response :logger                 # log requests to STDOUT
        faraday.adapter Faraday.default_adapter  # make requests with Net::HTTP
      end
      response = conn.get do |req|
        req.headers['Content-Type'] = 'application/json'
        req.params['fields'] = 'likes,talking_about_count'
        req.params['access_token'] = @fb_token
      end

      if response.status == 200
        json_resp = JSON.parse(response.body)
        @fb_id =  json_resp['id']
        @directory.fb_id = @fb_id
      end
    end
  end

  def assign_twitter_id

    return if @directory.twitter_id

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
      sleep(0.5)

      curr_twitter_handle = @directory.twitter_handle
      puts "Handling page name: #{curr_twitter_handle}"

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
      end

      if response.status == 200
        json_resp = JSON.parse(response.body)
        curr_twitter_id =  json_resp['id']
        @directory.twitter_id = curr_twitter_id
      end
    end
  end


  def assign_instagram_id
    return if @directory.instagram_id
    curr_inst_handle = @directory.instagram_handle
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
      curr_inst_id = json_resp['data'].first['id']
      @directory.instagram_id = curr_inst_id
    end
  end


  def fb_id
    @fb_id
  end

  def fb_token
    @fb_token
  end
end