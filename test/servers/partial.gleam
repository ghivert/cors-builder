import cors_builder as cors
import gleam/bytes_builder
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import mist.{type Connection, type ResponseData}

fn cors() {
  cors.new()
  |> cors.allow_origin("http://localhost:3000")
  |> cors.allow_method(http.Get)
  |> cors.allow_method(http.Post)
}

pub fn run(req: Request(Connection)) -> Response(ResponseData) {
  use _req <- cors.mist_handle(req, cors())
  let empty = mist.Bytes(bytes_builder.from_string("OK"))
  response.new(200)
  |> response.set_body(empty)
}
