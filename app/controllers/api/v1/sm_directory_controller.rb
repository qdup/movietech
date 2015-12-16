class Api::V1::SmDirectoryController < Api::ApiController
  require 'json'
  respond_to :json

  def create
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

  def update
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
