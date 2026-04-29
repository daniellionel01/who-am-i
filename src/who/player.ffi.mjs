const ALPHABET = "0123456789abcdefghijklmnopqrstuvwxyz";

/**
 * @param {number} length
 * @returns {string}
 */
export function random_id(length) {
  let result = "";
  for (let i = 0; i < length; i++) {
    const randomIndex = Math.floor(Math.random() * ALPHABET.length);
    let letter = ALPHABET[randomIndex];
    result += letter;
  }

  return result;
}
