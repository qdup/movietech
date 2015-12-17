class Api::V1::SmDataController < Api::ApiController
  respond_to :json


  # == GET A Social Media by TMDB_ID
  # movietech.herokuapp.com/api/v1/sm_data/<tmdb_id>
  # eg: show all aggregated points for a specific tmdb_id: 276907
  # movietech.herokuapp.com/api/v1/sm_data/276907
  # Headers:
  # X-Api-Key   5sdZCBgJyfWBZwhnijxgQwtt
  # where 5sdZCBgJyfWBZwhnijxgQwtt is a valid admin user api_key (user.api_key: "5sdZCBgJyfWBZwhnijxgQwtt")  # === Response
  #   Returns json formatted movie object
  #   for the requested movie key where found.
  # === Headers
  #   Cache-Control:max-age=0, private, must-revalidate
  #   Connection:Keep-Alive
  #   Date:Sun, 07 Sep 2014 14:14:45 GMT
  #   Etag:"2ed7df461fdda7d745e2f7d0a17e8f5e"
  #   JSON body
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
        limit(req_limit).offset(req_offset).order(date_key: :asc)

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

  def update

  end

private


end
