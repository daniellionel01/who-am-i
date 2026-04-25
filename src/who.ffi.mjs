/**
 * Show a confirmation dialog to the user
 * @param {string} message - The message to display in the confirmation dialog
 * @returns {boolean} True if user confirmed, false otherwise
 */
export function confirm(message) {
  return window.confirm(message);
}

/**
 * Show an alert dialog to the user
 * @param {string} message - The message to display in the laert dialog
 * @returns {void}
 */
export function alert(message) {
  return window.alert(message);
}
