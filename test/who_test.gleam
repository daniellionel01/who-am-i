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
