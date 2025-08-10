import lustre/attribute.{attribute}
import lustre/element
import lustre/element/html

pub fn navbar() {
  html.div([attribute.class("navbar bg-base-100 shadow-sm")], [
    html.div([attribute.class("flex-1")], [
      html.a([attribute.href("/"), attribute.class("btn btn-ghost text-xl")], [
        html.text("🥸 Who am I?"),
      ]),
    ]),
    html.div([attribute.class("flex-none")], [
      html.ul([attribute.class("menu menu-horizontal px-1")], [
        html.li([], [
          html.a([attribute.href("/characters")], [html.text("Characters")]),
        ]),
        html.li([], [
          html.a([attribute.href("/sessions")], [html.text("Sessions")]),
        ]),
      ]),
    ]),
  ])
}

pub fn root(elements: List(element.Element(a))) -> element.Element(a) {
  html.html([attribute.data("theme", "corporate")], [
    html.head([], [
      html.title([], "🥸 Who am I?"),
      html.meta([
        attribute.name("viewport"),
        attribute.content("width=device-width, initial-scale=1"),
      ]),
      html.link([
        attribute.rel("icon"),
        attribute.href("https://fav.farm/%F0%9F%A5%B8"),
      ]),
      html.link([
        attribute.rel("stylesheet"),
        attribute.href("/static/vendor/daisyui.css"),
      ]),
      html.link([
        attribute.rel("stylesheet"),
        attribute.href("/static/vendor/fonts/inter.css"),
      ]),
      html.link([attribute.rel("stylesheet"), attribute.href("/static/app.css")]),
      html.script(
        [
          attribute.src("/static/vendor/tailwind.js"),
          attribute("defer", "defer"),
        ],
        "",
      ),
    ]),
    html.body([], elements),
  ])
}
