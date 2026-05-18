module QueueHelper
  PRIORITY_STYLE = {
    "P1" => { label: "P1 · First withdrawal",          chip: "bg-rose-600 text-white",    border: "border-l-rose-600",    sla: "1–2h" },
    "P2" => { label: "P2 · Carding (chargeback)",      chip: "bg-rose-500 text-white",    border: "border-l-rose-500",    sla: "2–4h" },
    "P3" => { label: "P3 · Card → Crypto/Binance",     chip: "bg-orange-500 text-white",  border: "border-l-orange-500",  sla: "2–4h" },
    "P4" => { label: "P4 · Within 24h of card deposit", chip: "bg-amber-500 text-slate-900", border: "border-l-amber-500", sla: "4–8h" },
    "P5" => { label: "P5 · Returning clean client",    chip: "bg-yellow-300 text-slate-900", border: "border-l-yellow-400", sla: "4–8h" },
    "P6" => { label: "P6 · Escalated by time",         chip: "bg-purple-500 text-white",  border: "border-l-purple-500",  sla: "24h" },
    "P7" => { label: "P7 · Standard review",           chip: "bg-slate-400 text-white",   border: "border-l-slate-400",   sla: "EOD" }
  }.freeze

  def priority_style(p) = PRIORITY_STYLE[p.to_s] || PRIORITY_STYLE["P7"]
  def priority_chip(p)   = priority_style(p)[:chip]
  def priority_border(p) = priority_style(p)[:border]
  def priority_label(p)  = priority_style(p)[:label]
  def priority_sla(p)    = priority_style(p)[:sla]

  def method_icon(m)
    case m
    when "crypto"  then "₿"
    when "bank"    then "🏦"
    when "binance" then "🪙"
    when "card"    then "💳"
    else "•"
    end
  end

  def money(usd) = "$#{number_with_delimiter(usd)}"

  def humanize_block(n)
    %w[Policy Financial\ limits Account\ history KYC\ &\ recipient Behavioral Risk\ scoring Payment\ patterns][n.to_i] || "Block #{n}"
  end

  def time_in_queue_label(hours)
    return "—" if hours.nil?
    return "#{(hours * 60).round}m" if hours < 1
    "#{hours.round(1)}h"
  end
end
