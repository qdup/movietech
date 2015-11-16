require 'redis'
require "json"
require 'typhoeus'
require 'typhoeus/adapters/faraday'
require 'hashie'
require "#{Rails.root}/app/helpers/application_helper"
include ApplicationHelper
require 'trello'
require 'uri'
require 'net/http'
require "net/ftp"

BOARD_NAME = 'EP Incomplete Downloads'
BOARD_DESC = 'EP Incomplete Downloads List'
CREATED_CARD_LIST_NAME = 'Download Reported Incomplete'
# CREATED_CARD_LIST_NAME = 'SYSTEM_ONLY'

VERIFIED_FILE_LIST = 'File Verified on Client Server'
ENCODE_ALERT_LABEL_NAME = 'ENCODE_MISSING'


namespace :ep_tech_tools do
  desc 'Check EP Download Status'
  task ep_tech_encode_download_check: :environment do
    ep_tech_encode_download_check
  end

  task ep_tech_encode_verified_check: :environment do
    ep_tech_encode_verified_check
  end
end

def ep_tech_encode_download_check
  begin
    init_trello
    board_dl = nil
    Trello::Board.all.detect do |board|
    if board.name == BOARD_NAME
        board_dl = board
      end
    end
    card_names_h = load_card_names(board_dl)

    create_list = find_trello_create_list(board_dl)
    verified_list = find_trello_verified_list(board_dl)
    # board = get_download_trello_board

    auth_url = "http://epbeacon.com/token/new.json"

    download_status_url_base = 'http://epbeacon.com/filetransfers/api/0.1/delivery/search/'
    conn_auth = Faraday.new
    resp_auth = conn_auth.post auth_url, { username: 'gordon', password: 'fishmonitorcandychalk'}

    if resp_auth.status == 200
      str_start_date_gt =  Time.now.strftime ("%Y-%m-%d__gt")
      str_start_date_lt = 14.days.from_now.strftime ("%Y-%m-%d")
      auth_json = JSON.parse(resp_auth.body)
      auth_obj = Hashie::Mash.new auth_json
      auth_token = auth_obj.token
      download_conn = Faraday.new

      resp = download_conn.get download_status_url_base,  {user: '164', token: auth_token, startdate: str_start_date_gt, 'sort(+startdate)' => ""}

      bookings = JSON.parse(resp.body)

      puts "Total bookings found: #{bookings.size.to_s}"

      bookings.each do |booking_json|
        # {
          # title_id: 2119,
          # venue_id: 9662,
          # startdate: "2015-09-23",
          # delivered: false,
          # title: "The Wolfpack",
          # venue: "Wright Opera House",
          # enddate: "2015-09-23",
          # booking_type: "EP_Network",
          # booking_id: 53088,
          # servers: []
        # }
        puts "booking json: #{booking_json}"
        booking = Hashie::Mash.new booking_json
        curr_start_date = Date.strptime( booking.startdate, '%Y-%m-%d')
        if curr_start_date < 15.days.from_now
          booking.servers.each do |server|
            # {
              # server_id: 125,
              # encodes: [],
              # server_location: "Theatre",
              # server_model: "Origen ae"
            # }
            puts "server: #{server['server_location']}"
            if server.encodes.present?
              server.encodes.each do |encode|
                # {
                #   filetype: "tr",
                #   progress: 0,
                #   filename: "The_Wolfpack_1-78_MPEG-2-Tr.mpg",
                #   on_server: false,
                #   filesize: 267436956,
                #   filehash: "894a3bbf750aac1f105626fa16d455cc",
                #   encode_id: 1928
                # },
                # {
                #   filetype: "fe",
                #   progress: 0,
                #   filename: "Wolf_Pack_1-78_MPEG-2-Fe.mpg",
                #   on_server: false,
                #   filesize: 13080372788,
                #   filehash: "926cb792d691810521125f5e1c145f5a",
                #   encode_id: 1906
                # }
                card_name = format_card_name(server, booking, encode)
                if encode.progress != 100
                  start_date = Date.strptime(booking['startdate'], '%Y-%m-%d')
                  num_days_out = (start_date - DateTime.now).to_i
                  puts "theatre: #{booking['venue']} server: #{server['server_location']} #{encode['filetype'] == 'tr' ? 'trailer' : 'feature'}: #{encode['filename']} progess: #{encode['progress'].to_s} num days: #{num_days_out.to_s} start date: #{booking['startdate']}"
                  if !card_names_h[card_name]
                    card_desc = format_card_desc(server, booking, encode)
                    Trello::Card.create(
                      list_id: create_list.id,
                      name: card_name,
                      desc: card_desc,
                      pos: "bottom"
                    )
                  else
                    puts "CARD FOUND theatre: #{booking['venue']} server: #{server['server_location']} #{encode['filetype'] == 'tr' ? 'trailer' : 'feature'}: #{encode['filename']} progess: #{encode['progress'].to_s} num days: #{num_days_out.to_s} start date: #{booking['startdate']}"

                  end
                else
                  puts "PROGRESS 100% theatre: #{booking['venue']} server: #{server['server_location']} #{encode['filetype'] == 'tr' ? 'trailer' : 'feature'}: #{encode['filename']} progess: #{encode['progress'].to_s} num days: #{num_days_out.to_s} start date: #{booking['startdate']}"
                  if card_names_h[card_name]
                    card = board_dl.find_card(card_names_h[card_name])
                    card.move_to_list(verified_list) if card && card.list.id != verified_list.id
                  end

                end
              end
            else
              card_name = format_card_name(server, booking, nil)
              if !card_names_h[card_name]
                card_desc = format_card_desc(server, booking, nil)
                new_card = Trello::Card.create(
                  list_id: create_list.id,
                  name: card_name,
                  desc: card_desc,
                  pos: "bottom"
                )
                # new_card.add_label(:red)
              else

              end
            end
          end
        else
          puts "Skipping booking venue:  #{booking['venue']} title:  #{booking['title']}  start date: #{booking.startdate}"
        end
      end

    end

  rescue Exception => e
    puts 'Error handling set_encode_dl_progress request. Error: ' + e.to_s
  end
