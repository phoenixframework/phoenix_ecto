if Code.ensure_loaded?(Phoenix.HTML) do
  defimpl Phoenix.HTML.FormData, for: Ecto.Changeset do
    def to_form(%Ecto.Changeset{model: model, params: params} = changeset, opts) do
      {name, opts} = Keyword.pop(opts, :name)

      %Phoenix.HTML.Form{
        source: changeset,
        name: to_string(name || form_for_name(model)),
        model: model,
        params: params || %{},
        options: Keyword.put_new(opts, :method, form_for_method(model))
      }
    end

    defp form_for_name(%{__struct__: module}),
      do: Phoenix.Naming.resource_name(module)

    defp form_for_method(%{__state__: :loaded}), do: "put"
    defp form_for_method(_), do: "post"
  end

  defimpl Phoenix.HTML.Safe, for: [Decimal, Ecto.Time, Ecto.Date, Ecto.DateTime] do
    def to_iodata(t) do
      @for.to_string(t)
    end
  end
end
