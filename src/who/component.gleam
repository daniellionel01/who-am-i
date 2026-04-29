import glqr
import lustre/attribute.{attribute}
import lustre/element.{type Element}
import lustre/element/svg

pub fn qrcode(uri: String) -> Element(a) {
  let assert Ok(matrix) =
    glqr.new(uri)
    |> glqr.generate()

  let svg = glqr.to_svg(matrix)

  element.unsafe_raw_html("", "div", [attribute.class("max-w-md")], svg)
}

pub fn icon_x() -> Element(a) {
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
