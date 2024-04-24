import gleam/function
import gleam/http
import gleam/http/request
import gleam/list
import gleam/result
import gleeunit/should
import helpers
import servers

/// Should not include any CORS headers.
pub fn no_cors_set_test() {
  use request <- result.try(request.to("http://localhost:9000/"))
  let request =
    request
    |> request.set_header("origin", "http://localhost:3000")
    |> request.set_method(http.Options)

  request
  |> helpers.magic()
  |> servers.none()
  |> function.tap(fn(res) {
    res.status
    |> should.equal(204)

    list.new()
    |> list.prepend("access-control-allow-origin")
    |> list.prepend("access-control-allow-methods")
    |> list.prepend("access-control-expose-headers")
    |> list.prepend("access-control-max-age")
    |> list.prepend("access-control-allow-credentials")
    |> list.prepend("access-control-allow-headers")
    |> list.map(helpers.header_should_not_exists(res, _))
  })
  |> Ok
}
