import glaze/basecoat/button
import glaze/basecoat/card
import glaze/basecoat/form
import glaze/basecoat/input
import glaze/basecoat/label
import glaze/basecoat/theme_switcher
import gleam/dynamic
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import gleam/uri
import iv
import lustre
import lustre/attribute.{attribute}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/element/keyed
import lustre/event
import who/browser
import who/component
import who/player

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

pub type ViewMode {
  Editing
  ShareGame
  Identities
}

pub type Model {
  NewGame
  Game(
    players: iv.Array(player.Player),
    local_player_id: option.Option(player.PlayerId),
    mode: ViewMode,
  )
}

pub fn init(_: Nil) -> #(Model, Effect(Message)) {
  // When we initially load the site, we either start a new game
  // or let the user pick their identity, based on if we successfully
  // decode player names & identities from the search query.
  //
  let model = case uri.parse(browser.location_to_string()) {
    Error(_) -> NewGame
    Ok(uri) -> {
      case game_state_from_uri(uri) {
        Error(_) -> NewGame
        Ok(players) -> {
          case players {
            [] -> NewGame
            _ -> {
              let players = iv.from_list(players)

              // If not all players have a name & identity yet, we render the edit form.
              //
              let all_names_and_identities =
                iv.all(players, fn(player) {
                  !string.is_empty(player.name)
                  && !string.is_empty(player.identity)
                })
              let mode = case all_names_and_identities {
                False -> Editing
                True -> Identities
              }

              Game(players:, local_player_id: option.None, mode:)
            }
          }
        }
      }
    }
  }

  #(model, effect.none())
}

pub type Message {
  StartGame(player_name: String)
  ChooseLocalPlayer(player_id: player.PlayerId)

  RemovePlayer(index: Int)
  UpdatePlayerName(id: player.PlayerId, name: String)
  UpdatePlayerIdentity(id: player.PlayerId, identity: String)
  AddPlayer

  ResetGameClicked
  ResetGameConfirmed

  SwitchToIdentitiesView
  SwitchToEditingView
  SwitchToShareGameView
}

/// We use this type do avoid string logic
/// when deciding what message to dispatch
/// when the form is dispatched.
///
/// Since we want to make use of the browser-native form
/// validation (for `required`), we have multiple submit
/// buttons in some views which then are routed to the specific
/// message in the on_submit handler of the form.
///
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

