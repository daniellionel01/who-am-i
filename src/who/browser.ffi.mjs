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
 * @param {string} str
 * @returns {string}
 */
export function to_base_64(str) {
  const bytes = new TextEncoder().encode(str);
  let binary = "";

  // We have to accumulate these bytes individually
  // because `btoa` below does not work with utf8 data.
  //
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }

  return btoa(binary);
}

export function from_base_64(base64) {
  // The incoming base64 string is utf8 encoded,
  // so we have to do some javascript string magic.
  //
  const binary = atob(base64);
  const bytes = Uint8Array.from(binary, (char) => char.charCodeAt(0));

  return new TextDecoder().decode(bytes);
}

export function encode_uri_component(str) {
  return encodeURIComponent(str);
}

export function decode_uri_component(str) {
  return decodeURIComponent(str);
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
