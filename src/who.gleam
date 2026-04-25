import glaze/basecoat/button
import glaze/basecoat/card
import glaze/basecoat/form
import glaze/basecoat/input
import glaze/basecoat/label
import gleam/list
import gleam/option
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

pub type Player {
  Player(name: String, identity: String)
}

/// local_player refers to the player in the current browser.
///
pub type Model {
  Model(players: List(Player), local_player: option.Option(String))
}

pub fn init(_: Nil) -> #(Model, Effect(Message)) {
  let model = Model(players: [], local_player: option.None)
  #(model, effect.none())
}

pub type Message {
  StartGame(starting_player_name: String)
  ChooseLocalPlayer(local_player: String)
}

pub fn update(model: Model, message: Message) -> #(Model, Effect(Message)) {
  case message {
    StartGame(starting_player_name:) -> {
      let model =
        Model(
          players: [Player(name: starting_player_name, identity: "")],
          local_player: option.Some(starting_player_name),
        )
      #(model, effect.none())
    }
    ChooseLocalPlayer(local_player:) -> {
      let model = Model(..model, local_player: option.Some(local_player))
      #(model, effect.none())
    }
  }
}

pub fn view(model: Model) -> Element(Message) {
  let main = case model {
    Model(players: [], local_player: option.None) -> {
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
                StartGame(starting_player_name: name)
              }),
            ],
            [
              input.input([
                input.name("name"),
                input.id("name"),
                input.placeholder("John Doe"),
              ]),
              button.submit([attribute.class("font-semibold")], [
                html.text("Start Game"),
              ]),
            ],
          ),
        ]),
      ])
    }
    Model(players:, local_player: option.None) -> {
      html.div([], [html.text("")])
    }
    Model(players:, local_player: option.Some(local_player)) -> {
      html.div([], [html.text("")])
    }
  }

  html.div([attribute.class("p-20 w-full flex justify-center")], [
    html.div([attribute.class("w-full max-w-3xl")], [main]),
  ])
}
