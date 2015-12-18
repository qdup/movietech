class Api::V1::SmDirectoryController < Api::ApiController
  require 'json'
  respond_to :json


  # == POST SOCIAL MEDIA DIRECTORY for a new movie by TMDB_ID
  # === POST /api/v1/sm_directory/
  # movietech.herokuapp.com/api/v1/sm_directory/<tmdb_id>
  #     adds social media directory for movie referenced by tmdb id where the the sm_directory table
  #     is not found.
  # === Parameters
  #     tmdb_id: Integer(required). Example: 293660
  #     posts the movie titled Deadpool(2016)
  #       Request URL:http://localhost:9000/api/v1/sm_directory/
  # === Headers
      #   Cache-Control:max-age=0, private, must-revalidate
      #   Connection:Keep-Alive
      #   Authorization: Token token=5sdZCBgJyfWBZwhnijxgQwtt
  #   JSON body post
  # Sample body json payload:
  # {
  #   "tmdb_id": 293660,
  #   "title": "Deadpool",
  #   "fb_page_name": "fbname99999",
  #   "fb_id": "fbid 9999",
  #   "twitter_id": "twitter id 999999",
  #   "instagram_handle": "inst handle 99999",
  #   "instagram_id": "instagram id 999999",
  #   "klout_id": "klout id 999999",
  #   "release_date": "2016-09-09T00:00:00.000Z",
  #   "twitter_handle": "twitter handle 999999"
  # }

  def create #:nodoc:
    req_parm = {}
    no_response = {}
    no_response['Error'] = 'Request failed.'
    req_parm = JSON.parse(params[:sm_directory].to_json)
    @sm_directory = SmDirectory.where(tmdb_id: params[:sm_directory][:tmdb_id]).first_or_create(req_parm)
    if @sm_directory && @sm_directory.save
      respond_with(:api, :v1, @sm_directory)
    else
      respond_with :api, :v1, no_response, status: 404
    end
  end


  # == PUT SOCIAL MEDIA DIRECTORY for an a TMDB id
  # === PUT /api/v1/sm_directory/:tmdb_id
  #     updates social media directory for movie referenced by tmdb id
  #     Movie tmdb_id not modified.
  # === Parameters
  #     tmdb_id: Integer(required). Example: 293660
  #     update the meta for the movie titled Deadpool(2016)
  #       Request URL: http://movietech.herokuapp.com/api/v1/sm_directory/293660
  # === Headers
      #   Cache-Control:max-age=0, private, must-revalidate
      #   Connection:Keep-Alive
      #   Authorization: Token token=5sdZCBgJyfWBZwhnijxgQwtt
  #   JSON body
  # === Response
  # JSON object: tmdb movie social media record

  def update #:nodoc:
    req_parm = {}
    no_response = {}

    no_response['Error'] = 'Request failed.'
    req_parm = JSON.parse(params[:sm_directory].to_json)
    @sm_directory = SmDirectory.where(tmdb_id: params[:sm_directory][:tmdb_id]).first
    req_parm.except!('tmdb_id')
    if @sm_directory && @sm_directory.update(req_parm)
      render json: @sm_directory
    else
      # respond_with :api, :v1, no_response, status: 404
      render json: no_response, status: 404
    end

  end

  # == GET SOCIAL MEDIA DIRECTORY for movie BY TMDB id
  # === GET /api/v1/sm_directory/:tmdb_id
  #     gets social media directory referenced by tmdb id
  # === Parameters
  #     tmdb_id: Integer(required). Example: 259694
  #     update the meta for the movie titled How To Be Single
  #       Request URL: http://movietech.herokuapp.com/api/v1/sm_directory/259694
  # === Headers
      #   Cache-Control:max-age=0, private, must-revalidate
      #   Connection:Keep-Alive
      #   Authorization: Token token=5sdZCBgJyfWBZwhnijxgQwtt
  #   JSON body
  # === Response
  # JSON object: tmdb movie social media record
  def show
    req_parm = {}
    no_response = {}
    req_parm[:tmdb_id] = params[:id]
    @sm_directory = SmDirectory.where(req_parm).first
    if @sm_directory
      respond_with(directory: @sm_directory)
    else
      respond_with no_response, status: 404
    end
  end


private


end
