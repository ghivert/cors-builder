import gleam/bool
import gleam/bytes_builder
import gleam/function
import gleam/http.{type Method}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response, set_header}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/result
import gleam/set.{type Set}
import gleam/string
import mist
import wisp

pub opaque type Origin {
  Wildcard
  Origin(Set(String))
}

pub opaque type Cors {
  Cors(
    allow_origin: Option(Origin),
    expose_headers: Set(String),
    max_age: Option(Int),
    allow_credentials: Option(Bool),
    allow_methods: Set(Method),
    allow_headers: Set(String),
  )
}

pub fn new() -> Cors {
  Cors(
    allow_origin: None,
    expose_headers: set.new(),
    max_age: None,
    allow_credentials: None,
    allow_methods: set.new(),
    allow_headers: set.new(),
  )
}

/// Be extremely careful, you should not use this function in production!
/// Allowing all origins can easily be a huge security flaw!
/// Allow only the origins you need, and use this function only locally, in dev mode.
pub fn allow_all_origins(cors: Cors) {
  let allow_origin = Some(Wildcard)
  Cors(..cors, allow_origin: allow_origin)
}

pub fn allow_origin(cors: Cors, origin: String) {
  let allow_origin = case cors.allow_origin {
    Some(Wildcard) -> Some(Wildcard)
    Some(Origin(content)) -> Some(Origin(set.insert(content, origin)))
    None -> Some(Origin(set.from_list([origin])))
  }
  Cors(..cors, allow_origin: allow_origin)
}

pub fn expose_headers(cors: Cors, header: String) {
  let expose_headers = set.insert(cors.expose_headers, header)
  Cors(..cors, expose_headers: expose_headers)
}

pub fn max_age(cors: Cors, age: Int) {
  let max_age = Some(age)
  Cors(..cors, max_age: max_age)
}

pub fn allow_credentials(cors: Cors) {
  let allow_credentials = Some(True)
  Cors(..cors, allow_credentials: allow_credentials)
}

pub fn allow_method(cors: Cors, method: Method) {
  let allow_methods = set.insert(cors.allow_methods, method)
  Cors(..cors, allow_methods: allow_methods)
}

pub fn allow_header(cors: Cors, header: String) {
  let allow_headers = set.insert(cors.allow_headers, header)
  Cors(..cors, allow_headers: allow_headers)
}

fn set_allowed_origin(cors: Cors, origin: String) {
  let hd = "Access-Control-Allow-Origin"
  case cors.allow_origin {
    None -> function.identity
    Some(Wildcard) -> set_header(_, hd, "*")
    Some(Origin(origins)) -> {
      let origins = set.to_list(origins)
      case origins {
        [o] -> set_header(_, hd, o)
        _ -> {
          let not_origin = !list.contains(origins, origin)
          use <- bool.guard(when: not_origin, return: function.identity)
          fn(res) {
            res
            |> set_header(hd, origin)
            |> set_header("Vary", "Origin")
          }
        }
      }
    }
  }
}

fn set_expose_headers(res: Response(body), cors: Cors) {
  let hd = "Access-Control-Expose-Headers"
  cors.expose_headers
  |> set.to_list()
  |> string.join(",")
  |> set_header(res, hd, _)
}

fn set_max_age(res: Response(body), cors: Cors) {
  let hd = "Access-Control-Max-Age"
  cors.max_age
  |> option.map(fn(a) { set_header(res, hd, int.to_string(a)) })
  |> option.unwrap(res)
}

fn set_allow_credentials(res: Response(body), cors: Cors) {
  let hd = "Access-Control-Allow-Credentials"
  cors.allow_credentials
  |> option.map(fn(_) { set_header(res, hd, "true") })
  |> option.unwrap(res)
}

fn method_to_string(method: Method) {
  case method {
    http.Get -> "GET"
    http.Post -> "POST"
    http.Head -> "HEAD"
    http.Put -> "PUT"
    http.Delete -> "DELETE"
    http.Trace -> "TRACE"
    http.Connect -> "CONNECT"
    http.Options -> "OPTIONS"
    http.Patch -> "PATCH"
    http.Other(content) -> content
  }
}

fn set_allow_methods(res: Response(body), cors: Cors) {
  let hd = "Access-Control-Allow-Methods"
  let methods = set.to_list(cors.allow_methods)
  case list.is_empty(methods) {
    True -> res
    False ->
      methods
      |> list.map(method_to_string)
      |> string.join(",")
      |> set_header(res, hd, _)
  }
}

fn set_allow_headers(res: Response(body), cors: Cors) {
  let hd = "Access-Control-Allow-Headers"
  let headers = set.to_list(cors.allow_headers)
  case list.is_empty(headers) {
    True -> res
    False ->
      headers
      |> string.join(",")
      |> set_header(res, hd, _)
  }
}

fn set_response(res: Response(body), cors: Cors, origin: Option(String)) {
  res
  |> set_allowed_origin(cors, option.unwrap(origin, ""))
  |> set_expose_headers(cors)
  |> set_max_age(cors)
  |> set_allow_credentials(cors)
  |> set_allow_methods(cors)
  |> set_allow_headers(cors)
}

pub fn set_cors(res: Response(response), cors: Cors) {
  set_response(res, cors, None)
}

pub fn set_cors_origin(res: Response(response), cors: Cors, origin: String) {
  set_response(res, cors, Some(origin))
}

fn find_origin(req: Request(connection)) {
  req.headers
  |> list.find(fn(h) { pair.first(h) == "Origin" })
  |> result.map(pair.second)
  |> result.unwrap("")
}

fn middleware(
  empty: resdata,
  req: Request(connection),
  cors: Cors,
  handler: fn(Request(connection)) -> Response(resdata),
) {
  let res = case req.method {
    http.Options -> response.set_body(response.new(204), empty)
    _ -> handler(req)
  }
  req
  |> find_origin()
  |> set_cors_origin(res, cors, _)
}

pub fn mist_handle(
  req: Request(mist.Connection),
  cors: Cors,
  handler: fn(Request(mist.Connection)) -> Response(mist.ResponseData),
) {
  bytes_builder.new()
  |> mist.Bytes()
  |> middleware(req, cors, handler)
}

pub fn wisp_handle(
  req: wisp.Request,
  cors: Cors,
  handler: fn(wisp.Request) -> wisp.Response,
) {
  middleware(wisp.Empty, req, cors, handler)
}
