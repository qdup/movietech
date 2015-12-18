class Api::V1::SmDataController < Api::ApiController
  respond_to :json

  # == GET  Social Media data collected for movie referenced by TMDB_ID
  # movietech.herokuapp.com/api/v1/sm_data/<tmdb_id>
  # eg: show all aggregated points for a specific tmdb_id: 276907
  # movietech.herokuapp.com/api/v1/sm_data/276907
  # === Params
  # tmdb_id: <tmdb_id>
  # start_date: yyyy/mm/dd    (%Y/%m/%d) :optional
  # end_date: yyyy/mm/dd    (%Y/%m/%d) :optional
  #  === Headers
  # X-Api-Key   5sdZCBgJyfWBZwhnijxgQwtt
  # where 5sdZCBgJyfWBZwhnijxgQwtt is a valid admin user api_key (user.api_key: "5sdZCBgJyfWBZwhnijxgQwtt")  # === Response
  #   Returns json formatted movie object
  #   for the requested movie key where found.
  # === Response
  # JSON
  # Return social media data collected for the requested date(s). Where no date range is specifed a 7 day range is returned.
  # {
  #   "data_points": [
  #     {
  #       "id": 1413,
  #       "created_at": "2015-11-30T00:01:26.917Z",
  #       "updated_at": "2015-11-30T00:04:46.508Z",
  #       "fb_id": "505861482904561",
  #       "fb_likes": 494306,
  #       "fb_talk_about": 182875,
  #       "tmdb_id": 312221,
  #       "twitter_id": "3253953780",
  #       "twitter_statuses": 570,
  #       "twitter_followers": 15128,
  #       "movie_title": null,
  #       "fb_page_name": "creedmovie",
  #       "twitter_handle": "creedmovie",
  #       "twitter_hashtag": "Creed",
  #       "klout_id": "156781589595216925",
  #       "release_date": null,
  #       "date_key": "2015-11-30T00:00:00.000Z",
  #       "klout_score": "79.5056354922966",
  #       "klout_day_change": "0.246260171439275",
  #       "klout_week_change": "7.74198417898903",
  #       "klout_month_change": "13.0029090579688",
  #       "inst_id": "253760693",
  #       "inst_followed_by": 1207720,
  #       "inst_follows": 24,
  #       "inst_hash_tag": "Creed",
  #       "inst_tag_media_count": 259960,
  #       "inst_handle": "creedmovie",
  #       "aggregate_score": "0.0237840288638437"
  #     },
  #     {
  #       "id": 1475,
  #       "created_at": "2015-12-01T00:01:09.990Z",
  #       "updated_at": "2015-12-01T00:04:08.500Z",
  #       "fb_id": "505861482904561",
  #       "fb_likes": 498023,
  #       "fb_talk_about": 165496,
  #       "tmdb_id": 312221,
  #       "twitter_id": "3253953780",
  #       "twitter_statuses": 579,
  #       "twitter_followers": 15435,
  #       "movie_title": null,
  #       "fb_page_name": "creedmovie",
  #       "twitter_handle": "creedmovie",
  #       "twitter_hashtag": "Creed",
  #       "klout_id": "156781589595216925",
  #       "release_date": null,
  #       "date_key": "2015-12-01T00:00:00.000Z",
  #       "klout_score": "79.5181665594634",
  #       "klout_day_change": "0.0125310671668046",
  #       "klout_week_change": "7.58396943870686",
  #       "klout_month_change": "12.8689335793433",
  #       "inst_id": "253760693",
  #       "inst_followed_by": 1213042,
  #       "inst_follows": 24,
  #       "inst_hash_tag": "Creed",
  #       "inst_tag_media_count": 263580,
  #       "inst_handle": "creedmovie",
  #       "aggregate_score": "0.0221260700829587"
  #     }
  #   ],
  #   "daily_max_scores": [
  #     {
  #       "id": 17,
  #       "max_ag_score": "0.138402844210364",
  #       "datekey": "2015-11-30T00:00:00.000Z",
  #       "created_at": "2015-11-30T00:04:48.916Z",
  #       "updated_at": "2015-11-30T00:04:48.936Z",
  #       "max_fb_likes": 22698645,
  #       "max_fb_talk_about": 737949,
  #       "max_twitter_followers": 1742705,
  #       "max_inst_followed_by": 1207724
  #     },
  #     {
  #       "id": 18,
  #       "max_ag_score": "0.140732657380468",
  #       "datekey": "2015-12-01T00:00:00.000Z",
  #       "created_at": "2015-12-01T00:04:09.168Z",
  #       "updated_at": "2015-12-01T00:04:09.177Z",
  #       "max_fb_likes": 22698251,
  #       "max_fb_talk_about": 742411,
  #       "max_twitter_followers": 1744797,
  #       "max_inst_followed_by": 1213044
  #     }
  #   ]
  # }

  # MovieMeter Sample call:
  # MovieMeter::SocialData.find() class method handles requests to return social media data for the requesting tmdb_id for the optional start and end date
  # sample class method find request: chartdata = SocialData.find('259694', 5.days.ago.to_date, 2.days.ago.to_date)
  def show  #:nodoc:
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
