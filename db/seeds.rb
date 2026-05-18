require "digest"

puts "Seeding operators..."
ops = {
  marta: Operator.find_or_create_by!(name: "Marta Kowalska") { |o| o.role = "operator";    o.avatar_initials = "MK" },
  omar:  Operator.find_or_create_by!(name: "Omar Haddad")    { |o| o.role = "operator";    o.avatar_initials = "OH" },
  lucia: Operator.find_or_create_by!(name: "Lucia Romero")   { |o| o.role = "operator";    o.avatar_initials = "LR" },
  anya:  Operator.find_or_create_by!(name: "Anya Morozova")  { |o| o.role = "superadmin";  o.avatar_initials = "AM" }
}

puts "Seeding country profiles..."
[
  { code: "MX", name: "Mexico",    preferred_method: "SPEI", max_single_usd: 400, max_24h_usd: 2000, max_24h_count: 3 },
  { code: "CO", name: "Colombia",  preferred_method: "PSE",  max_single_usd: 300, max_24h_usd: 1500, max_24h_count: 2 },
  { code: "AR", name: "Argentina", preferred_method: "CVU",  max_single_usd: 200, max_24h_usd: 800,  max_24h_count: 2 },
  { code: "CL", name: "Chile",     preferred_method: "TEF",  max_single_usd: 500, max_24h_usd: 2500, max_24h_count: 3 },
  { code: "PE", name: "Peru",      preferred_method: "CCI",  max_single_usd: 350, max_24h_usd: 1500, max_24h_count: 2 }
].each { |attrs| CountryProfile.find_or_create_by!(code: attrs[:code]) { |c| c.attributes = attrs } }

puts "Seeding settings..."
settings_seed = [
  # ---- numeric tunables (spec section "Числовые параметры") ----
  ["first_withdrawal_limit_usd",   "100",   "number",  "limit",   "Лимит первого вывода (USD)"],
  ["global_single_max_usd",        "500",   "number",  "limit",   "Максимум разового авто-апрува (USD)"],
  ["global_24h_max_usd",           "500",   "number",  "limit",   "Глобальный лимит за 24 часа (USD)"],
  ["global_7d_max_usd",            "10000", "number",  "limit",   "Лимит за 7 дней (USD)"],
  ["global_30d_max_usd",           "30000", "number",  "limit",   "Лимит за 30 дней (USD)"],
  ["hard_limit_usd",               "5000",  "number",  "limit",   "Hard limit, абсолютный (USD)"],
  ["min_account_age_days",         "3",     "number",  "limit",   "Минимальный возраст аккаунта (дни)"],
  ["min_hours_since_last_deposit", "24",    "number",  "limit",   "Мин. часов с последнего депозита"],
  ["min_trade_volume_usd",         "500",   "number",  "limit",   "Мин. объём торгов до вывода (USD)"],
  ["min_trades_first_withdrawal",  "1",     "number",  "limit",   "Мин. закрытых сделок для первого вывода"],
  ["card_count_review_threshold",  "2",     "number",  "limit",   "Кол-во карт за 24ч → ревью (Блок 6)"],
  ["crypto_transit_activity_pct",  "10",    "number",  "limit",   "Порог торговой активности (%) для крипто-транзита"],
  # ---- scoring threshold — main lever ----
  ["scoring_threshold_pts",        "10",    "number",  "scoring", "Главный порог скоринга (pts). 15/10/6/1 = мягкий/стандарт/жёсткий/ручной"],
  # ---- KYC tier multiplier ----
  ["tier1_limit_multiplier_pct",   "50",    "number",  "kyc",     "Лимит для Tier 1 как % от глобального"],
  # ---- block on/off toggles ----
  ["block1_financial_limits",      "true",  "boolean", "toggle",  "Блок 1 — Финансовые лимиты"],
  ["block2_account_history",       "true",  "boolean", "toggle",  "Блок 2 — История аккаунта"],
  ["block3_kyc_recipient",         "true",  "boolean", "toggle",  "Блок 3 — Реквизиты и верификация"],
  ["block4_behavioral",            "true",  "boolean", "toggle",  "Блок 4 — Поведенческие сигналы"],
  ["block5_risk_scoring",          "true",  "boolean", "toggle",  "Блок 5 — Скоринг риска"],
  ["block6_payment_patterns",      "true",  "boolean", "toggle",  "Блок 6 — Платёжные паттерны"],
  ["first_withdrawal_policy",      "true",  "boolean", "toggle",  "Политика первого вывода"],
  ["check_method_match",           "true",  "boolean", "toggle",  "Проверка совпадения метода депозита и вывода"],
  ["check_new_destination",        "true",  "boolean", "toggle",  "Проверка нового счёта/кошелька/Binance"],
  ["check_new_ip",                 "true",  "boolean", "toggle",  "Проверка нового IP при запросе"]
]
settings_seed.each do |key, value, kind, category, description|
  Setting.find_or_create_by!(key: key) { |s| s.value = value; s.kind = kind; s.category = category; s.description = description }
