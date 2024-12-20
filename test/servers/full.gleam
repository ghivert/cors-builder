import cors_builder as cors
import gleam/bytes_tree
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response
import mist.{type Connection}

fn cors() {
  cors.new()
  |> cors.allow_origin("http://localhost:3000")
  |> cors.allow_origin("http://localhost:4000")
  |> cors.allow_method(http.Get)
  |> cors.allow_method(http.Post)
  |> cors.expose_header("content-type")
  |> cors.max_age(200)
  |> cors.allow_credentials()
  |> cors.allow_header("content-type")
}

pub fn run(req: Request(Connection)) {
  use _req <- cors.mist_middleware(req, cors())
  let empty = mist.Bytes(bytes_tree.new())
  response.new(200)
  |> response.set_body(empty)
}
