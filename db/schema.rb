# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20151214013213) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admins", force: true do |t|
    t.string   "fname"
    t.string   "lname"
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "admins", ["email"], name: "index_admins_on_email", unique: true, using: :btree
  add_index "admins", ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true, using: :btree

  create_table "daily_etls", force: true do |t|
    t.decimal  "max_ag_score"
    t.datetime "datekey"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "max_fb_likes"
    t.integer  "max_fb_talk_about"
    t.integer  "max_twitter_followers"
    t.integer  "max_inst_followed_by"
  end

  create_table "instagram_hashtags", force: true do |t|
    t.string   "value"
    t.integer  "sm_directory_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "instagram_hashtags", ["sm_directory_id"], name: "index_instagram_hashtags_on_sm_directory_id", using: :btree

  create_table "sm_data", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "fb_id"
    t.integer  "fb_likes"
    t.integer  "fb_talk_about"
    t.integer  "tmdb_id"
    t.string   "twitter_id"
    t.integer  "twitter_statuses"
    t.integer  "twitter_followers"
    t.string   "movie_title"
    t.string   "fb_page_name"
    t.string   "twitter_handle"
    t.string   "twitter_hashtag"
    t.string   "klout_id"
    t.datetime "release_date"
    t.datetime "date_key"
    t.decimal  "klout_score",          precision: 20, scale: 17
    t.decimal  "klout_day_change",     precision: 20, scale: 17
    t.decimal  "klout_week_change",    precision: 20, scale: 17
    t.decimal  "klout_month_change",   precision: 20, scale: 17
    t.string   "inst_id"
    t.integer  "inst_followed_by"
    t.integer  "inst_follows"
    t.string   "inst_hash_tag"
    t.integer  "inst_tag_media_count"
    t.string   "inst_handle"
    t.decimal  "aggregate_score"
  end

  create_table "sm_directories", force: true do |t|
    t.integer  "tmdb_id"
    t.string   "title"
    t.string   "fb_page_name"
    t.string   "fb_id"
    t.string   "twitter_id"
    t.string   "instagram_handle"
    t.string   "instagram_id"
    t.string   "klout_id"
    t.datetime "release_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "twitter_hashtags", force: true do |t|
    t.string   "value"
    t.integer  "sm_directory_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "twitter_hashtags", ["sm_directory_id"], name: "index_twitter_hashtags_on_sm_directory_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "fname"
    t.string   "lname"
    t.string   "api_key"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
