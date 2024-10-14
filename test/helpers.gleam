import gleam/http/response.{type Response}
import gleeunit/should

pub fn header_should_equal(res: Response(a), header: #(String, String)) {
  let #(header, content) = header
  res
  |> response.get_header(header)
  |> should.be_ok()
  |> should.equal(content)
}

pub fn header_should_not_exists(res: Response(a), header: String) {
  res
  |> response.get_header(header)
  |> should.be_error()
}

@external(erlang, "cors_builder_ffi", "magic")
pub fn magic(a: a) -> b
