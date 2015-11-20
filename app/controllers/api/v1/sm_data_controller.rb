class Api::V1::SmDataController < Api::ApiController
  respond_to :json
  before_action :authenticate

  def show
    req_parm = {}
    no_response = {}
    req_parm[:tmdb_id] = params[:id]
    req_limit = params[:size] ||= SearchParams::SIZE_LIMIT_DEFAULT
    req_offset = params[:start] ||= SearchParams::START_OFFSET_DEFAULT
    start_date = params[:start_date].present? ? params[:start_date] : Date.today - SearchParams::START_DATE_OFFSET_DEFAULT
    end_date = params[:end_date].present? ? params[:end_date] : Date.today - SearchParams::END_DATE_OFFSET_DEFAULT

    @sm_data_points = SmData.where(req_parm).
      where('date_key >= ? AND date_key <= ?', start_date, end_date).
        limit(req_limit).offset(req_offset)
    @max_daily_scores = []
    @sm_data_points.each do |sm_data|
      @max_daily_scores <<  DailyEtl.find_by(datekey: sm_data.date_key)
    end

    if @sm_data_points
      respond_with(data_points: @sm_data_points, daily_max_scores: @max_daily_scores)
    else
      respond_with no_response, status: 404
    end
  end

  private

  def authenticate
    api_key = request.headers['X-Api-Key']
    @user = User.where(api_key: api_key).first if api_key

    unless @user
      head status: :unauthorized
      return false
    end
  end
end
