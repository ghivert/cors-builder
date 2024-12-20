import cors_builder as cors
import gleam/bytes_tree
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import mist.{type Connection, type ResponseData}

pub fn run(req: Request(Connection)) -> Response(ResponseData) {
  use _req <- cors.mist_middleware(req, cors.new())
  let empty = mist.Bytes(bytes_tree.from_string("OK"))
  response.new(200)
  |> response.set_body(empty)
}
