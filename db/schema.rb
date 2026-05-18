# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_05_17_100001) do
  create_table "account_events", force: :cascade do |t|
    t.integer "client_id", null: false
    t.string "kind", null: false
    t.datetime "occurred_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_account_events_on_client_id"
  end

  create_table "clients", force: :cascade do |t|
    t.string "external_id", null: false
    t.string "name", null: false
    t.string "email"
    t.string "country_code", null: false
    t.integer "kyc_tier", default: 0, null: false
    t.string "kyc_full_name"
    t.string "registration_ip"
    t.datetime "registered_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_clients_on_external_id", unique: true
  end

  create_table "country_profiles", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.string "preferred_method", null: false
    t.integer "max_single_usd", null: false
    t.integer "max_24h_usd", null: false
    t.integer "max_24h_count", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_country_profiles_on_code", unique: true
  end

  create_table "decisions", force: :cascade do |t|
    t.integer "withdrawal_request_id", null: false
    t.string "outcome", null: false
    t.integer "score_pts", default: 0, null: false
    t.string "priority"
    t.text "reasons_json"
    t.text "block_results_json"
    t.string "engine_version"
    t.datetime "decided_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["outcome"], name: "index_decisions_on_outcome"
    t.index ["priority"], name: "index_decisions_on_priority"
    t.index ["withdrawal_request_id"], name: "index_decisions_on_withdrawal_request_id"
  end

  create_table "deposits", force: :cascade do |t|
    t.integer "client_id", null: false
    t.datetime "occurred_at", null: false
    t.string "method", null: false
    t.string "instrument_label"
    t.string "card_fingerprint"
    t.string "cardholder_name"
    t.integer "amount_usd", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id", "occurred_at"], name: "index_deposits_on_client_id_and_occurred_at"
    t.index ["client_id"], name: "index_deposits_on_client_id"
  end

  create_table "ip_events", force: :cascade do |t|
    t.integer "client_id", null: false
    t.string "ip", null: false
    t.string "kind", null: false
    t.datetime "occurred_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id", "occurred_at"], name: "index_ip_events_on_client_id_and_occurred_at"
    t.index ["client_id"], name: "index_ip_events_on_client_id"
  end

  create_table "operator_decisions", force: :cascade do |t|
    t.integer "withdrawal_request_id", null: false
    t.integer "operator_id", null: false
    t.string "action", null: false
    t.text "comment", null: false
    t.datetime "acted_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["operator_id"], name: "index_operator_decisions_on_operator_id"
    t.index ["withdrawal_request_id"], name: "index_operator_decisions_on_withdrawal_request_id"
  end

  create_table "operators", force: :cascade do |t|
    t.string "name", null: false
    t.string "role", null: false
    t.string "avatar_initials"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["role"], name: "index_operators_on_role"
  end

  create_table "previous_withdrawals", force: :cascade do |t|
    t.integer "client_id", null: false
    t.datetime "occurred_at", null: false
    t.string "method", null: false
    t.string "destination_fingerprint"
    t.string "status", null: false
    t.integer "amount_usd", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_previous_withdrawals_on_client_id"
  end

  create_table "settings", force: :cascade do |t|
    t.string "key", null: false
    t.string "value", null: false
    t.string "kind", null: false
    t.string "category", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "trades", force: :cascade do |t|
    t.integer "client_id", null: false
    t.datetime "closed_at", null: false
    t.integer "volume_usd", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_trades_on_client_id"
  end

  create_table "withdrawal_requests", force: :cascade do |t|
    t.integer "client_id", null: false
    t.string "request_id", null: false
    t.integer "amount_usd", null: false
    t.string "method", null: false
    t.string "destination_label", null: false
    t.string "destination_fingerprint", null: false
    t.string "destination_holder_name"
    t.string "origin_ip"
    t.boolean "is_first_withdrawal", default: false, null: false
    t.datetime "submitted_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_withdrawal_requests_on_client_id"
    t.index ["request_id"], name: "index_withdrawal_requests_on_request_id", unique: true
  end

  add_foreign_key "account_events", "clients"
  add_foreign_key "decisions", "withdrawal_requests"
  add_foreign_key "deposits", "clients"
  add_foreign_key "ip_events", "clients"
  add_foreign_key "operator_decisions", "operators"
  add_foreign_key "operator_decisions", "withdrawal_requests"
  add_foreign_key "previous_withdrawals", "clients"
  add_foreign_key "trades", "clients"
  add_foreign_key "withdrawal_requests", "clients"
end
