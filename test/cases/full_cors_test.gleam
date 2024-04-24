import gleam/function
import gleam/http
import gleam/http/request
import gleam/list
import gleam/result
import gleeunit/should
import helpers
import servers

pub fn full_cors_test() {
  use request <- result.try(request.to("http://localhost:8080/"))
  let request =
    request
    |> request.set_header("origin", "http://localhost:8000")
    |> request.set_method(http.Options)

  request
  |> helpers.magic()
  |> servers.full()
  |> function.tap(fn(res) {
    res.status
    |> should.equal(204)

    list.new()
    |> list.prepend(#("access-control-allow-methods", "GET,POST"))
    |> list.prepend(#("access-control-expose-headers", "content-type"))
    |> list.prepend(#("access-control-max-age", "200"))
    |> list.prepend(#("access-control-allow-credentials", "true"))
    |> list.prepend(#("access-control-allow-headers", "content-type"))
    |> list.map(helpers.header_should_equal(res, _))

    ["access-control-allow-origin"]
    |> list.map(helpers.header_should_not_exists(res, _))
  })
  |> Ok
}

pub fn full_cors_origin_test() {
  use request <- result.try(request.to("http://localhost:8080/"))
  let request =
    request
    |> request.set_header("origin", "http://localhost:3000")
    |> request.set_method(http.Options)

  request
  |> helpers.magic()
  |> servers.full()
  |> function.tap(fn(res) {
    res.status
    |> should.equal(204)

    list.new()
    |> list.prepend(#("access-control-allow-origin", "http://localhost:3000"))
    |> list.prepend(#("vary", "origin"))
    |> list.prepend(#("access-control-allow-methods", "GET,POST"))
    |> list.prepend(#("access-control-expose-headers", "content-type"))
    |> list.prepend(#("access-control-max-age", "200"))
    |> list.prepend(#("access-control-allow-credentials", "true"))
    |> list.prepend(#("access-control-allow-headers", "content-type"))
    |> list.map(helpers.header_should_equal(res, _))
  })
  |> Ok
}