end

def ep_tech_encode_verified_check
  begin
    init_trello
    board_dl = nil
    Trello::Board.all.detect do |board|
      if board.name == BOARD_NAME
        board_dl = board
      end
    end

    card_names_h = load_card_names(board_dl)

    verified_list = find_trello_verified_list(board_dl)

    if verified_list
      auth_url = "http://epbeacon.com/token/new.json"

      download_status_url_base = 'http://epbeacon.com/filetransfers/api/0.1/delivery/search/'
      conn_auth = Faraday.new
      resp_auth = conn_auth.post auth_url, { username: 'gordon', password: 'fishmonitorcandychalk'}
      user_num = 164 #user gordon id number

      if resp_auth.status == 200
        auth_json = JSON.parse(resp_auth.body)
        auth_obj = Hashie::Mash.new auth_json
        auth_token = auth_obj.token
        verified_list.cards.each do |card|
          desc_arr = card.desc.split
          puts "Checking verify on card: #{desc_arr}"
          if desc_arr.present? && desc_arr.first.include?('booking_id=')
            puts "Verified card name: #{card.name} -  card desc: #{card.desc}"
            desc_h = Hash.new
            desc_arr.each do |desc|
              if desc.include?('=')
                kv_arr = desc.split("=")
                desc_h[kv_arr[0]] = kv_arr[1]
              end
            end
            response = set_encode_dl_progress(desc_h['server_id'], desc_h['encode_id'], '100', user_num, auth_token)
            card.delete if response == 200
            puts "Verified and removed card: #{card.desc}"
          else
            # puts "LEGACY Verified card name: #{card.name} -  card desc: #{card.desc}"
          end
        end
      end
    else

    end


  rescue Exception => e
    puts 'Error handling ep_tech_encode_verified_check request. Error: ' + e.to_s
  end
end

def init_trello
  Trello.configure do |trello|
    trello.developer_public_key = ENV['TRELLO_DEVELOPER_PUBLIC_KEY']
    trello.member_token = ENV['TRELLO_MEMBER_TOKEN']
  end
  Trello::Board.all.each do |board|
    puts "* #{board.name}"
  end
end

def get_download_trello_board
  board = Trello::Board.all.detect do |board|
    board.name =~ BOARD_NAME
  end
end

def get_alert_label(board)
  alert_label = nil
  board.labels.each do |label|
    alert_label = label if label.name == ENCODE_ALERT_LABEL_NAME
  end
  return alert_label
end

def find_card(board, card_name)
  match_card = nil
  board.lists.each do |list|
    list.cards.each do |card|
      puts "found card name: #{card.name}"
      if card.name == card_name
        match_card = card
      end
    end
  end
  match_card
end

def load_card_names(board)
  begin
    card_h  = Hash.new
    board.lists.each do |list|
      list.cards.each do |card|
        puts "loading card name: #{card.name}"
        card_h[card.name] = card.id
      end
    end
    card_h
  rescue Exception => e
    puts "error handle card loading: #{e.to_s}"
  end
