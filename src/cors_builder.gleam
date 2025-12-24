//// `cors_builder` provides an easy way to build and inject your CORS configuration
//// in your server. The package tries to remains as simplest as possible, while
//// guaranteeing type-safety and correctness of the CORS configuration.
////
//// ## Quickstart
////
//// Import the `cors_builder` package, and configure your CORS. Finally, use the
//// correct corresponding middleware for your server, and you're done!
////
//// ```
//// import cors_builder as cors
//// import gleam/http
//// import mist
//// import wisp.{type Request, type Response}
////
//// // Dummy example.
//// fn cors() {
////   cors.new()
////   |> cors.allow_origin("http://localhost:3000")
////   |> cors.allow_origin("http://localhost:4000")
////   |> cors.allow_method(http.Get)
////   |> cors.allow_method(http.Post)
//// }
////
//// fn handler(req: Request) -> Response {
////   use req <- cors.wisp_middleware(req, cors())
////   wisp.ok()
//// }
////
//// fn main() {
////   handler
////   |> wisp.mist_handler(secret_key)
////   |> mist.new()
////   |> mist.port(3000)
////   |> mist.start_http()
//// }
//// ```
////
//// ## Low-level functions
////
//// If you're building your framework or you know what you're doing, you should
//// take a look at [`set_cors`](#set_cors) and
//// [`set_cors_multiple_origin`](#set_cors_multiple_origin). They allow to
//// inject the CORS in your response, and it allows you to create your
//// middleware to use with the bare CORS data.
////
//// If you're not building your framework, you should _probably_ heads to [`wisp`](https://hexdocs.pm/wisp)
//// to get you started. It's better to familiarize with the ecosystem before
//// jumping right in your custom code.

import cors_builder/internal/function
import gleam/bool
import gleam/bytes_tree
import gleam/http.{type Method}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response, set_header}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/result
import gleam/set.{type Set}
import gleam/string
import gleam/uri
import mist
import wisp

/// Indicates the origin for CORS. Could be any origin (wildcard `"*"`) or a
/// list of domains. In case it's a list of domains, one domain will be returned
/// every time, and the `vary` header will be filled with `origin`.
/// If you only have one domain, the domain will always be filled.
pub opaque type Origin {
  Wildcard
  Origin(Set(String))
}

/// CORS builder. Use it in your program to generate the good CORS for your
/// responses.
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

/// Creates an empty CORS object. It will not contains anything by default.
/// If you're using it directly, no headers will be added to the response.
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

/// Allow all domains to access your server.
///
/// Be extremely careful, you should not use this function in production!
/// Allowing all origins can easily be a huge security flaw!
/// Allow only the origins you need, and use this function only locally,
/// in dev mode.
pub fn allow_all_origins(cors: Cors) {
  let allow_origin = Some(Wildcard)
  Cors(..cors, allow_origin: allow_origin)
}

fn invalid_uri(origin: String) {
  uri.parse(origin)
  |> result.is_error()
  |> function.tap(fn(value) {
    use <- bool.guard(when: !value, return: Nil)
    io.println("Your provided origin: \"" <> origin <> "\" is not a valid URI.")
  })
}

/// Allow a specific domain to access your server. The domain must be a valid
/// URI, conformant to RFC 3986. In case it's not conformant, a warning will be
/// emitted, and Cors won't be changed.
/// You can specify multiple domains to access your server. In this case, call
/// the function multiple times on `Cors` data.
/// ```
/// fn cors() {
///   cors.new()
///   |> cors.allow_origin("domain")
///   |> cors.allow_origin("domain2")
/// }
pub fn allow_origin(cors: Cors, origin: String) {
  use <- bool.guard(when: invalid_uri(origin), return: cors)
  let allow_origin = case cors.allow_origin {
    Some(Wildcard) -> Some(Wildcard)
    Some(Origin(content)) -> Some(Origin(set.insert(content, origin)))
    None -> Some(Origin(set.from_list([origin])))
  }
  Cors(..cors, allow_origin: allow_origin)
}

/// Expose headers in the resulting request.
/// You can specify multiple headers to access your server. In this case, call
/// the function multiple times on `Cors` data.
/// ```
/// fn cors() {
///   cors.new()
///   |> cors.expose_header("content-type")
///   |> cors.expose_header("vary")
/// }
/// ```
pub fn expose_header(cors: Cors, header: String) {
  let expose_headers = set.insert(cors.expose_headers, header)
  Cors(..cors, expose_headers: expose_headers)
}

/// Set an amount of seconds during which CORS requests can be cached.
/// When using `max_age`, the browser will issue one request `OPTIONS` at first,
/// and will reuse the result of that request for the specified amount of time.
/// Once the cache expired, a new `OPTIONS` request will be made.
pub fn max_age(cors: Cors, age: Int) {
  let max_age = Some(age)
  Cors(..cors, max_age: max_age)
}

/// Allow credentials to be sent in the request. Credentials take form of
/// username and password, stored in cookies most of the time.
///
/// Be extremely careful with this header, and consider it with caution, mainly
/// for legacy systems relying on cookies or for systems aware of the danger of
/// cookies, because of [CSRF attacks](https://developer.mozilla.org/en-US/docs/Glossary/CSRF).
/// You probably don't really need it if you use lustre or any modern framework
/// you'll find in the gleam ecosystem!
///
/// When you can, prefer using some modern system, like OAuth2 or rely on a
/// framework doing the authentication for you. A simple and secured way to
/// authenticate your users is to use the `authorization` header, with a `Bearer`
/// token.
pub fn allow_credentials(cors: Cors) {
  let allow_credentials = Some(True)
  Cors(..cors, allow_credentials: allow_credentials)
}

