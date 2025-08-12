import sqlight

pub fn with_connection(name: String, f: fn(sqlight.Connection) -> a) -> a {
  use db <- sqlight.with_connection(name)
  let assert Ok(_) = sqlight.exec("pragma foreign_keys = on;", db)
  let assert Ok(_) = sqlight.exec("pragma journal_mode = WAL;", db)
  f(db)
}
