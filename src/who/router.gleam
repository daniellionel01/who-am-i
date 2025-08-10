import lustre/element
import who/layout
import who/middleware
import who/web/page
import wisp

pub fn handle_request(req: wisp.Request, ctx: middleware.Context) {
  use req <- middleware.middleware(req, ctx)
  case wisp.path_segments(req) {
    [] -> serve_html(page.home(), 200)
    _ -> wisp.not_found()
  }
}

fn serve_html(el: element.Element(a), status: Int) -> wisp.Response {
  [el]
  |> layout.root()
  |> element.to_document_string_tree
  |> wisp.html_response(status)
}
