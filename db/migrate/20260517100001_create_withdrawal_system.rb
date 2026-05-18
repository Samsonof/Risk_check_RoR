class CreateWithdrawalSystem < ActiveRecord::Migration[8.0]
  def change
    # ---- people ----
    create_table :operators do |t|
      t.string :name, null: false
      t.string :role, null: false # operator | superadmin
      t.string :avatar_initials
      t.timestamps
    end
    add_index :operators, :role

    # ---- config ----
    # numeric tunables + boolean toggles, keyed by string
    create_table :settings do |t|
      t.string :key,         null: false
      t.string :value,       null: false # store as string, parse per consumer
      t.string :kind,        null: false # "number" | "boolean"
      t.string :category,    null: false # "limit" | "scoring" | "toggle" | "kyc"
      t.string :description
      t.timestamps
    end
    add_index :settings, :key, unique: true

    # ---- markets ----
    create_table :country_profiles do |t|
      t.string  :code,             null: false # MX | CO | AR | CL | PE
      t.string  :name,             null: false
      t.string  :preferred_method, null: false # SPEI | PSE | CVU | TEF | CCI
      t.integer :max_single_usd,   null: false
      t.integer :max_24h_usd,      null: false
      t.integer :max_24h_count,    null: false
      t.timestamps
    end
    add_index :country_profiles, :code, unique: true

    # ---- clients ----
    create_table :clients do |t|
      t.string  :external_id, null: false
      t.string  :name,        null: false
      t.string  :email
      t.string  :country_code, null: false # MX | CO | AR | CL | PE
      t.integer :kyc_tier,     null: false, default: 0 # 0 | 1 | 2
      t.string  :kyc_full_name # for name-mismatch checks against withdrawal target
      t.string  :registration_ip
      t.datetime :registered_at, null: false
      t.timestamps
    end
    add_index :clients, :external_id, unique: true

    # ---- past behavior ----
    create_table :trades do |t|
      t.references :client, null: false, foreign_key: true
      t.datetime :closed_at, null: false
      t.integer  :volume_usd, null: false
      t.timestamps
    end

    create_table :deposits do |t|
      t.references :client, null: false, foreign_key: true
      t.datetime :occurred_at, null: false
      t.string   :method,      null: false # card | bank | crypto | binance
      t.string   :instrument_label # "Visa **** 4412" or wallet hash etc.
      t.string   :card_fingerprint # for "X different cards" detection
      t.string   :cardholder_name  # for "different names on cards" detection
      t.integer  :amount_usd, null: false
      t.timestamps
    end
    add_index :deposits, %i[client_id occurred_at]

    create_table :previous_withdrawals do |t|
      t.references :client, null: false, foreign_key: true
      t.datetime :occurred_at, null: false
      t.string   :method, null: false
      t.string   :destination_fingerprint # sha1ish of bank/wallet/binance ID
      t.string   :status, null: false # completed | reversed
      t.integer  :amount_usd, null: false
      t.timestamps
    end

    create_table :ip_events do |t|
      t.references :client, null: false, foreign_key: true
      t.string :ip, null: false
      t.string :kind, null: false # login | request | registration | shared_with_another_account
      t.datetime :occurred_at, null: false
      t.timestamps
    end
    add_index :ip_events, %i[client_id occurred_at]

    create_table :account_events do |t|
      t.references :client, null: false, foreign_key: true
      t.string :kind, null: false # password_change | bank_change | crypto_address_change | binance_change
      t.datetime :occurred_at, null: false
      t.timestamps
    end

    # ---- the heart: a withdrawal request ----
    create_table :withdrawal_requests do |t|
      t.references :client, null: false, foreign_key: true
      t.string  :request_id, null: false
      t.integer :amount_usd, null: false
      t.string  :method,             null: false # bank | crypto | binance
      t.string  :destination_label,  null: false
      t.string  :destination_fingerprint, null: false
      t.string  :destination_holder_name
      t.string  :origin_ip
      t.boolean :is_first_withdrawal, null: false, default: false
      t.datetime :submitted_at, null: false
      t.timestamps
    end
    add_index :withdrawal_requests, :request_id, unique: true

    # ---- engine decision (binary: auto_approve | review) ----
    create_table :decisions do |t|
      t.references :withdrawal_request, null: false, foreign_key: true
      t.string  :outcome, null: false # auto_approve | review
      t.integer :score_pts, null: false, default: 0
      t.string  :priority # P1..P7, set if outcome=review
      t.text    :reasons_json    # serialized [{block, code, message, pts}]
      t.text    :block_results_json # which of 6 blocks passed/failed
      t.string  :engine_version
      t.datetime :decided_at, null: false
      t.timestamps
    end
    add_index :decisions, :outcome
    add_index :decisions, :priority

    # ---- operator action on a review case ----
    create_table :operator_decisions do |t|
      t.references :withdrawal_request, null: false, foreign_key: true
      t.references :operator,           null: false, foreign_key: true
      t.string :action,  null: false # approved | rejected
      t.text   :comment, null: false
      t.datetime :acted_at, null: false
      t.timestamps
    end
  end
end
