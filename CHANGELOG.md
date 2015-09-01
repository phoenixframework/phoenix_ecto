# Changelog

## v1.2.0

* Enhancements
  * Depend on Ecto ~> 1.0
  * Depend on Phoenix.HTML ~> 2.2
  * Use the new `:as` option for naming inputs fields instead of `:name`

## v1.1.0

* Enhancements
  * Depend on Ecto ~> 0.15
  * Support `skip_deleted` in inputs_for
  * Support default values from model rather from `:default` option

## v1.0.0

* Enhancements
  * Depend on Phoenix.HTML ~> 2.1
  * Depend on Ecto ~> 0.15
  * Support associations on changesets

## v0.9.0

* Enhancements
  * Depend on Phoenix.HTML ~> 2.0

## v0.8.1

* Bug fix
  * Ensure we can encode decimals and floats from errors messages

## v0.8.0

* Enhancements
  * Depend on Phoenix.HTML ~> 1.4 (includes `input_type` and `input_validation` support)
  * Include embeds errors during JSON generation

## v0.7.0

* Enhancements
  * Depend on Phoenix.HTML ~> 1.3 (includes `inputs_for` support)

## v0.6.0

* Enhancements
  * Depend on Ecto ~> 0.14

## v0.5.0

* Enhancements
  * Depend on Ecto ~> 0.12

## v0.4.0

* Enhancements
  * Depend on phoenix_html as optional dependency instead of Phoenix
  * Depend on poison as optional dependency instead of Phoenix

## v0.3.2

* Bug fix
  * Ensure we interpolate `%{count}` in JSON encoding

## v0.3.1

* Enhancements
  * Implement Plug.Exception for Ecto exceptions

## v0.3.0

* Enhancements
  * Support Phoenix v0.11.0 errors entry in form data

## v0.2.0

* Enhancements
  * Implement `Phoenix.HTML.Safe` for `Ecto.Date`, `Ecto.Time` and `Ecto.DateTime`
  * Implement `Poison.Encoder` for `Ecto.Changeset`, `Decimal`, `Ecto.Date`, `Ecto.Time` and `Ecto.DateTime`

## v0.1.0

* Enhancements
  * Implement `Phoenix.HTML.FormData` for `Ecto.Changeset`
  * Implement `Phoenix.HTML.Safe` for `Decimal`
