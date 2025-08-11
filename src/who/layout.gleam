import lustre/attribute.{attribute}
import lustre/element
import lustre/element/html

pub fn root(elements: List(element.Element(a))) -> element.Element(a) {
  html.html([attribute.data("theme", "corporate")], [
    html.head([], [
      html.title([], "Who am I?"),
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
