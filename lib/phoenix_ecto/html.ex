if Code.ensure_loaded?(Phoenix.HTML) do
  defimpl Phoenix.HTML.FormData, for: Ecto.Changeset do
    def to_form(%Ecto.Changeset{model: model, params: params} = changeset, opts) do
      {name, opts} = Keyword.pop(opts, :name)

      %Phoenix.HTML.Form{
        source: changeset,
        name: to_string(name || form_for_name(model)),
        errors: form_for_errors(changeset.errors),
        model: model,
        params: params || %{},
        options: Keyword.put_new(opts, :method, form_for_method(model))
      }
    end

    defp form_for_name(%{__struct__: module}),
      do: Phoenix.Naming.resource_name(module)

    defp form_for_method(%{__meta__: %{state: :loaded}}), do: "put"
    defp form_for_method(_), do: "post"

    defp form_for_errors(errors) do
      for {attr, message} <- errors do
        {attr, form_for_error(message)}
      end
    end

    defp form_for_error(msg) when is_binary(msg), do: msg
    defp form_for_error({msg, count}) when is_binary(msg) do
      String.replace(msg, "%{count}", Integer.to_string(count))
    end
  end

  defimpl Phoenix.HTML.Safe, for: [Decimal, Ecto.Time, Ecto.Date, Ecto.DateTime] do
    def to_iodata(t) do
      @for.to_string(t)
    end
  end
end
