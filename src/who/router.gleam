import lustre/element
import who/middleware
import wisp

pub fn handle_request(req: wisp.Request, ctx: middleware.Context) {
  use req <- middleware.middleware(req, ctx)
  case wisp.path_segments(req) {
    [] -> serve_html(pages.home(), 200)
  }
}

fn serve_html(el: element.Element(a), status: Int) -> wisp.Response {
  [el]
  |> layout.root()
  |> element.to_document_string_tree
  |> wisp.html_response(status)
}
