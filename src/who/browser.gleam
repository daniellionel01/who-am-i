@external(javascript, "./browser.ffi.mjs", "confirm")
pub fn confirm(message: String) -> Bool

@external(javascript, "./browser.ffi.mjs", "alert")
pub fn alert(message: String) -> Nil

@external(javascript, "./browser.ffi.mjs", "history_replace_state")
pub fn history_replace_state(url: String) -> Nil

@external(javascript, "./browser.ffi.mjs", "location_pathname")
pub fn location_pathname() -> String

@external(javascript, "./browser.ffi.mjs", "location_to_string")
pub fn location_to_string() -> String
