import glaze/basecoat/button
import glaze/basecoat/card
import glaze/basecoat/form
import glaze/basecoat/input
import glaze/basecoat/label
import gleam/bool
import gleam/int
import gleam/list
import lustre
import lustre/attribute.{attribute}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/element/svg
import lustre/event

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

pub type Player {
  Player(name: String, identity: String)
}

pub type ViewMode {
  Editing
  Identities
}

pub type Model {
  NewGame
  Game(players: List(Player), local_player: String, mode: ViewMode)
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
}

pub fn update(model: Model, message: Message) -> #(Model, Effect(Message)) {
  case model {
    NewGame -> {
      case message {
        StartGame(player_name:) -> {
          let model =
            Game(
              players: [Player(name: player_name, identity: "")],
              local_player: player_name,
              mode: Editing,
            )
          #(model, effect.none())
        }
        ChooseLocalPlayer(_)
        | RemovePlayer(_)
        | AddPlayer
        | ResetGameClicked
        | ResetGameConfirmed -> panic as "reached impossible state"
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
              // This is super inefficient, since linked lists are more than
              // suboptimal to remove elements from in the middle of the list.
              //
              // A better and more performant implementation would use iv or at least have
              // an additional id for each player that we would filter out without
              // having to rely on the index.
              //
              let players =
                players
                |> list.index_map(fn(item, index) { #(item, index) })
                |> list.filter(fn(row) { row.1 != remove_index })
                |> list.map(fn(row) { row.0 })

              let model = Game(..model, players:)
              #(model, effect.none())
            }
          }
        }
        AddPlayer -> {
          let players =
            list.append(model.players, [Player(name: "", identity: "")])
          let model = Game(..model, players:)
          #(model, effect.none())
        }
        ResetGameClicked -> {
          let confirm_dialog = {
            use dispatch, _root <- effect.before_paint
            let agreed = confirm("Are you sure you want to reset?")
            use <- bool.guard(!agreed, Nil)
            dispatch(ResetGameConfirmed)
          }
          #(model, confirm_dialog)
        }
        ResetGameConfirmed -> {
          #(NewGame, effect.none())
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
    Game(players: _, local_player: "", mode: _) -> {
      todo
    }
    Game(players: _, local_player: _, mode: Identities) -> {
      html.div([], [html.text("")])
    }
    Game(players:, local_player: _, mode: Editing) -> {
      let player_inputs =
        list.index_map(players, fn(player, index) {
          let index_str = int.to_string(index)

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
        })

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
            list.append(player_inputs, [
              html.div([attribute.class("flex flex-col gap-4")], [
                button.outline([event.on_click(AddPlayer)], [
                  html.text("Add Player"),
                ]),
                button.submit([], [
                  html.text("Share Game"),
                ]),
              ]),
            ]),
          ),
        ]),
      ])
    }
  }

  html.div([attribute.class("p-20 w-full flex justify-center")], [
    html.div([attribute.class("w-full max-w-3xl")], [main]),
  ])
}

@external(javascript, "./who.ffi.mjs", "confirm")
pub fn confirm(message: String) -> Bool

@external(javascript, "./who.ffi.mjs", "alert")
pub fn alert(message: String) -> Bool

fn icon_x() {
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
