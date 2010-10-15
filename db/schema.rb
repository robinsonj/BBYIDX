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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110309223551) do

  create_table "admin_comments", :force => true do |t|
    t.integer  "idea_id"
    t.integer  "author_id"
    t.text     "text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "admin_tags", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "client_applications", :force => true do |t|
    t.string   "name"
    t.string   "url"
    t.string   "support_url"
    t.string   "callback_url"
    t.string   "key",          :limit => 20
    t.string   "secret",       :limit => 40
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "client_applications", ["key"], :name => "index_client_applications_on_key", :unique => true

  create_table "comments", :force => true do |t|
    t.integer  "idea_id"
    t.integer  "author_id"
    t.text     "text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "inappropriate_flags",               :default => 0
    t.boolean  "hidden",                            :default => false
    t.string   "ip",                  :limit => 64
    t.string   "user_agent"
    t.boolean  "marked_spam",                       :default => false
    t.boolean  "spam_checked",                      :default => false, :null => false
    t.boolean  "notifications_sent",                :default => false, :null => false
  end

  add_index "comments", ["author_id"], :name => "index_comments_on_author_id"
  add_index "comments", ["idea_id"], :name => "index_comments_on_idea_id"

  create_table "currents", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.integer  "inventor_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "vectors"
    t.boolean  "closed",              :default => false
    t.boolean  "invitation_only",     :default => false
    t.date     "submission_deadline"
  end

  add_index "currents", ["vectors"], :name => "currents_fts_vectors_index"

  create_table "currents_subscribers", :id => false, :force => true do |t|
    t.integer "current_id"
    t.integer "user_id"
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.text     "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ideas", :force => true do |t|
    t.text     "title"
    t.text     "description"
    t.decimal  "rating",                            :precision => 10, :scale => 2, :default => 0.0
    t.integer  "inventor_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "flagged"
    t.boolean  "viewed",                                                           :default => false
    t.integer  "inappropriate_flags",                                              :default => 0
    t.boolean  "hidden",                                                           :default => false
    t.datetime "decayed_at"
    t.integer  "life_cycle_step_id"
    t.string   "status",              :limit => 20,                                :default => "new", :null => false
    t.integer  "duplicate_of_id"
    t.boolean  "marked_spam",                                                      :default => false
    t.integer  "current_id",                                                       :default => -1
    t.integer  "vote_count"
    t.string   "ip",                  :limit => 64
    t.string   "user_agent"
    t.boolean  "spam_checked",                                                     :default => false, :null => false
    t.boolean  "notifications_sent",                                               :default => false, :null => false
  end

  add_index "ideas", ["inventor_id"], :name => "index_ideas_on_inventor_id"

  create_table "ideas_admin_tags", :id => false, :force => true do |t|
    t.integer "idea_id"
    t.integer "admin_tag_id"
  end

  add_index "ideas_admin_tags", ["admin_tag_id"], :name => "index_ideas_admin_tags_on_admin_tag_id"
  add_index "ideas_admin_tags", ["idea_id"], :name => "index_ideas_admin_tags_on_idea_id"

  create_table "ideas_subscribers", :id => false, :force => true do |t|
    t.integer "idea_id"
    t.integer "user_id"
  end

  create_table "ideas_tags", :id => false, :force => true do |t|
    t.integer "idea_id"
    t.integer "tag_id"
  end

  add_index "ideas_tags", ["idea_id"], :name => "index_ideas_tags_on_idea_id"
  add_index "ideas_tags", ["tag_id"], :name => "index_ideas_tags_on_tag_id"

  create_table "life_cycle_steps", :force => true do |t|
    t.integer  "life_cycle_id"
    t.integer  "position"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "life_cycle_steps_admins", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "life_cycle_step_id"
  end

  create_table "life_cycles", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "oauth_nonces", :force => true do |t|
    t.string   "nonce"
    t.integer  "timestamp"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "oauth_nonces", ["nonce", "timestamp"], :name => "index_oauth_nonces_on_nonce_and_timestamp", :unique => true

  create_table "oauth_tokens", :force => true do |t|
    t.integer  "user_id"
    t.string   "type",                  :limit => 20
    t.integer  "client_application_id"
    t.string   "token",                 :limit => 20
    t.string   "secret",                :limit => 40
    t.string   "callback_url"
    t.string   "verifier",              :limit => 20
    t.datetime "authorized_at"
    t.datetime "invalidated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "oauth_tokens", ["token"], :name => "index_oauth_tokens_on_token", :unique => true

  create_table "postal_codes", :force => true do |t|
    t.string "code"
    t.float  "lat"
    t.float  "lon"
  end

  add_index "postal_codes", ["code"], :name => "index_postal_codes_on_code"

  create_table "roles", :force => true do |t|
    t.string   "name",              :limit => 40
    t.string   "authorizable_type", :limit => 40
    t.integer  "authorizable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer  "user_id"
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "id"
  end

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  add_index "tags", ["name"], :name => "index_tags_on_name"

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "crypted_password",           :limit => 40
    t.string   "salt",                       :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "activation_code",            :limit => 40
    t.datetime "activated_at"
    t.string   "state",                                    :default => "passive"
    t.datetime "deleted_at"
    t.string   "zip_code"
    t.float    "contribution_points",                      :default => 0.0
    t.datetime "decayed_at"
    t.boolean  "moderator"
    t.integer  "postal_code_id"
    t.string   "twitter_handle"
    t.boolean  "tweet_ideas"
    t.string   "twitter_token"
    t.string   "twitter_secret"
    t.string   "facebook_uid"
    t.boolean  "notify_on_comments",                       :default => false,     :null => false
    t.boolean  "notify_on_state",                          :default => false,     :null => false
    t.string   "facebook_access_token"
    t.boolean  "facebook_post_ideas"
    t.string   "facebook_name"
    t.float    "recent_contribution_points"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["state"], :name => "index_users_on_state"

  create_table "votes", :force => true do |t|
    t.integer  "idea_id"
    t.integer  "user_id"
    t.boolean  "counted",    :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "votes", ["user_id", "idea_id"], :name => "index_votes_on_user_id_and_idea_id", :unique => true

end
