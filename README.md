# Simple CORS

## Middlewares

```gleam
import gleam/http
import mist
import simple_cors as cors
import wisp.{type Request, type Response}

fn cors() {
  cors.new()
  |> cors.allow_origin("http://localhost:3000")
  |> cors.allow_origin("http://localhost:4000")
  |> cors.allow_method(http.Get)
  |> cors.allow_method(http.Post)
}

fn handler(req: Request) -> Response {
  use req <- cors.wisp_handle(req, cors())
  wisp.ok()
}

fn main() {
  handler
  |> wisp.mist_handler(secret_key)
  |> mist.new()
  |> mist.port(3000)
  |> mist.start_http()
}
```

## What is CORS?

Browsers apply a simple rules for every HTTP request: when the request
originates from a different origin than the target server URL — and if it's not
a simple request — the browser needs to authorize the cross-origin call.

> From the HTTP point of view, a simple request respects the following
> conditions:
>
> - Allowed methods are `GET`, `HEAD` or `POST`
> - Allowed headers are `Accept`, `Accept-Language`, `Content-Language` and
>   `Content-Type`
> - `Content-Type` should be:
>   - `application/x-www-form-urlencoded`
>   - `multipart/form-data`
>   - `text/plain`
> - No event listener has been added on `XMLHttpRequestUpload`.
>   `XMLHttpRequestUpload.upload` is preferred.
> - No `ReadableStream` is used in the request.

To authorize the call, the browser will issue a first request, called a
"preflight" request. This request takes the form of an `OPTIONS` request, which
should be answered positively by the server (meaning the response status code
should be 2XX) and should contains the appropriate CORS headers
(`Access-Control` headers).

In case the preflight request is not successful, the server will simply cancel
the HTTP request. But if the preflight request is successful, then the browser
will then launch the real request, and the server will be able to handle it.

## What are the headers?

We distinguish different types of headers: the headers concerning the request
issuer (the caller) and the headers responded by the server.

### Response headers

Response headers are not automatically set by the server, and you should handle
them according on what you want to do. This package tries to abstract it to
simplify your development and let you focus on your application. We count 6 CORS
response headers:

- `Access-Control-Allow-Origin`, indicates which origins are allowed to access
  the server. It can be a joker (`"*"`) or a unique domain
  (`https://gleam.run`). It cannot contains multiple domains, but can response
  to multiple different domains with the `VARY` header. You should not have to
  take care of this, because the library provides it for you.
- `Access-Control-Expose-Headers`, provides a whitelist of allowed headers for
  the browsers. Only the headers in the whitelist will be able to be used in the
  response object in the JS code. It means if the response contains headers you
  want to cache to the client, you can use this header.
- `Access-Control-Max-Age`, allows to put the preflight response in cache, for a
  specified amount of time. This avoids to rerun the `OPTIONS` request multiple
  times.
- `Access-Control-Allow-Credentials`, allows the request to includes credentials
  authorizations. This can expose you to CSRF attack. Never activate this option
  unless you carefully know what you're doing.
- `Access-Control-Allow-Methods`, provides a whitelist of subsequent authorized
  methods in the future requests.
- `Access-Control-Allow-Headers`, indicates which headers are accepted by the
  server, and thus, which headers the browser will be able to send in subsequent
  requests.

### Request headers

Request headers are headers automatically set by the browser, when issuing a
request with `XMLHttpRequest` or `fetch`. You should not bother about it, but
they're still referenced it, in case you encounter them.We count 3 CORS request
headers:

- `Origin` contains the origin of the request. The browser will _always_ fill
  this header automatically.
- `Access-Control-Request-Method` contains the desired methods to use when
  talking with the server.
- `Access-Control-Request-Header` contains the desired headers that the request
  want to have.
