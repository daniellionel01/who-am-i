import gleam/string
import gleeunit
import who

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn base64_test() {
  let str = "Joe"
  assert str == who.from_base64(who.to_base64(str))

  let str = "hello 👋"
  assert str == who.from_base64(who.to_base64(str))
}

pub fn encode_decode_uri_test() {
  let str = "players=[one, two, three]"
  assert str == who.decode_uri_component(who.encode_uri_component(str))
}

pub fn random_id_test() {
  assert string.length(who.random_id(7)) == 7
  assert string.length(who.random_id(10)) == 10
}

pub fn uri_test() {
  let players = [
    who.Player(id: "1", name: "John", identity: "Batman"),
    who.Player(id: "2", name: "Danny", identity: "Spiderman"),
    who.Player(id: "3", name: "Carl", identity: "Superman"),
  ]
  let assert Ok(players) =
    players
    |> who.game_state_to_uri
    |> who.game_state_from_uri

  let assert [player1, player2, player3] = players

  assert player1.name == "John"
  assert player1.identity == "Batman"

  assert player2.name == "Danny"
  assert player2.identity == "Spiderman"

  assert player3.name == "Carl"
  assert player3.identity == "Superman"
}
