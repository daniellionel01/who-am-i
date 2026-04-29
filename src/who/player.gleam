pub opaque type PlayerId {
  PlayerId(String)
}

pub type Player {
  Player(id: PlayerId, name: String, identity: String)
}

pub fn create_id() -> PlayerId {
  let id = random_id(7)
  PlayerId(id)
}

pub fn id_to_string(player_id: PlayerId) -> String {
  let PlayerId(value) = player_id
  value
}

@external(javascript, "./player.ffi.mjs", "random_id")
@internal
pub fn random_id(length: Int) -> String
