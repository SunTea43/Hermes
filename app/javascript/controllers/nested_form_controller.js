import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template"]

  addItem(event) {
    event.preventDefault()
    const timestamp = new Date().getTime()
    const html = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, timestamp)
    this.containerTarget.insertAdjacentHTML("beforeend", html)
  }

  removeItem(event) {
    event.preventDefault()
    const item = event.target.closest("[data-nested-item]")
    const destroyInput = item.querySelector("input[name*='_destroy']")
    if (destroyInput) {
      destroyInput.value = "1"
      item.style.display = "none"
    } else {
      item.remove()
    }
  }
}