end

puts "Clearing previous clients/cases..."
WithdrawalRequest.destroy_all
Client.destroy_all

now = Time.zone.parse("2026-05-17 12:00:00")
fp = ->(label) { Digest::SHA1.hexdigest(label)[0, 16] }

# helper to build a case in one shot
def build_case!(now, fp, attrs)
  c = Client.create!(attrs[:client].merge(registered_at: attrs[:client].fetch(:registered_at)))
  (attrs[:trades] || []).each       { |t| c.trades.create!(t) }
  (attrs[:deposits] || []).each     { |d| c.deposits.create!(d.merge(card_fingerprint: d[:card_fingerprint] || (d[:method] == "card" ? fp.call(d[:instrument_label]) : nil))) }
  (attrs[:prior_withdrawals] || []).each { |w| c.previous_withdrawals.create!(w) }
  (attrs[:ip_events] || []).each    { |e| c.ip_events.create!(e) }
  (attrs[:account_events] || []).each { |e| c.account_events.create!(e) }

  wr_attrs = attrs[:withdrawal].dup
  wr_attrs[:destination_fingerprint] ||= fp.call(wr_attrs[:destination_label])
  wr_attrs[:is_first_withdrawal] = c.previous_withdrawals.where(status: "completed").none? if wr_attrs[:is_first_withdrawal].nil?
  c.withdrawal_requests.create!(wr_attrs)
end

puts "Seeding 12 withdrawal cases..."

# --- AUTO-APPROVE CANDIDATES (3) -----------------------------------------

# A1: Mexico, returning client, small bank withdrawal, deposit was bank, KYC L2, 6 trades, account 90d old
build_case!(now, fp,
  client: { external_id: "C-2001", name: "Diego Hernandez", email: "diego.h@example.mx", country_code: "MX",
            kyc_tier: 2, kyc_full_name: "Diego Hernandez", registration_ip: "189.203.10.5",
            registered_at: now - 90.days },
  trades: 6.times.map { |i| { closed_at: now - (10 + i).days, volume_usd: 600 } },
  deposits: [{ occurred_at: now - 5.days, method: "bank", instrument_label: "SPEI **** 8800", amount_usd: 300 }],
  prior_withdrawals: [
    { occurred_at: now - 30.days, method: "bank", destination_fingerprint: fp.call("SPEI **** 8800"), status: "completed", amount_usd: 200 },
    { occurred_at: now - 60.days, method: "bank", destination_fingerprint: fp.call("SPEI **** 8800"), status: "completed", amount_usd: 150 }
  ],
  ip_events: [{ ip: "189.203.10.5", kind: "request", occurred_at: now }],
  withdrawal: { request_id: "W-9001", amount_usd: 250, method: "bank", destination_label: "SPEI **** 8800",
                origin_ip: "189.203.10.5", is_first_withdrawal: false, submitted_at: now })

