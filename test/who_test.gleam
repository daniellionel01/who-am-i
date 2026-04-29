import gleam/option
import gleam/string
import gleam/uri
import gleeunit
import who
import who/browser
import who/player

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn base64_test() {
  let str = "Joe"
  assert str == browser.from_base64(browser.to_base64(str))

  let str = "hello 👋"
  assert str == browser.from_base64(browser.to_base64(str))
}

pub fn random_id_test() {
  assert string.length(player.random_id(7)) == 7
  assert string.length(player.random_id(10)) == 10
}

pub fn uri_test() {
  let players = [
    player.Player(id: player.create_id(), name: "John", identity: "Batman"),
    player.Player(id: player.create_id(), name: "Danny", identity: "Spiderman"),
    player.Player(id: player.create_id(), name: "Carl", identity: "Superman"),
  ]

  let query =
    players
    |> who.game_state_to_search
    |> uri.query_to_string
    |> option.Some
  let uri = uri.Uri(..uri.empty, query:)

  let assert Ok(players) = who.game_state_from_uri(uri)

  let assert [player1, player2, player3] = players

  assert player1.name == "John"
  assert player1.identity == "Batman"

  assert player2.name == "Danny"
  assert player2.identity == "Spiderman"

  assert player3.name == "Carl"
  assert player3.identity == "Superman"
}
