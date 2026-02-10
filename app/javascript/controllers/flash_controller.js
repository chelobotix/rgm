import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="quill"
// Quill is loaded as a global script in the layout (not via importmap)
export default class extends Controller {
    close() {
        this.element.remove()
    }
}