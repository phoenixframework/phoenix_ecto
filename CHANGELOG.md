# Changelog

## v0.5.0

* Enhancements
  * Require latest Ecto (0.12.0)

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
