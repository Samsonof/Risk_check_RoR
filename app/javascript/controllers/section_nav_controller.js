import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link"]

  connect() {
    this.onScroll = this.updateActiveLink.bind(this)
    window.addEventListener("scroll", this.onScroll, { passive: true })
    this.updateActiveLink()
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
  }

  updateActiveLink() {
    const current = this.linkTargets
      .map((link) => [link, document.querySelector(link.hash)])
      .filter(([, section]) => section)
      .reverse()
      .find(([, section]) => section.getBoundingClientRect().top <= 140)

    if (!current) return

    this.linkTargets.forEach((link) => link.classList.toggle("active", link === current[0]))
  }
}
