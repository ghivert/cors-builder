import gleam/function
import gleam/http
import gleam/http/request
import gleam/list
import gleam/result
import gleeunit/should
import helpers
import servers

pub fn options_test() {
  use request <- result.try(request.to("http://localhost:8080/"))
  let request =
    request
    |> request.set_header("origin", "http://localhost:8000")
    |> request.set_method(http.Options)

  request
  |> helpers.magic()
  |> servers.partial()
  |> function.tap(fn(res) {
    res.status
    |> should.equal(204)

    list.new()
    |> list.prepend(#("access-control-allow-origin", "http://localhost:3000"))
    |> list.prepend(#("access-control-allow-methods", "GET,POST"))
    |> list.map(helpers.header_should_equal(res, _))

    list.new()
    |> list.prepend("access-control-expose-headers")
    |> list.prepend("access-control-max-age")
    |> list.prepend("access-control-allow-credentials")
    |> list.prepend("access-control-allow-headers")
    |> list.map(helpers.header_should_not_exists(res, _))
  })
  |> Ok
}

pub fn get_test() {
  use request <- result.try(request.to("http://localhost:8080/"))
  let request =
    request
    |> request.set_header("origin", "http://localhost:3000")

  request
  |> helpers.magic()
  |> servers.partial()
  |> function.tap(fn(res) {
    res.status
    |> should.equal(200)

    list.new()
    |> list.prepend(#("access-control-allow-origin", "http://localhost:3000"))
    |> list.prepend(#("access-control-allow-methods", "GET,POST"))
    |> list.map(helpers.header_should_equal(res, _))

    list.new()
    |> list.prepend("access-control-expose-headers")
    |> list.prepend("access-control-max-age")
    |> list.prepend("access-control-allow-credentials")
    |> list.prepend("access-control-allow-headers")
    |> list.map(helpers.header_should_not_exists(res, _))
  })
  |> Ok
}
