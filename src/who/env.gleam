import envoy

pub type Environment {
  Environment(db_path: String)
}

pub fn get_env() -> Environment {
  let assert Ok(db_path) = envoy.get("DB_PATH")

  Environment(db_path:)
}
