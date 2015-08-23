A project that integrates [Phoenix](http://github.com/phoenixframework/phoenix) with [Ecto](http://github.com/elixir-lang/ecto), implementing all relevant protocols.

## Usage

You can use `phoenix_ecto` in your projects in two steps:

1. Add it to your `mix.exs` dependencies:

    ```elixir
    def deps do
      [{:phoenix_ecto, "~> 1.1"}]
    end
    ```

2. List it as your application dependency:

    ```elixir
    def application do
      [applications: [:logger, :phoenix_ecto]]
    end
    ```

## Details

This project:

  * Implements the `Phoenix.HTML.FormData` protocol for `Ecto.Changeset`
  * Implements the `Phoenix.HTML.Safe` protocol for `Decimal`, `Ecto.Date`, `Ecto.Time` and `Ecto.DateTime`
  * Implements the `Poison.Encoder` protocol for `Ecto.Changeset` (it renders its errors as JSON), `Decimal`, `Ecto.Date`, `Ecto.Time` and `Ecto.DateTime`
  * Implements the `Plug.Exception` protocol for the relevant Ecto exceptions

## License

Same license as Phoenix.
