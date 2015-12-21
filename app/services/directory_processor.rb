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
    assign_fb_id if @directory.fb_page_name
  end

  def assign_fb_id
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

  def fb_id
    @fb_id
  end

  def fb_token
    @fb_token
  end
end