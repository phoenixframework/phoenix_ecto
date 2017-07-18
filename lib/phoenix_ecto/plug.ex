errors = [
  {Ecto.CastError, 400},
  {Ecto.Query.CastError, 400},
  {Ecto.NoResultsError, 404},
  {Ecto.InvalidChangesetError, 422},
]

excluded_exceptions = Application.get_env(:phoenix_ecto, :exclude_ecto_exceptions_from_plug, [])

for {exception, status_code} <- errors do
  unless exception in excluded_exceptions do
    defimpl Plug.Exception, for: exception do
      def status(_), do: unquote(status_code)
    end
  end
end