pub fn game_state_to_search(
  players: List(player.Player),
) -> List(#(String, String)) {
  list.append(
    list.map(players, fn(player) { #("names[]", player.name) }),
    list.map(players, fn(player) {
      #("identities[]", browser.to_base64(player.identity))
    }),
  )
}

/// This effect updates the search query in the URL of the browser
/// to encode all player names and identities.
///
pub fn update_uri(model: Model) -> Effect(a) {
  effect.from(fn(_dispatch) {
    case model {
      NewGame -> {
        // This resets any existing search query in the URL
        let pathname = browser.location_pathname()
        browser.history_replace_state(pathname)
      }
      Game(players:, local_player_id: _, mode: _) -> {
        let pathname = browser.location_pathname()

        let search =
          players
          |> iv.to_list
          |> game_state_to_search
          |> uri.query_to_string

        browser.history_replace_state(pathname <> "?" <> search)
      }
    }
  })
}

pub fn game_state_from_uri(uri: uri.Uri) -> Result(List(player.Player), Nil) {
  case uri.query {
    option.None -> Ok([])
    option.Some(query) -> {
      use query <- result.try(uri.parse_query(query))

      let names = list.key_filter(query, "names[]")
      let identities = list.key_filter(query, "identities[]")

      let players =
        list.zip(names, identities)
        |> list.map(fn(item) {
          let #(name, identity) = item
          let identity = browser.from_base64(identity)
          player.Player(id: player.create_id(), name:, identity:)
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
                player.Player(
                  id: player.create_id(),
                  name: player_name,
                  identity: "",
                ),
              ]),
              local_player_id: option.None,
              mode: Editing,
            )
          #(model, update_uri(model))
        }

        // These messages should not be dispatched in this state of the game.
        //
        ChooseLocalPlayer(_)
        | RemovePlayer(_)
        | AddPlayer
        | ResetGameClicked
        | ResetGameConfirmed
        | SwitchToIdentitiesView
        | SwitchToShareGameView
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
                browser.alert(
                  "You cannot remove the player who started the game!",
                )
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
              player.Player(id: player.create_id(), name: "", identity: ""),
            )
          let model = Game(..model, players:)
          #(model, update_uri(model))
        }
        ResetGameClicked -> {
          let confirm_dialog = {
            use dispatch, _root <- effect.before_paint
            let agreed = browser.confirm("Are you sure you want to reset?")
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
        SwitchToShareGameView -> {
          let model = Game(..model, mode: ShareGame)
          #(model, effect.none())
        }
        UpdatePlayerName(id:, name:) -> {
          let players =
            iv.map(model.players, fn(player) {
              case player.id == id {
                False -> player
                True -> player.Player(..player, name:)
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
                True -> player.Player(..player, identity:)
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
      new_game_screen()
    }
    Game(players:, local_player_id: _, mode: Editing) -> {
      editing_screen(players)
    }
    Game(players:, local_player_id: option.None, mode: Identities) -> {
      choose_identity_screen(players)
    }
    Game(
      players:,
      local_player_id: option.Some(local_player_id),
      mode: Identities,
    ) -> {
      identities_view(players, local_player_id)
    }
    Game(players: _, local_player_id: _, mode: ShareGame) -> {
      share_game_screen()
    }
  }

  html.div([attribute.class("p-4 sm:p-20 w-full flex justify-center")], [
    html.div([attribute.class("w-full max-w-3xl")], [main]),

    theme_switcher.init_script(),
  ])
}

pub fn reset_button() -> Element(Message) {
  button.outline([event.on_click(ResetGameClicked)], [
    html.text("Reset"),
  ])
}

/// This is a card component that wraps every screen
/// in this application.
///
pub fn application_card(
  description: String,
  action: option.Option(Element(Message)),
  content: List(Element(Message)),
) -> Element(Message) {
  card.card([], [
    card.header([attribute.class("flex")], [
      html.div([attribute.class("w-full space-y-2")], [
        card.title([], [html.text("Who am I? 🥸")]),
        card.description([], [
          html.text(description),
        ]),
      ]),
      html.div([attribute.class("flex gap-2")], [
        option.unwrap(action, element.fragment([])),
        button.icon_outline(
          [
            attribute(
              "onclick",
              "document.dispatchEvent(new CustomEvent('basecoat:theme'))",
            ),
          ],
          [
            html.span([attribute.class("hidden dark:block")], [
              component.sun_icon(),
            ]),
            html.span([attribute.class("block dark:hidden")], [
              component.moon_icon(),
            ]),
          ],
        ),
      ]),
    ]),
    card.content([], content),
    card.footer([attribute.class("border-t pt-4")], [
      html.p([attribute.class("text-sm")], [
        html.span([attribute.class("inline-flex items-center gap-1")], [
          html.text("Made with"),
          html.a(
            [attribute.href("https://gleam.run/"), attribute.class("underline")],
            [html.text("Gleam")],
          ),
          html.text("and"),
          html.a(
            [
              attribute.href("https://hexdocs.pm/lustre/index.html"),
              attribute.class("underline"),
            ],
            [html.text("Lustre")],
          ),
          html.span([attribute.class("inline-block w-6 h-6")], [
            component.lucy(),
          ]),
        ]),
      ]),
    ]),
  ])
}

pub fn new_game_screen() -> Element(Message) {
  application_card("Enter the first player to start a new game", option.None, [
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
  ])
}

pub fn share_game_screen() -> Element(Message) {
  application_card(
    "Let your friends scan the QR Code.",
    option.Some(reset_button()),
    [
      html.div([], [component.qrcode(browser.location_to_string())]),
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
    ],
  )
}

pub fn editing_screen(players: iv.Array(player.Player)) {
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
                event.on_input(fn(name) { UpdatePlayerName(player.id, name) }),
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
              input.input([
                attribute.class(
                  "
                  text-transparent caret-muted-foreground [text-shadow:0_0_14px_var(--muted-foreground)]
                  placeholder:[text-shadow:none] selection:text-transparent selection:[text-shadow:0_0_14px_var(--foreground)]
                ",
                ),
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
            component.close_icon(),
          ]),
        ])
      #(player.id_to_string(player.id), el)
    })
  let player_inputs = keyed.fragment(iv.to_list(player_input_elements))

  application_card(
    "Enter the other players and assign them their identities.",
    option.Some(reset_button()),
    [
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
                SwitchToShareGameView
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
            html.div(
              [attribute.class("flex flex-col sm:flex-row w-full gap-4")],
              [
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
              ],
            ),
          ]),
        ],
      ),
    ],
  )
}

pub fn choose_identity_screen(
  players: iv.Array(player.Player),
) -> Element(Message) {
  let player_elements =
    iv.map(players, fn(player) {
      #(
        player.id_to_string(player.id),
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

  application_card(
    "Choose your name. Your identity will be hidden from you.",
    option.Some(reset_button()),
    [
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
          html.div([attribute.class("flex flex-col sm:flex-row w-full gap-4")], [
            button.button(
              [
                attribute.class("flex-grow"),
                event.on_click(SwitchToShareGameView),
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
    ],
  )
}

pub fn identities_view(
  players: iv.Array(player.Player),
  local_player_id: player.PlayerId,
) -> Element(Message) {
  let player_elements =
    iv.map(players, fn(player) {
      #(
        player.id_to_string(player.id),
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
                    html.p([attribute.class("blur-sm")], [
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

  application_card("Good luck!", option.Some(reset_button()), [
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
        html.div([attribute.class("flex flex-col sm:flex-row w-full gap-4")], [
          button.button(
            [
              attribute.class("flex-grow"),
              event.on_click(SwitchToShareGameView),
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
  ])
}
