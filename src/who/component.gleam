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

pub fn close_icon() -> Element(a) {
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

pub fn sun_icon() -> Element(msg) {
  svg.svg(
    [
      attribute("xmlns", "http://www.w3.org/2000/svg"),
      attribute("width", "24"),
      attribute("height", "24"),
      attribute("viewBox", "0 0 24 24"),
      attribute("fill", "none"),
      attribute("stroke", "currentColor"),
      attribute("stroke-width", "2"),
      attribute("stroke-linecap", "round"),
      attribute("stroke-linejoin", "round"),
    ],
    [
      svg.circle([
        attribute("cx", "12"),
        attribute("cy", "12"),
        attribute("r", "4"),
      ]),
      svg.path([attribute("d", "M12 2v2")]),
      svg.path([attribute("d", "M12 20v2")]),
      svg.path([attribute("d", "m4.93 4.93 1.41 1.41")]),
      svg.path([attribute("d", "m17.66 17.66 1.41 1.41")]),
      svg.path([attribute("d", "M2 12h2")]),
      svg.path([attribute("d", "M20 12h2")]),
      svg.path([attribute("d", "m6.34 17.66-1.41 1.41")]),
      svg.path([attribute("d", "m19.07 4.93-1.41 1.41")]),
    ],
  )
}

pub fn moon_icon() -> Element(msg) {
  svg.svg(
    [
      attribute("xmlns", "http://www.w3.org/2000/svg"),
      attribute("width", "24"),
      attribute("height", "24"),
      attribute("viewBox", "0 0 24 24"),
      attribute("fill", "none"),
      attribute("stroke", "currentColor"),
      attribute("stroke-width", "2"),
      attribute("stroke-linecap", "round"),
      attribute("stroke-linejoin", "round"),
    ],
    [
      svg.path([attribute("d", "M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z")]),
    ],
  )
}
