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
