A project that integrates [Phoenix](http://github.com/phoenixframework/phoenix) with [Ecto](http://github.com/elixir-lang/ecto), implementing all relevant protocols.

## Usage

You can use `phoenix_ecto` in your projects in two steps:

1. Add it to your `mix.exs` dependencies:

    ```elixir
    def deps do
      [{:phoenix_ecto, "~> 2.0"}]
    end
    ```

2. List it as your application dependency:

    ```elixir
    def application do
      [applications: [:logger, :phoenix_ecto]]
    end
    ```

## The Phoenix <-> Ecto integration

Thanks to Elixir protocols, the integration between Phoenix and Ecto is simply a matter of implementing a handful of protocols. We provide the following implementations:

  * `Phoenix.HTML.FormData` protocol for `Ecto.Changeset`
  * `Phoenix.HTML.Safe` protocol for `Decimal`, `Ecto.Date`, `Ecto.Time` and `Ecto.DateTime`
  * `Plug.Exception` protocol for the relevant Ecto exceptions
  * `Poison.Encoder` protocol for `Decimal`, `Ecto.Date`, `Ecto.Time` and `Ecto.DateTime`

## Concurrent acceptance tests

This library also provides a plug called `Phoenix.Ecto.SQL.Sandbox` that allows developers to run acceptance tests concurrently. If you are not familiar with Ecto's SQL sandbox, we recommend you to first get acquainted with it by [reading `Ecto.Adapters.SQL.Sandbox` documentation](https://hexdocs.pm/ecto/Ecto.Adapters.SQL.Sandbox.html).

In the examples below, we will list the instructions of running concurrent acceptance tests with Hound but it would apply to any tool.

  1. First [add Hound as a dependency to your project as outlined in its README](https://github.com/HashNuke/hound)

  2. Then set a flag to enable the sandbox in `config/test.exs`:

    ```elixir
    config :your_app, sql_sandbox: true
    ```

  3. And use the flag to conditionally add the plug to `lib/your_app/endpoint.ex`:

    ```elixir
    if Application.get_env(:your_app, :sql_sandbox) do
      plug Phoenix.Ecto.SQL.Sandbox
    end
    ```

  4. Then, within an acceptance test, checkout a sandboxed connection as usual and
    start your test driver using the metadata provided by `Phoenix.Ecto.SQL.Sandbox.metadata_for`.
  
    ```elixir
    use Hound.Helpers

    setup do
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(YourApp.Repo)
      Hound.start_session(metadata: Phoenix.Ecto.SQL.Sandbox.metadata_for(YourApp.Repo, self()))
    end
    ```

Keep in mind `phantomjs` shares cookies between sessions, which could therefore results in
race conditions or bugs when running tests concurrently.

## License

Same license as Phoenix.