# A2: Chile, clean low-risk crypto-to-crypto with heavy trading (low risk per matrix)
build_case!(now, fp,
  client: { external_id: "C-2002", name: "Camila Soto", email: "camila.s@example.cl", country_code: "CL",
            kyc_tier: 2, kyc_full_name: "Camila Soto", registration_ip: "200.91.20.10",
            registered_at: now - 60.days },
  trades: 14.times.map { |i| { closed_at: now - (1 + i).days, volume_usd: 800 } },
  deposits: [{ occurred_at: now - 7.days, method: "crypto", instrument_label: "USDT TRC20 0xa4...12c", amount_usd: 1000 }],
  prior_withdrawals: [{ occurred_at: now - 40.days, method: "crypto", destination_fingerprint: fp.call("USDT TRC20 wallet-A"), status: "completed", amount_usd: 300 }],
  ip_events: [{ ip: "200.91.20.10", kind: "request", occurred_at: now }],
  withdrawal: { request_id: "W-9002", amount_usd: 400, method: "crypto", destination_label: "USDT TRC20 wallet-A",
                destination_fingerprint: fp.call("USDT TRC20 wallet-A"), origin_ip: "200.91.20.10", is_first_withdrawal: false, submitted_at: now })

# A3: Peru, first withdrawal that meets ALL first-withdrawal policy conditions (P1 normally, but should still auto-approve)
build_case!(now, fp,
  client: { external_id: "C-2003", name: "Mateo Vargas", email: "mateo.v@example.pe", country_code: "PE",
            kyc_tier: 2, kyc_full_name: "Mateo Vargas", registration_ip: "190.40.5.11",
            registered_at: now - 30.days },
  trades: [{ closed_at: now - 2.days, volume_usd: 200 }],
  deposits: [{ occurred_at: now - 36.hours, method: "bank", instrument_label: "CCI **** 7711", amount_usd: 80 }],
  ip_events: [{ ip: "190.40.5.11", kind: "request", occurred_at: now }],
  withdrawal: { request_id: "W-9003", amount_usd: 70, method: "bank", destination_label: "CCI **** 7711",
                origin_ip: "190.40.5.11", is_first_withdrawal: true, submitted_at: now })

# --- REVIEW CASES (9) ----------------------------------------------------

# R1 — P1: First withdrawal, $90 (under limit), but came from DIFFERENT IP than registration → review (P1 priority)
build_case!(now, fp,
  client: { external_id: "C-2010", name: "Carla Mendez", email: "carla.m@example.mx", country_code: "MX",
            kyc_tier: 1, kyc_full_name: "Carla Mendez", registration_ip: "189.250.4.2",
            registered_at: now - 14.days },
  trades: [{ closed_at: now - 1.day, volume_usd: 120 }],
  deposits: [{ occurred_at: now - 40.hours, method: "card", instrument_label: "Visa **** 4412", amount_usd: 90 }],
  ip_events: [{ ip: "200.5.5.5", kind: "request", occurred_at: now }],
  withdrawal: { request_id: "W-9101", amount_usd: 90, method: "bank", destination_label: "SPEI **** 1234",
                origin_ip: "200.5.5.5", is_first_withdrawal: true, submitted_at: now - 30.minutes })

# R2 — P2: 3 different cards within 24h, then bank-transfer withdrawal (carding/chargeback risk)
build_case!(now, fp,
  client: { external_id: "C-2011", name: "Lucas Romero", email: "lucas.r@example.ar", country_code: "AR",
            kyc_tier: 2, kyc_full_name: "Lucas Romero", registration_ip: "190.210.8.8",
            registered_at: now - 50.days },
  trades: [{ closed_at: now - 5.days, volume_usd: 250 }],
  deposits: [
    { occurred_at: now - 20.hours, method: "card", instrument_label: "Visa **** 1111", cardholder_name: "Lucas Romero", amount_usd: 80 },
    { occurred_at: now - 18.hours, method: "card", instrument_label: "Master **** 2222", cardholder_name: "Lucas Romero", amount_usd: 75 },
    { occurred_at: now - 16.hours, method: "card", instrument_label: "Visa **** 3333", cardholder_name: "Lucas Romero", amount_usd: 60 }
  ],
  ip_events: [{ ip: "190.210.8.8", kind: "request", occurred_at: now }],
  withdrawal: { request_id: "W-9102", amount_usd: 180, method: "bank", destination_label: "CVU **** 9090",
                origin_ip: "190.210.8.8", is_first_withdrawal: false, submitted_at: now - 2.hours })

