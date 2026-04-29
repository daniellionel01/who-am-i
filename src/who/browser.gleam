@external(javascript, "./browser.ffi.mjs", "confirm")
pub fn confirm(message: String) -> Bool

@external(javascript, "./browser.ffi.mjs", "alert")
pub fn alert(message: String) -> Nil

@external(javascript, "./browser.ffi.mjs", "encode_uri_component")
pub fn encode_uri_component(str: String) -> String

@external(javascript, "./browser.ffi.mjs", "decode_uri_component")
pub fn decode_uri_component(str: String) -> String

@external(javascript, "./browser.ffi.mjs", "to_base_64")
pub fn to_base64(str: String) -> String

@external(javascript, "./browser.ffi.mjs", "from_base_64")
pub fn from_base64(str: String) -> String

@external(javascript, "./browser.ffi.mjs", "history_replace_state")
pub fn history_replace_state(url: String) -> Nil

@external(javascript, "./browser.ffi.mjs", "location_pathname")
pub fn location_pathname() -> String

@external(javascript, "./browser.ffi.mjs", "location_to_string")
pub fn location_to_string() -> String
