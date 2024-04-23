import gleam/bytes_builder
import gleam/erlang/process
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import mist.{type Connection, type ResponseData}
import simple_cors as cors

fn cors() {
  cors.new()
  |> cors.allow_origin("http://localhost:3000")
  |> cors.allow_method(http.Get)
  |> cors.allow_method(http.Post)
}

fn main_handler(req: Request(Connection)) -> Response(ResponseData) {
  use _req <- cors.mist_handle(req, cors())
  let empty = mist.Bytes(bytes_builder.new())
  response.new(200)
  |> response.set_body(empty)
}

pub fn main() {
  let assert Ok(_) =
    main_handler
    |> mist.new()
    |> mist.port(8080)
    |> mist.start_http()
  process.sleep(5000)
}
