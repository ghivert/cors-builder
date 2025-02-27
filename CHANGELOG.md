## v2.0.4 - 2025-02-27

- Patch update, no changes public API, no changes expected in your codebase.
- Update and relax gleam_http requirement to < 5.0.0

## v2.0.3 - 2024-12-20

- Patch update, no changes public API, no changes expected in your codebase.
- Update [`mist`](https://hex.pm/packages/mist) dependency to >= 4.0.0. \
  [`mist`](https://hex.pm/packages/mist) regularly updates accordingly with the standard
  library.
- Update stdlib dependency to >= 0.42.0. \
  Because the standard library is still subject to breaking changes, some new versions
  update can still occur in the library. Below version 0.42.0, please, stay on version
  2.0.2, which is still working great (but miss `bytes_tree` and `string_tree`).

## v2.0.2 - 2024-10-14

- Patch update, no changes public API, no changes expected in your codebase.
- Update [`mist`](https://hex.pm/packages/mist) dependency to >= 3.0.0. \

## v2.0.1 - 2024-09-17

- Patch update, no changes public API, no changes expected in your codebase.
- Update [`mist`](https://hex.pm/packages/mist) dependency to >= 2.0.0.

## v2.0.0 - 2024-08-26

- Major update because [`mist`](https://hex.pm/packages/mist) has officially
  been bumped. No changes in public API, no changes expected in your codebase.
- Update [`mist`](https://hex.pm/packages/mist) dependency to >= 1.0.0.
- Fix `max_age` documentation (milliseconds -> seconds).

## v1.0.0 - 2024-05-14

- Major update, breaking change! Expect incompatibilities in your codebase.
- First stable release of CORS Builder!
- Rename `wisp_handle` to `wisp_middleware`.
- Rename `mist_handle` to `mist_middleware`.

## v0.1.0 - 2024-04-24

- First release of CORS Builder!
