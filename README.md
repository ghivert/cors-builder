# CORS Builder

> [!IMPORTANT]
>
> Before diving in CORS,
> [make sure you're aware of security advices](#more-details--notes-about-security)
> and see if you can't just use a simple proxy to avoid CORS! It's a better and
> more secure way to manage CORS! Always secure correctly your CORS, and use
> them sparingly, when needed.

Manipulating CORS is often a pain for developers, and always a little blurry, to
understand what should be done, how it should be configured, etc. CORS Builder
abstract the complexity while trying to remains simple, and friendly warns you
when something is wrong.

CORS Builder is compatible with every servers, as long as you're using the
[`gleam_http`](https://hexdocs.pm/gleam_http) `Response` as a foundation.
However, to simplify your development, two middlewares are provided
out-of-the-box:
[`wisp_middleware`](https://hexdocs.pm/cors_builder/cors_builder.html#wisp_middleware)
and
[`mist_middleware`](https://hexdocs.pm/cors_builder/cors_builder.html#mist_middleware)
to integrate nicely in [`wisp`](https://hexdocs.pm/wisp) and
[`mist`](https://hexdocs.pm/mist). You should never have to worry about CORS
again! Use the package, configure your CORS, and everything should work
smoothly!

## Quickstart

You can interchange `wisp_middleware` with `mist_middleware` if you're using
`wisp` or `mist`.

```gleam
import cors_builder as cors
import gleam/http
import mist
import wisp.{type Request, type Response}

fn cors() {
  cors.new()
  |> cors.allow_origin("http://localhost:3000")
  |> cors.allow_origin("http://localhost:4000")
  |> cors.allow_method(http.Get)
  |> cors.allow_method(http.Post)
}

fn handler(req: Request) -> Response {
  use req <- cors.wisp_middleware(req, cors())
  wisp.ok()
}

fn main() {
  handler
  |> wisp.mist_middlewarer(secret_key)
  |> mist.new()
  |> mist.port(3000)
  |> mist.start_http()
}
```

## More details & notes about security

CORS are often badly understood, however they're full parts of the web stack
when working with browsers, and they're part of security measures, to avoid
users' browsers behaving badly.

CORS intervene when browsers have to manage with cross-origin requests. A
cross-origin request is a request coming from a different domain than the domain
you're currently on. Imagine you're browsing your favorite website, like
[packages.gleam.run](https://packages.gleam.run), and suddenlly, your browser
want to query [google.com](https://google.com) in an async way. Because you're
not on Google, the browser will identify your request as a cross-origin request.
Some more security measures have to be taken to make sure the request is valid.
That's where CORS comes into play. CORS stands for Cross-Origin Resource
Sharing. It means it's a way to authorize cross-origin requests, to allow
outside clients to access the desired resources.

This mechanism is a way to prevent browsers to ask for data on behalf of a user,
in an undesired way. It's up to you, when developping your server, to make sure
only authentified, regular users can access your service. **It is a bad idea to
let everyone access your data directly from a browser.** You should identify who
can access your service, and how, that's what CORS are made for. Most of the
time, you want your frontend to access your backend, and nothing else. You can
simply identify those domains, and add them in your CORS configuration. Let's
imagine your frontend is hosted on `https://frontend.app` and your backend on
`https://backend.app`. You can configure your CORS to _only_ accept
`https://frontend.app`. That way, every request coming from another domain will
be rejected, and only your users will be accepted.

Keep in mind that CORS will never trigger as long as your frontend query the
same domain where it resides. When your frontend queries
`https://frontend.app/api/path` for example, because your frontend resides on
`https://frontend.app`, no cross-origin request is identified, so CORS won't
comes into play. So always think about this, and see if you can just host your
frontend at the same address as your backend. This can be achieved using a
proxy, and this should be soon available in lustre dev tools, and is already
available if you're using
[Vite](https://vitejs.dev/config/server-options#server-proxy) or
[Webpack](https://webpack.js.org/configuration/dev-server/#devserverproxy)!

## How are CORS working?

Browsers apply a simple rules for every HTTP request: when the request
originates from a different origin than the target server URL — and if it's not
a simple request — the browser needs to authorize the cross-origin call.

> From the HTTP point of view, a simple request respects the following
> conditions:
>
> - Allowed methods are `GET`, `HEAD` or `POST`
> - Allowed headers are `accept`, `accept-language`, `content-language` and
>   `content-type`
> - `content-type` should be:
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
(`access-control` headers).

In case the preflight request is not successful, the server will simply cancel
the HTTP request. But if the preflight request is successful, then the browser
will then launch the real request, and the server will be able to handle it.

## What are the headers?

We distinguish different types of headers: the headers concerning the request
issuer (the caller) and the headers responded by the server.

> [!NOTE]
>
> In HTTP, all headers keys are case-insensitive. It means all headers can be
> written as `content-type` or `Content-Type` or even `CONTENT-type`. By
> convention, they're written as `Content-Type`. In HTTP2 though, all headers
> keys have to be lowercase or the requests are rejected, and `gleam_http` will
> enforce this behaviour. All headers keys in this guide will be written in
> lowercase. On the internet you could still see both way of writing them.

### Response headers

Response headers are not automatically set by the server, and you should handle
them according on what you want to do. This package tries to abstract it to
simplify your development and let you focus on your application. We count 6 CORS
response headers:

- `access-control-allow-origin`, indicates which origins are allowed to access
  the server. It can be a joker (`"*"`) or a unique domain
  (`https://gleam.run`). It cannot contains multiple domains, but can response
  to multiple different domains with the `vary` header. You should not have to
  take care of this, because the library provides it for you.
- `access-control-expose-headers`, provides a whitelist of allowed headers for
  the browsers. Only the headers in the whitelist will be able to be used in the
  response object in the JS code. It means if the response contains headers you
  want to cache to the client, you can use this header.
- `access-control-max-age`, allows to put the preflight response in cache, for a
  specified amount of time. This avoids to rerun the `OPTIONS` request multiple
  times.
- `access-control-allow-credentials`, allows the request to includes credentials
  authorizations. This can expose you to CSRF attack. Never activate this option
  unless you carefully know what you're doing.
- `access-control-allow-methods`, provides a whitelist of subsequent authorized
  methods in the future requests.
- `access-control-allow-headers`, indicates which headers are accepted by the
  server, and thus, which headers the browser will be able to send in subsequent
  requests.

### Request headers

Request headers are headers automatically set by the browser, when issuing a
request with `XMLHttpRequest` or `fetch`. You should not bother about it, but
they're still referenced it, in case you encounter them.We count 3 CORS request
headers:

- `origin` contains the origin of the request. The browser will _always_ fill
  this header automatically.
- `access-control-request-method` contains the desired methods to use when
  talking with the server.
- `access-control-request-header` contains the desired headers that the request
  want to have.

## Contributing

You love the package and want to improve it? You have a shiny new framework and
want to provide an integration with CORS in this package? Every contribution is
welcome! Feel free to open a Pull Request, and let's discuss about it!
