if Code.ensure_loaded?(Phoenix.HTML) do
  defimpl Phoenix.HTML.FormData, for: Ecto.Changeset do
    def to_form(%Ecto.Changeset{model: model, params: params} = changeset, opts) do
      {name, opts} = Keyword.pop(opts, :name)

      %Phoenix.HTML.Form{
        source: changeset,
        name: to_string(name || form_for_name(model)),
        model: model,
        hidden: form_for_hidden(model),
        params: params || %{},
        options: Keyword.put_new(opts, :method, form_for_method(model))
      }
    end

    defp form_for_name(%{__struct__: module}),
      do: Phoenix.Naming.resource_name(module)

    defp form_for_method(%{__state__: :loaded}), do: "put"
    defp form_for_method(_), do: "post"

    defp form_for_hidden(%{__state__: :loaded} = model) do
      if pk = Ecto.Model.primary_key(model) do
        [{model.__struct__.__schema__(:primary_key), pk}]
      else
        []
      end
    end
    defp form_for_hidden(_), do: []
  end

  defimpl Phoenix.HTML.Safe, for: Decimal do
    def to_iodata(dec) do
      Decimal.to_string(dec)
    end
  end

  defimpl Phoenix.HTML.Safe, for: Ecto.Time do
    def to_iodata(t) do
      "#{t}" 
    end
  end
end
