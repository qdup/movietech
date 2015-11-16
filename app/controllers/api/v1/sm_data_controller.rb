class Api::V1::SmDataController < Api::ApiController
  respond_to :json
  before_action :authenticate

  def show
    req_parm = {}
    no_response = {}
    req_parm[:tmdb_id] = params[:id]
    # @sm_data_point = SmData.where(req_parm).first
    @sm_data_point = SmData.where(req_parm)

    if @sm_data_point
      respond_with  @sm_data_point, status: :accepted
    else
      respond_with no_response, status: 404
    end
  end

  def authenticate
    api_key = request.headers['X-Api-Key']
    @user = User.where(api_key: api_key).first if api_key

    unless @user
      head status: :unauthorized
      return false
    end
  end
end
