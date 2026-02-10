import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="quill"
// Quill is loaded as a global script in the layout (not via importmap)
export default class extends Controller {
  static targets = ["editor", "input"]

  connect() {
    if (typeof Quill === "undefined") {
      console.error("Quill is not loaded. Make sure the Quill script tag is in your layout.")
      return
    }

    this.quill = new Quill(this.editorTarget, {
      theme: "snow",
      modules: {
        toolbar: {
          container: [
            [{ header: [1, 2, 3, false] }],
            ["bold", "italic", "underline", "strike"],
            ["blockquote", "code-block"],
            [{ list: "ordered" }, { list: "bullet" }],
            ["link", "image"],
            ["clean"]
          ],
          handlers: {
            image: () => this.#insertRemoteImage()
          }
        }
      }
    })

    // Sync Quill content to hidden input
    this.quill.on("text-change", () => {
      this.inputTarget.value = this.quill.root.innerHTML
    })

    // Set initial content if input has value
    if (this.inputTarget.value) {
      this.quill.root.innerHTML = this.inputTarget.value
    }

    // Sync content to hidden input before form submit (ensures content is sent even without text-change)
    const form = this.element.closest("form")
    if (form) {
      form.addEventListener("submit", () => this.#syncToInput())
    }
  }

  #syncToInput() {
    if (this.hasInputTarget) {
      this.inputTarget.value = this.quill.root.innerHTML
    }
  }

  // Private: prompt for a remote image URL and insert it at cursor position
  #insertRemoteImage() {
    const url = prompt("URL de la imagen:")

    if (url) {
      const range = this.quill.getSelection(true)
      this.quill.insertEmbed(range.index, "image", url)
      this.quill.setSelection(range.index + 1)
    }
  }
}
