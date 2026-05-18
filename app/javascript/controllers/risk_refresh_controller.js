import { Controller } from "@hotwired/stimulus"

const DECISION_CLASSES = {
  allow:  ["border-emerald-200", "bg-emerald-50", "text-emerald-700"],
  review: ["border-amber-200",   "bg-amber-50",   "text-amber-700"],
  block:  ["border-rose-200",    "bg-rose-50",    "text-rose-700"]
}
const METER_CLASSES = {
  allow:  "stroke-emerald-500",
  review: "stroke-amber-500",
  block:  "stroke-rose-500"
}

export default class extends Controller {
  static targets = ["score", "decision", "decisionBadge", "engine", "checkedAt", "meter"]
  static values  = { url: String, interval: { type: Number, default: 5000 } }

  connect() {
    this.onVisibility = () => this.toggleTimer()
    document.addEventListener("visibilitychange", this.onVisibility)
    this.toggleTimer()
  }

  disconnect() {
    document.removeEventListener("visibilitychange", this.onVisibility)
    this.stop()
  }

  toggleTimer() {
    if (document.visibilityState === "visible") this.start()
    else this.stop()
  }

  start() {
    if (this.timer) return
    this.timer = setInterval(() => this.refresh(), this.intervalValue)
  }

  stop() {
    if (!this.timer) return
    clearInterval(this.timer)
    this.timer = null
  }

  async refresh() {
    try {
      const res  = await fetch(this.urlValue, { headers: { Accept: "application/json" } })
      const data = await res.json()
      this.scoreTarget.textContent     = data.risk_score
      this.decisionTarget.textContent  = data.decision
      this.engineTarget.textContent    = data.engine_status
      this.checkedAtTarget.textContent = data.checked_at
      this.meterTarget.setAttribute("stroke-dasharray", `${data.risk_score}, 100`)

      this.meterTarget.classList.remove("stroke-emerald-500", "stroke-amber-500", "stroke-rose-500")
      this.meterTarget.classList.add(METER_CLASSES[data.decision] || METER_CLASSES.review)

      Object.values(DECISION_CLASSES).flat().forEach(c => this.decisionBadgeTarget.classList.remove(c))
      ;(DECISION_CLASSES[data.decision] || DECISION_CLASSES.review).forEach(c => this.decisionBadgeTarget.classList.add(c))
    } catch {
      this.engineTarget.textContent = "offline"
    }
  }
}
