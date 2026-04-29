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

/**
 * @param {string} url
 * @returns {void}
 */
export function history_replace_state(url) {
  window.history.replaceState(null, "", url);
}

/**
 *
 * @returns {string}
 */
export function location_to_string() {
  return window.location.toString();
}

/**
 *
 * @returns {string}
 */
export function location_pathname() {
  return window.location.pathname;
}
