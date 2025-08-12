import gleam/erlang/process
import mist
import who/database
import who/env
import who/middleware
import who/router
import wisp
import wisp/wisp_mist

pub fn main() -> Nil {
  let env = env.get_env()
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  use db <- database.with_connection(env.db_path)

  let ctx = middleware.Context(static_directory(), db)

  let assert Ok(_) =
    wisp_mist.handler(router.handle_request(_, ctx), secret_key_base)
    |> mist.new
    |> mist.port(3000)
    |> mist.start

  process.sleep_forever()
}

pub fn static_directory() -> String {
  let assert Ok(priv_directory) = wisp.priv_directory("who")
  priv_directory
}
