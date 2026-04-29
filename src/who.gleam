import glaze/basecoat/button
import glaze/basecoat/card
import glaze/basecoat/form
import glaze/basecoat/input
import glaze/basecoat/label
import gleam/dynamic
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/uri
import glqr
import iv
import lustre
import lustre/attribute.{attribute}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/element/keyed
import lustre/element/svg
import lustre/event

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

pub type Player {
  Player(id: String, name: String, identity: String)
}

pub type ViewMode {
  Editing
  ShareGame
  Identities
}

pub type Model {
  NewGame
  Game(
    players: iv.Array(Player),
    local_player_id: option.Option(String),
    mode: ViewMode,
  )
}

pub fn init(_: Nil) -> #(Model, Effect(Message)) {
  let model = case uri.parse(get_current_uri_as_string()) {
    Error(_) -> NewGame
    Ok(uri) -> {
      case game_state_from_uri(uri) {
        Error(_) -> NewGame
        Ok(players) -> {
          let players = iv.from_list(players)
          Game(players:, local_player_id: option.None, mode: Editing)
        }
      }
    }
  }

  #(model, effect.none())
}

pub type Message {
  StartGame(player_name: String)
  ChooseLocalPlayer(player_id: String)
  RemovePlayer(index: Int)
  UpdatePlayerName(id: String, name: String)
  UpdatePlayerIdentity(id: String, identity: String)
  AddPlayer
  ResetGameClicked
  ResetGameConfirmed
  SwitchToIdentitiesView
  SwitchToEditingView
  ShareGameView
}

pub type ButtonAction {
  SwitchToIdentitiesAction
  ShareGameAction
}

fn button_action_decoder() -> decode.Decoder(ButtonAction) {
  use variant <- decode.then(decode.string)
  case variant {
    "switch_to_identities_action" -> decode.success(SwitchToIdentitiesAction)
    "share_game_action" -> decode.success(ShareGameAction)
    _ -> decode.failure(SwitchToIdentitiesAction, "ButtonAction")
  }
}

pub fn button_action_to_string(action: ButtonAction) {
  case action {
    SwitchToIdentitiesAction -> "switch_to_identities_action"
    ShareGameAction -> "share_game_action"
  }
}

pub fn create_player_id() {
  random_id(7)
}

