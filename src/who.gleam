import glaze/basecoat/button
import glaze/basecoat/card
import glaze/basecoat/form
import glaze/basecoat/input
import glaze/basecoat/label
import gleam/int
import gleam/list
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
  Identities
}

pub type Model {
  NewGame
  Game(players: iv.Array(Player), local_player: String, mode: ViewMode)
}

pub fn init(_: Nil) -> #(Model, Effect(Message)) {
  let model = NewGame
  #(model, effect.none())
}

pub type Message {
  StartGame(player_name: String)
  ChooseLocalPlayer(local_player: String)
  RemovePlayer(index: Int)
  AddPlayer
  ResetGameClicked
  ResetGameConfirmed
  SwitchToIdentitiesView
  SwitchToEditingView
}

pub fn create_player_id() {
  random_id(7)
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
              local_player: "",
              mode: Editing,
            )
          #(model, effect.none())
        }
        ChooseLocalPlayer(_)
        | RemovePlayer(_)
        | AddPlayer
        | ResetGameClicked
        | ResetGameConfirmed
        | SwitchToIdentitiesView
        | SwitchToEditingView -> panic as "reached impossible state"
      }
    }
    Game(players:, local_player: _, mode: _) -> {
      case message {
        ChooseLocalPlayer(local_player:) -> {
          let model =
            Game(..model, local_player: local_player, mode: Identities)
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
              #(model, effect.none())
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
          #(model, effect.none())
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
          #(NewGame, effect.none())
        }
        SwitchToIdentitiesView -> {
          let model = Game(..model, local_player: "", mode: Identities)
          #(model, effect.none())
        }
        SwitchToEditingView -> {
          let model = Game(..model, local_player: "", mode: Editing)
          #(model, effect.none())
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
    Game(players:, local_player: _, mode: Editing) -> {
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
                    [
                      html.text("Name:"),
                    ],
                  ),
                  input.input([
                    input.id("player_names-" <> index_str),
                    input.name("player_names[]"),
                    input.placeholder("John Doe"),
                    attribute.required(True),
                    attribute.default_value(player.name),
                  ]),
                ]),
                html.div([attribute.class("flex gap-2")], [
                  label.label(
                    [
                      attribute.class("w-16"),
                      attribute.for("player_identities-" <> index_str),
                    ],
                    [
                      html.text("Identity:"),
                    ],
                  ),
                  input.password([
                    input.id("player_identities-" <> index_str),
                    input.name("player_identities[]"),
                    attribute.required(True),
                    attribute.default_value(player.identity),
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
                let assert Ok(name) = list.key_find(values, "name")
                StartGame(player_name: name)
              }),
            ],
            [
              player_inputs,
              html.div([attribute.class("flex flex-col gap-4")], [
                button.outline([event.on_click(AddPlayer)], [
                  html.text("Add Player"),
                ]),
                html.div([attribute.class("flex w-full gap-4")], [
                  button.button([attribute.class("flex-grow")], [
                    html.text("Share Game"),
                  ]),
                  button.button(
                    [
                      event.on_click(SwitchToIdentitiesView),
                      attribute.class("flex-grow"),
                    ],
                    [
                      html.text("View Identities"),
                    ],
                  ),
                ]),
              ]),
            ],
          ),
        ]),
      ])
    }
    Game(players:, local_player: "", mode: Identities) -> {
      let player_identities =
        iv.map(players, fn(player) {
          keyed.div([], [#(player.id, html.div([], []))])
        })

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
            list.append(iv.to_list(player_identities), [
              button.button([event.on_click(SwitchToEditingView)], [
                html.text("Back to Edit"),
              ]),
            ]),
          ),
        ]),
      ])
    }
    Game(players: _, local_player: _, mode: Identities) -> {
      html.div([], [html.text("")])
    }
  }

  html.div([attribute.class("p-20 w-full flex justify-center")], [
    html.div([attribute.class("w-full max-w-3xl")], [main]),
  ])
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
