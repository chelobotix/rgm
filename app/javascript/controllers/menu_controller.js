import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="menu"
export default class extends Controller {
  static targets = ["menuMobile", "sidebar"]

  toggleMenu() {
    const isHidden = this.menuMobileTarget.classList.contains("hidden")

    if (isHidden) {
      this.openMenu()
    } else {
      this.closeMenu()
    }
  }

  openMenu() {
    this.menuMobileTarget.classList.remove("hidden")

    setTimeout(() => {
      if (this.hasSidebarTarget) {
        this.sidebarTarget.classList.remove("translate-x-full")
        this.sidebarTarget.classList.add("translate-x-0")
      }
      document.body.style.overflow = "hidden"
    }, 10)
  }

  closeMenu() {
    if (this.hasSidebarTarget) {
      this.sidebarTarget.classList.remove("translate-x-0")
      this.sidebarTarget.classList.add("translate-x-full")
    }

    setTimeout(() => {
      this.menuMobileTarget.classList.add("hidden")
      document.body.style.overflow = ""
    }, 300)
  }
}