pub fn game_state_to_uri(players: List(Player)) -> uri.Uri {
  let query =
    uri.query_to_string(list.append(
      list.map(players, fn(player) { #("names[]", player.name) }),
      list.map(players, fn(player) { #("identities[]", player.identity) }),
    ))
  uri.Uri(..uri.empty, path: "/", query: option.Some(query))
}

pub fn update_uri(model: Model) -> Effect(a) {
  effect.from(fn(_dispatch) {
    case model {
      NewGame -> {
        replace_state("/")
      }
      Game(players:, local_player_id: _, mode: _) -> {
        let players = iv.to_list(players)
        let uri = game_state_to_uri(players)
        replace_state("/?" <> option.unwrap(uri.query, ""))
      }
    }
  })
}

pub fn game_state_from_uri(uri: uri.Uri) -> Result(List(Player), Nil) {
  case uri.query {
    option.None -> Error(Nil)
    option.Some(query) -> {
      use query <- result.try(uri.parse_query(query))

      let names = list.key_filter(query, "names[]")
      let identities = list.key_filter(query, "identities[]")

      let players =
        list.zip(names, identities)
        |> list.map(fn(item) {
          let #(name, identity) = item
          Player(id: create_player_id(), name:, identity:)
        })
      Ok(players)
    }
  }
}

pub fn update(model: Model, message: Message) -> #(Model, Effect(Message)) {
  case model {
    NewGame -> {
      case message {
        StartGame(player_name:) -> {
          let model =
            Game(
              players: iv.from_list([
                Player(id: create_player_id(), name: player_name, identity: ""),
              ]),
              local_player_id: option.None,
              mode: Editing,
            )
          #(model, update_uri(model))
        }
        ChooseLocalPlayer(_)
        | RemovePlayer(_)
        | AddPlayer
        | ResetGameClicked
        | ResetGameConfirmed
        | SwitchToIdentitiesView
        | ShareGameView
        | UpdatePlayerName(_, _)
        | UpdatePlayerIdentity(_, _)
        | SwitchToEditingView -> panic as "reached impossible state"
      }
    }
    Game(players:, local_player_id: _, mode: _) -> {
      case message {
        ChooseLocalPlayer(player_id:) -> {
          let model =
            Game(
              ..model,
              local_player_id: option.Some(player_id),
              mode: Identities,
            )
          #(model, effect.none())
        }
        RemovePlayer(index: remove_index) -> {
          case remove_index {
            0 -> {
              let alert_dialog = {
                use _dispatch, _root <- effect.before_paint
                alert("You cannot remove the player who started the game!")
                Nil
              }
              #(model, alert_dialog)
            }
            _ -> {
              let players = iv.try_delete(players, at: remove_index)
              let model = Game(..model, players:)
              #(model, update_uri(model))
            }
          }
        }
        AddPlayer -> {
          let players =
            iv.append(
              model.players,
              Player(id: create_player_id(), name: "", identity: ""),
            )
          let model = Game(..model, players:)
          #(model, update_uri(model))
        }
        ResetGameClicked -> {
          let confirm_dialog = {
            use dispatch, _root <- effect.before_paint
            let agreed = confirm("Are you sure you want to reset?")
            case agreed {
              False -> Nil
              True -> dispatch(ResetGameConfirmed)
            }
          }
          #(model, confirm_dialog)
        }
        ResetGameConfirmed -> {
          let model = NewGame
          #(model, update_uri(model))
        }
        SwitchToIdentitiesView -> {
          let model = Game(..model, mode: Identities)
          #(model, effect.none())
        }
        SwitchToEditingView -> {
          let model = Game(..model, mode: Editing)
          #(model, effect.none())
        }
        ShareGameView -> {
          let model = Game(..model, mode: ShareGame)
          #(model, effect.none())
        }
        UpdatePlayerName(id:, name:) -> {
          let players =
            iv.map(model.players, fn(player) {
              case player.id == id {
                False -> player
                True -> Player(..player, name:)
              }
            })
          let model = Game(..model, players:)
          #(model, update_uri(model))
        }
        UpdatePlayerIdentity(id:, identity:) -> {
          let players =
            iv.map(model.players, fn(player) {
              case player.id == id {
                False -> player
                True -> Player(..player, identity:)
              }
            })
          let model = Game(..model, players:)
          #(model, update_uri(model))
        }

        StartGame(_) -> panic as "reached impossible state"
      }
    }
  }
}

pub fn view(model: Model) -> Element(Message) {
  let main = case model {
    NewGame -> {
      card.card([], [
        card.header([], [
          card.title([], [html.text("Who am I? 🥸")]),
          card.description([], [
            html.text("Enter the first player to start a new game"),
          ]),
        ]),
        card.content([], [
          form.form(
            [
              attribute.class("space-y-8"),
              event.on_submit(fn(values) {
                let assert Ok(name) = list.key_find(values, "name")
                StartGame(player_name: name)
              }),
            ],
            [
              input.input([
                input.name("name"),
                input.id("name"),
                input.placeholder("John Doe"),
                attribute.required(True),
              ]),
              button.submit([], [
                html.text("Start Game"),
              ]),
            ],
          ),
        ]),
      ])
    }
    Game(players:, local_player_id: _, mode: Editing) -> {
      let player_input_elements =
        iv.index_map(players, fn(player, index) {
          let index_str = int.to_string(index)

          let el =
            html.div([attribute.class("flex gap-2")], [
              html.div([attribute.class("w-full space-y-2")], [
                html.div([attribute.class("flex gap-2")], [
                  label.label(
                    [
                      attribute.class("w-16"),
                      attribute.for("player_names-" <> index_str),
                    ],
                    [html.text("Name:")],
                  ),
                  input.input([
                    input.id("player_names-" <> index_str),
                    input.name("player_names[]"),
                    input.placeholder("John Doe"),
                    attribute.required(True),
                    attribute.value(player.name),
                    event.on_input(fn(name) {
                      UpdatePlayerName(player.id, name)
                    }),
                  ]),
                ]),
                html.div([attribute.class("flex gap-2")], [
                  label.label(
                    [
                      attribute.class("w-16"),
                      attribute.for("player_identities-" <> index_str),
                    ],
                    [html.text("Identity:")],
                  ),
                  input.password([
                    input.id("player_identities-" <> index_str),
                    input.name("player_identities[]"),
                    attribute.required(True),
                    attribute.value(player.identity),
                    event.on_input(fn(identity) {
                      UpdatePlayerIdentity(player.id, identity)
                    }),
                  ]),
                ]),
              ]),
              button.icon_outline([event.on_click(RemovePlayer(index))], [
                icon_x(),
              ]),
            ])
          #(player.id, el)
        })
      let player_inputs = keyed.fragment(iv.to_list(player_input_elements))

      card.card([], [
        card.header([attribute.class("flex")], [
          html.div([attribute.class("w-full space-y-2")], [
            card.title([], [html.text("Who am I? 🥸")]),
            card.description([], [
              html.text(
                "Enter the other players and assign them their identities.",
              ),
            ]),
          ]),
          button.destructive([event.on_click(ResetGameClicked)], [
            html.text("Reset"),
          ]),
        ]),
        card.content([], [
          form.form(
            [
              attribute.class("space-y-8"),
              event.on_submit(fn(values) {
                let assert Ok(action) = list.key_find(values, "action")
                let assert Ok(action) =
                  decode.run(dynamic.string(action), button_action_decoder())
                case action {
                  SwitchToIdentitiesAction -> {
                    SwitchToIdentitiesView
                  }
                  ShareGameAction -> {
                    ShareGameView
                  }
                }
              }),
            ],
            [
              player_inputs,
              html.div([attribute.class("flex flex-col gap-4")], [
                button.outline([event.on_click(AddPlayer)], [
                  html.text("Add Player"),
                ]),
                html.div([attribute.class("flex w-full gap-4")], [
                  button.submit(
                    [
                      attribute.class("flex-grow"),
                      attribute.name("action"),
                      attribute.value(button_action_to_string(ShareGameAction)),
                    ],
                    [html.text("Share Game")],
                  ),
                  button.submit(
                    [
                      attribute.class("flex-grow"),
                      attribute.name("action"),
                      attribute.value(button_action_to_string(
                        SwitchToIdentitiesAction,
                      )),
                    ],
                    [html.text("View Identities")],
                  ),
                ]),
              ]),
            ],
          ),
        ]),
      ])
    }
    Game(players:, local_player_id: option.None, mode: Identities) -> {
      let player_elements =
        iv.map(players, fn(player) {
          #(
            player.id,
            html.li([], [
              button.outline(
                [
                  attribute.class("w-full block text-left"),
                  event.on_click(ChooseLocalPlayer(player.id)),
                ],
                [
                  html.p([attribute.class("font-semibold")], [
                    html.text(player.name),
                  ]),
                ],
              ),
            ]),
          )
        })
      let player_identities =
        keyed.ul([attribute.class("space-y-4")], iv.to_list(player_elements))

      card.card([], [
        card.header([attribute.class("flex")], [
          html.div([attribute.class("w-full space-y-2")], [
            card.title([], [html.text("Who am I? 🥸")]),
            card.description([], [
              html.text(
                "Choose your name. Your identity will be hidden from you.",
              ),
            ]),
          ]),
          button.destructive([event.on_click(ResetGameClicked)], [
            html.text("Reset"),
          ]),
        ]),
        card.content([], [
          form.form(
            [
              attribute.class("space-y-8"),
              event.on_submit(fn(values) {
                let assert Ok(name) = list.key_find(values, "name")
                StartGame(player_name: name)
              }),
            ],
            [
              player_identities,
              html.div([attribute.class("flex w-full gap-4")], [
                button.button(
                  [
                    attribute.class("flex-grow"),
                    event.on_click(ShareGameView),
                  ],
                  [html.text("Share Game")],
                ),
                button.button(
                  [
                    attribute.class("flex-grow"),
                    event.on_click(SwitchToEditingView),
                  ],
                  [html.text("Back to Edit")],
                ),
              ]),
            ],
          ),
        ]),
      ])
    }
    Game(
      players:,
      local_player_id: option.Some(local_player_id),
      mode: Identities,
    ) -> {
      let player_elements =
        iv.map(players, fn(player) {
          #(
            player.id,
            html.li([], [
              button.outline(
                [attribute.class("w-full block text-left h-auto space-y-2")],
                [
                  html.p([attribute.class("font-semibold")], [
                    html.text(player.name),
                  ]),
                  {
                    case local_player_id == player.id {
                      True ->
                        html.p([attribute.class("blur-xs")], [
                          html.text(player.identity),
                        ])
                      False -> html.p([], [html.text(player.identity)])
                    }
                  },
                ],
              ),
            ]),
          )
        })
      let player_identities =
        keyed.ul([attribute.class("space-y-4")], iv.to_list(player_elements))

      card.card([], [
        card.header([attribute.class("flex")], [
          html.div([attribute.class("w-full space-y-2")], [
            card.title([], [html.text("Who am I? 🥸")]),
            card.description([], [
              html.text("Enjoy the game!"),
            ]),
          ]),
          button.destructive([event.on_click(ResetGameClicked)], [
            html.text("Reset"),
          ]),
        ]),
        card.content([], [
          form.form(
            [
              attribute.class("space-y-8"),
              event.on_submit(fn(values) {
                let assert Ok(name) = list.key_find(values, "name")
                StartGame(player_name: name)
              }),
            ],
            [
              player_identities,
              html.div([attribute.class("flex w-full gap-4")], [
                button.button(
                  [
                    attribute.class("flex-grow"),
                    event.on_click(ShareGameView),
                  ],
                  [html.text("Share Game")],
                ),
                button.button(
                  [
                    attribute.class("flex-grow"),
                    event.on_click(SwitchToEditingView),
                  ],
                  [html.text("Back to Edit")],
                ),
              ]),
            ],
          ),
        ]),
      ])
    }
    Game(players: _, local_player_id: _, mode: ShareGame) -> {
      card.card([], [
        card.header([attribute.class("flex")], [
          html.div([attribute.class("w-full space-y-2")], [
            card.title([], [html.text("Who am I? 🥸")]),
            card.description([], [
              html.text("Let your friends scan the QR Code."),
            ]),
          ]),
          button.destructive([event.on_click(ResetGameClicked)], [
            html.text("Reset"),
          ]),
        ]),
        card.content([], [
          html.div([], [render_qrcode(get_current_uri_as_string())]),
          html.div([attribute.class("flex w-full gap-4")], [
            button.button(
              [
                attribute.class("flex-grow"),
                event.on_click(SwitchToEditingView),
              ],
              [html.text("Back to Edit")],
            ),
            button.button(
              [
                attribute.class("flex-grow"),
                event.on_click(SwitchToIdentitiesView),
              ],
              [html.text("View Identities")],
            ),
          ]),
        ]),
      ])
    }
  }

  html.div([attribute.class("p-20 w-full flex justify-center")], [
    html.div([attribute.class("w-full max-w-3xl")], [main]),
  ])
}

pub fn render_qrcode(uri: String) -> Element(model) {
  let assert Ok(matrix) =
    glqr.new(uri)
    |> glqr.generate()

  let svg = glqr.to_svg(matrix)

  element.unsafe_raw_html("", "div", [attribute.class("max-w-md")], svg)
}

pub fn icon_x() {
  svg.svg(
    [
      attribute.class("lucide lucide-x-icon lucide-x"),
      attribute("stroke-linejoin", "round"),
      attribute("stroke-linecap", "round"),
      attribute("stroke-width", "2"),
      attribute("stroke", "currentColor"),
      attribute("fill", "none"),
      attribute("viewBox", "0 0 24 24"),
      attribute("height", "24"),
      attribute("width", "24"),
      attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([attribute("d", "M18 6 6 18")]),
      svg.path([attribute("d", "m6 6 12 12")]),
    ],
  )
}

@external(javascript, "./who.ffi.mjs", "confirm")
pub fn confirm(message: String) -> Bool

@external(javascript, "./who.ffi.mjs", "alert")
pub fn alert(message: String) -> Nil

@external(javascript, "./who.ffi.mjs", "encode_uri_component")
pub fn encode_uri_component(str: String) -> String

@external(javascript, "./who.ffi.mjs", "decode_uri_component")
pub fn decode_uri_component(str: String) -> String

@external(javascript, "./who.ffi.mjs", "to_base_64")
pub fn to_base64(str: String) -> String

@external(javascript, "./who.ffi.mjs", "from_base_64")
pub fn from_base64(str: String) -> String

@external(javascript, "./who.ffi.mjs", "random_id")
pub fn random_id(length: Int) -> String

@external(javascript, "./who.ffi.mjs", "replace_state")
pub fn replace_state(url: String) -> Nil

@external(javascript, "./who.ffi.mjs", "get_current_uri_as_string")
pub fn get_current_uri_as_string() -> String