/// Allow methods to be used in subsequent CORS requests.
/// You can specify multiple allowed methods. In this case, call the function
/// multiple times on `Cors` data.
/// ```
/// import gleam/http
///
/// fn cors() {
///   cors.new()
///   |> cors.allow_method(http.Get)
///   |> cors.allow_method(http.Post)
/// }
/// ```
pub fn allow_method(cors: Cors, method: Method) {
  let allow_methods = set.insert(cors.allow_methods, method)
  Cors(..cors, allow_methods: allow_methods)
}

/// All header to be sent to the server.
/// You can specify multiple headers to send to your server. In this case, call
/// the function multiple times on `Cors` data.
/// ```
/// fn cors() {
///   cors.new()
///   |> cors.allow_header("content-type")
///   |> cors.allow_header("origin")
/// }
/// ```
pub fn allow_header(cors: Cors, header: String) {
  let allow_headers = set.insert(cors.allow_headers, header)
  Cors(..cors, allow_headers: allow_headers)
}

// Set functions
// Used internally to simplify the CORS apply.

fn warn_if_origin_empty(origin: String) {
  case origin {
    "" ->
      io.println(
        "origin is empty, but you have multiple allowed domains in your CORS configuration. Are you sure you're calling set_cors_multiple_origin and not set_cors?",
      )
    _ -> Nil
  }
}

fn set_allowed_origin(cors: Cors, origin: String) {
  let hd = "access-control-allow-origin"
  case cors.allow_origin {
    None -> function.identity
    Some(Wildcard) -> set_header(_, hd, "*")
    Some(Origin(origins)) -> {
      let origins = set.to_list(origins)
      case origins {
        [o] -> set_header(_, hd, o)
        _ -> {
          warn_if_origin_empty(origin)
          let not_origin = !list.contains(origins, origin)
          use <- bool.guard(when: not_origin, return: function.identity)
          fn(res) {
            res
            |> set_header(hd, origin)
            |> set_header("vary", "origin")
          }
        }
      }
    }
  }
}

fn set_expose_headers(res: Response(body), cors: Cors) {
  let hd = "access-control-expose-headers"
  let ls = set.to_list(cors.expose_headers)
  use <- bool.guard(when: list.is_empty(ls), return: res)
  ls
  |> string.join(",")
  |> set_header(res, hd, _)
}

fn set_max_age(res: Response(body), cors: Cors) {
  let hd = "access-control-max-age"
  cors.max_age
  |> option.map(fn(a) { set_header(res, hd, int.to_string(a)) })
  |> option.unwrap(res)
}

fn set_allow_credentials(res: Response(body), cors: Cors) {
  let hd = "access-control-allow-credentials"
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
  let hd = "access-control-allow-methods"
  let methods = set.to_list(cors.allow_methods)
  use <- bool.guard(when: list.is_empty(methods), return: res)
  methods
  |> list.map(method_to_string)
  |> string.join(",")
  |> set_header(res, hd, _)
}

fn set_allow_headers(res: Response(body), cors: Cors) {
  let hd = "access-control-allow-headers"
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

// Request methods

/// Set CORS headers on a response. Should be used in your handler.
/// In case you're using a framework, it probably already implements it.
/// If you're using mist or wisp, use the corresponding provided middlewares,
/// ([mist_middleware](#mist_middleware)) and ([wisp_middleware](#wisp_middleware)) and do not
/// use this "low-level" function.
pub fn set_cors(res: Response(response), cors: Cors) {
  set_response(res, cors, None)
}

/// Set CORS headers on a response. Should be used when you have multiple
/// allowed domains. Should be used in your handler.
/// In case you're using a framework, it probably already implements it.
/// If you're using mist or wisp, use the corresponding provided middlewares,
/// ([mist_middleware](#mist_middleware)) and ([wisp_middleware](#wisp_middleware)) and do not
/// use this "low-level" function.
pub fn set_cors_multiple_origin(
  res: Response(response),
  cors: Cors,
  origin: String,
) {
  set_response(res, cors, Some(origin))
}

fn find_origin(req: Request(connection)) {
  req.headers
  |> list.find(fn(h) { pair.first(h) == "origin" })
  |> result.map(pair.second)
  |> option.from_result()
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
  |> option.map(set_cors_multiple_origin(res, cors, _))
  |> option.unwrap(res)
}

/// Intercepts the request for mist and handles CORS directly without worrying
/// about it. Provide your CORS configuration, and you're good to go!
pub fn mist_middleware(
  req: Request(mist.Connection),
  cors: Cors,
  handler: fn(Request(mist.Connection)) -> Response(mist.ResponseData),
) {
  bytes_tree.new()
  |> mist.Bytes()
  |> middleware(req, cors, handler)
}

/// Intercepts the request for wisp and handles CORS directly without worrying
/// about it. Provide your CORS configuration and you're good to go!
pub fn wisp_middleware(
  req: wisp.Request,
  cors: Cors,
  handler: fn(wisp.Request) -> wisp.Response,
) {
  middleware(wisp.Bytes(bytes_tree.from_string("")), req, cors, handler)
}