# R3 — P3: card deposit → crypto withdrawal (always high risk per matrix)
build_case!(now, fp,
  client: { external_id: "C-2012", name: "Sofia Bermudez", email: "sofia.b@example.co", country_code: "CO",
            kyc_tier: 2, kyc_full_name: "Sofia Bermudez", registration_ip: "186.30.4.4",
            registered_at: now - 22.days },
  trades: [{ closed_at: now - 3.days, volume_usd: 300 }],
  deposits: [{ occurred_at: now - 10.hours, method: "card", instrument_label: "Visa **** 7700", cardholder_name: "Sofia Bermudez", amount_usd: 250 }],
  ip_events: [{ ip: "186.30.4.4", kind: "request", occurred_at: now }],
  withdrawal: { request_id: "W-9103", amount_usd: 220, method: "crypto", destination_label: "USDT TRC20 0xfe...ab",
                origin_ip: "186.30.4.4", is_first_withdrawal: false, submitted_at: now - 1.hour })

# R4 — P4: bank withdrawal within 1h of card deposit (chargeback window risk)
build_case!(now, fp,
  client: { external_id: "C-2013", name: "Pedro Aguilar", email: "pedro.a@example.cl", country_code: "CL",
            kyc_tier: 2, kyc_full_name: "Pedro Aguilar", registration_ip: "200.91.11.11",
            registered_at: now - 30.days },
  trades: [{ closed_at: now - 2.days, volume_usd: 400 }],
  deposits: [{ occurred_at: now - 30.minutes, method: "card", instrument_label: "Visa **** 5005", cardholder_name: "Pedro Aguilar", amount_usd: 300 }],
  ip_events: [{ ip: "200.91.11.11", kind: "request", occurred_at: now }],
  withdrawal: { request_id: "W-9104", amount_usd: 280, method: "bank", destination_label: "TEF **** 9090",
                origin_ip: "200.91.11.11", is_first_withdrawal: false, submitted_at: now - 5.minutes })

# R5 — P5: returning clean client w/ formal trigger (slightly above $500 single → review)
build_case!(now, fp,
  client: { external_id: "C-2014", name: "Andrea Silva", email: "andrea.s@example.cl", country_code: "CL",
            kyc_tier: 2, kyc_full_name: "Andrea Silva", registration_ip: "200.91.22.22",
            registered_at: now - 120.days },
  trades: 25.times.map { |i| { closed_at: now - (1 + i).days, volume_usd: 700 } },
  deposits: [{ occurred_at: now - 4.days, method: "bank", instrument_label: "TEF **** 7711", amount_usd: 600 }],
  prior_withdrawals: 4.times.map { |i| { occurred_at: now - ((i + 1) * 14).days, method: "bank", destination_fingerprint: fp.call("TEF **** 7711"), status: "completed", amount_usd: 300 } },
  ip_events: [{ ip: "200.91.22.22", kind: "request", occurred_at: now }],
  withdrawal: { request_id: "W-9105", amount_usd: 600, method: "bank", destination_label: "TEF **** 7711",
                origin_ip: "200.91.22.22", is_first_withdrawal: false, submitted_at: now - 4.hours })

