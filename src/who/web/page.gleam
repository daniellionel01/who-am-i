import lustre/attribute
import lustre/element/html

pub fn home() {
  html.div([], [
    html.div([attribute.class("m-8")], [
      html.button([attribute.class("btn btn-primary")], [html.text("test")]),
    ]),
  ])
}
