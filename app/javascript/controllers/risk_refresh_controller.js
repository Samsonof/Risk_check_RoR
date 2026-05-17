import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["score", "decision", "engine", "checkedAt", "meter"]
  static values = { url: String }

  connect() {
    this.refresh()
    this.timer = setInterval(() => this.refresh(), 5000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  async refresh() {
    try {
        const response = await fetch(this.urlValue, { headers: { Accept: "application/json" } })
        const data = await response.json()
        this.scoreTarget.textContent = data.risk_score
        this.decisionTarget.textContent = data.decision
        this.engineTarget.textContent = data.engine_status
        this.checkedAtTarget.textContent = data.checked_at
        this.meterTarget.style.setProperty("--score-fill", `${data.risk_score}%`)
        this.element.dataset.decision = data.decision
      } catch (_error) {
        this.engineTarget.textContent = "offline"
      }
  }
}