end

def find_trello_create_list(board)
  board.lists.each do |list|
    return list if list.name == CREATED_CARD_LIST_NAME
  end
end

def find_trello_verified_list(board)
  board.lists.each do |list|
    return list if list.name == VERIFIED_FILE_LIST
  end
end

def format_card_name(server, booking, encode)
  if encode.present?
    file_type_desc = encode['filetype'] == 'tr' ? 'trailer' : 'feature'
    card_name = "#{booking.venue} - #{booking.title} - #{file_type_desc} - #{booking.startdate}"
  else
    card_name = "#{ENCODE_ALERT_LABEL_NAME} #{booking.venue} - #{booking.title} - #{file_type_desc} - #{booking.startdate}"
  end
  return card_name
end

def format_card_desc(server, booking, encode)
  if encode.present?
    desc_str = "booking_id=#{booking.booking_id}\n" + "server_id=#{server.server_id.to_s}\n" + encode.map{|k,v| "#{k}=#{v}"}.join("\n")
  else
    desc_str = "booking_id=#{booking.booking_id}\n" + "server_id=#{server.server_id.to_s}\n"
  end
  return desc_str
end


def set_encode_dl_progress(server_id, encode_id, i_progress, user_num, token_req)
  # url:   http://epbeacon.com/filetransfers/api/0.1/bookingprogress/add/?user=164&token=40r-f938c031cf93fff9b4f4
  # Content-type : application/json
  # raw contents:
  # {
  #   "server_id":"8",
  #   "encode_id":"28",
  #   "percent":"55"
  # }

  # Result:
  # {

  #   "added": {
  #   "encode": 28,
  #   "server": 8
  # },
  #   "success": true
  # }
  begin

    #api note: body payload must be a json string literal with NO spaces and all keys and values are delimited with double quotes
    body_str = %Q!{"server_id":"#{server_id.to_s}","encode_id":"#{encode_id.to_s}","percent":"#{i_progress.to_s}"}!
    puts "processing progress update: #{body_str}"
    # epbeacon.com/filetransfers/api/0.1/delivery/view/?token=46j-940c5851d4736a2cac10&user=164&record=2017
    # encode_url_base = 'http://epbeacon.com/filetransfers/api/0.1/delivery/view/'

    # conn = Faraday.new(url: encode_url_base, ssl: { verify: false }) do |faraday|
    #   faraday.request :url_encoded             # form-encode POST params
    #   faraday.response :logger                 # log requests to STDOUT
    #   faraday.adapter Faraday.default_adapter  # make requests with Net::HTTP
    # end
    # response = conn.get do |req|
    #   req.headers['Content-Type'] = 'application/json'
    #   req.params = { user: '164', record: encode_id, token: token_req}
    # end
    # if response.status == 200


      file_tx_url_base = "http://epbeacon.com/filetransfers/api/0.1/bookingprogress/add/"
      conn_progress = Faraday.new(url: file_tx_url_base, ssl: { verify: false }) do |faraday|
        faraday.request :url_encoded             # form-encode POST params
        faraday.response :logger                 # log requests to STDOUT
        faraday.adapter Faraday.default_adapter  # make requests with Net::HTTP
      end
      puts "updating: #{body_str}"
      response = conn_progress.post do |req|
        req.headers['Content-Type'] = 'application/json'
        req.params = { user: '164', token: token_req}
        req.body = body_str #'{"server_id":"8","encode_id":"28","percent":"55"}'
      end
      puts "Successfully updated progress of #{body_str}"
    # else
    #   puts "Encode not found for  #{body_str}"
    # end

    return 200 #response.status

  rescue Exception => e
    puts "Error handling set_encode_dl_progress request. Error: #{e.to_s}  request: #{body_str}"
    return 500
  end
end


def enumerate_available_encodes

  ftp = Net::FTP.new("ip.addrees")
  ftp.login("username","password")
  #get the file list, returns an array
  files = ftp.list("*.msg")
  # each element in the array is a string in the standard FTP list format:
  # e.g.: "-rw-r--r-- ftpowner ftpowner 5748456 Nov 28 08:20:27 somefile.msg"
  #so the filename we want is the last space-seperated element in this string
  #split by space, returns an array
  firstfile = files[0].split(" ")
  # get the last element in this array, which is the filename
  filename = firstfile[firstfile.size -1]
  #get the file
  ftp.get(filename) #gets file in current  mode (text or binary), or:
  ftp.getbinaryfile(filename) #gets file in text mode, or:
  ftp.gettextfile(filename) #gets file in binary mode
end
