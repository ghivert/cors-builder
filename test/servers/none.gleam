import cors_builder as cors
import gleam/bytes_builder
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import mist.{type Connection, type ResponseData}

pub fn run(req: Request(Connection)) -> Response(ResponseData) {
  use _req <- cors.mist_handle(req, cors.new())
  let empty = mist.Bytes(bytes_builder.from_string("OK"))
  response.new(200)
  |> response.set_body(empty)
}
