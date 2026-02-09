import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle"]

  connect() {
    this.actualTheme = this.readTheme()

    if (!this.actualTheme) {
      this.actualTheme = "light"
      localStorage.setItem("_rails_genius_theme", this.actualTheme)
    }

    this.applyTheme()
    this.updateToggleState()
  }

  toggle() {
    this.actualTheme = this.actualTheme === "dark" ? "light" : "dark"
    localStorage.setItem("_rails_genius_theme", this.actualTheme)

    this.applyTheme()
    this.updateToggleState()
  }

  readTheme() {
    return localStorage.getItem("_rails_genius_theme")
  }

  applyTheme() {
    if (this.actualTheme === "dark") {
      document.documentElement.classList.add("dark")
    } else {
      document.documentElement.classList.remove("dark")
    }
  }

  updateToggleState() {
    if (!this.hasToggleTarget) return

    if (this.actualTheme === "dark") {
      this.toggleTarget.setAttribute("checked", "checked")
    } else {
      this.toggleTarget.removeAttribute("checked")
    }
  }
}
