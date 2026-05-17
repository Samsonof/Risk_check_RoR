import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle(event) {
    const button = event.currentTarget
    const row = button.closest(".lock-row")
    const status = row.querySelector("[data-lock-toggle-target='status']")
    const isLocked = row.dataset.locked === "true"

    row.dataset.locked = String(!isLocked)
    row.classList.toggle("locked", !isLocked)
    row.classList.toggle("clear", isLocked)

    status.textContent = isLocked ? event.params.clear : event.params.locked
    button.textContent = isLocked ? event.params.apply : event.params.release
    button.classList.toggle("btn-outline-danger", !isLocked)
    button.classList.toggle("btn-outline-success", isLocked)
  }
}
