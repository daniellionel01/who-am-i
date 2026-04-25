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
 * We have to encode these bytes
 *
 * @param {string} str
 * @returns {string}
 */
export function toBase64(str) {
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

export function fromBase64(base64) {
  // The incoming base64 string is utf8 encoded,
  // so we have to do some javascript string magic.
  //
  const binary = atob(base64);
  const bytes = Uint8Array.from(binary, (char) => char.charCodeAt(0));

  return new TextDecoder().decode(bytes);
}

export function encodeURIComponent(str) {
  return encodeURIComponent(str);
}

export function decodeURIComponent(str) {
  return decodeURIComponent(str);
}