# R6 — P7: Argentina country limit override (max single $200, request $250)
build_case!(now, fp,
  client: { external_id: "C-2015", name: "Florencia Vega", email: "flor.v@example.ar", country_code: "AR",
            kyc_tier: 2, kyc_full_name: "Florencia Vega", registration_ip: "190.210.4.4",
            registered_at: now - 90.days },
  trades: 10.times.map { |i| { closed_at: now - (1 + i).days, volume_usd: 500 } },
  deposits: [{ occurred_at: now - 5.days, method: "bank", instrument_label: "CVU **** 6060", amount_usd: 300 }],
  prior_withdrawals: [{ occurred_at: now - 20.days, method: "bank", destination_fingerprint: fp.call("CVU **** 6060"), status: "completed", amount_usd: 180 }],
  ip_events: [{ ip: "190.210.4.4", kind: "request", occurred_at: now }],
  withdrawal: { request_id: "W-9106", amount_usd: 250, method: "bank", destination_label: "CVU **** 6060",
                origin_ip: "190.210.4.4", is_first_withdrawal: false, submitted_at: now - 6.hours })

# R7 — P7: Crypto-transit: crypto in, crypto out, no trading
build_case!(now, fp,
  client: { external_id: "C-2016", name: "Jorge Castillo", email: "jorge.c@example.pe", country_code: "PE",
            kyc_tier: 2, kyc_full_name: "Jorge Castillo", registration_ip: "190.40.4.4",
            registered_at: now - 40.days },
  trades: [],
  deposits: [{ occurred_at: now - 8.hours, method: "crypto", instrument_label: "USDT TRC20 0x77...ee", amount_usd: 300 }],
  ip_events: [{ ip: "190.40.4.4", kind: "request", occurred_at: now }],
  withdrawal: { request_id: "W-9107", amount_usd: 280, method: "crypto", destination_label: "USDT TRC20 0xab...cd",
                origin_ip: "190.40.4.4", is_first_withdrawal: false, submitted_at: now - 30.minutes })

# R8 — P7: account too young (1 day) + first withdrawal violates "min age 3 days"
build_case!(now, fp,
  client: { external_id: "C-2017", name: "Renata Diaz", email: "ren.d@example.co", country_code: "CO",
            kyc_tier: 1, kyc_full_name: "Renata Diaz", registration_ip: "186.30.7.7",
            registered_at: now - 1.day },
  trades: [{ closed_at: now - 2.hours, volume_usd: 80 }],
  deposits: [{ occurred_at: now - 6.hours, method: "card", instrument_label: "Visa **** 8800", cardholder_name: "Renata Diaz", amount_usd: 90 }],
  ip_events: [{ ip: "186.30.7.7", kind: "request", occurred_at: now }],
  withdrawal: { request_id: "W-9108", amount_usd: 80, method: "bank", destination_label: "PSE **** 6060",
                origin_ip: "186.30.7.7", is_first_withdrawal: true, submitted_at: now - 10.minutes })

# R9 — P7 / hard issue: Tier 0 client trying to withdraw → instant review (would be block if hard rule, kept as review for demo)
build_case!(now, fp,
  client: { external_id: "C-2018", name: "Hugo Martinez", email: "hugo.m@example.mx", country_code: "MX",
            kyc_tier: 0, kyc_full_name: "Hugo Martinez", registration_ip: "189.203.50.5",
            registered_at: now - 4.days },
  trades: [],
  deposits: [{ occurred_at: now - 1.day, method: "card", instrument_label: "Visa **** 1010", cardholder_name: "Hugo Martinez", amount_usd: 150 }],
  ip_events: [{ ip: "189.203.50.5", kind: "request", occurred_at: now }],
  withdrawal: { request_id: "W-9109", amount_usd: 130, method: "bank", destination_label: "SPEI **** 4040",
                origin_ip: "189.203.50.5", is_first_withdrawal: true, submitted_at: now - 2.hours })

puts "Done: clients=#{Client.count}, withdrawals=#{WithdrawalRequest.count}, settings=#{Setting.count}, ops=#{Operator.count}, countries=#{CountryProfile.count}"
