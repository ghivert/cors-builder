import gleam/erlang/process
import gleam/http
import mist
import simple_cors as cors
import wisp.{type Request, type Response}

fn cors() {
  cors.new()
  |> cors.allow_origin("http://localhost:3000")
  |> cors.allow_origin("http://localhost:4000")
  |> cors.allow_method(http.Get)
  |> cors.allow_method(http.Post)
}

fn main_handler(req: Request) -> Response {
  use _req <- cors.wisp_handle(req, cors())
  wisp.ok()
}

pub fn main() {
  let secret_key = wisp.random_string(64)
  let assert Ok(_) =
    main_handler
    |> wisp.mist_handler(secret_key)
    |> mist.new()
    |> mist.port(8080)
    |> mist.start_http()
  process.sleep(5000)
}
