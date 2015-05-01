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
        hidden: form_for_hidden(model),
        options: Keyword.put_new(opts, :method, form_for_method(model))
      }
    end

    defp form_for_hidden(model) do
      # Since they are primary keys, we should ignore nil values.
      for {k, v} <- Ecto.Model.primary_key(model), v != nil, do: {k, v}
    end

    defp form_for_name(%{__struct__: module}) do
      module
      |> Module.split()
      |> List.last()
      |> underscore()
    end

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

    defp underscore(<<>>), do: ""

    defp underscore(<<h, t :: binary>>) do
      <<to_lower_char(h)>> <> do_underscore(t, h)
    end

    defp do_underscore(<<h, t, rest :: binary>>, _) when h in ?A..?Z and not t in ?A..?Z do
      <<?_, to_lower_char(h), t>> <> do_underscore(rest, t)
    end

    defp do_underscore(<<h, t :: binary>>, prev) when h in ?A..?Z and not prev in ?A..?Z do
      <<?_, to_lower_char(h)>> <> do_underscore(t, h)
    end

    defp do_underscore(<<h, t :: binary>>, _) do
      <<to_lower_char(h)>> <> do_underscore(t, h)
    end

    defp do_underscore(<<>>, _) do
      <<>>
    end

    defp to_lower_char(char) when char in ?A..?Z, do: char + 32
    defp to_lower_char(char), do: char
  end

  defimpl Phoenix.HTML.Safe, for: [Decimal, Ecto.Time, Ecto.Date, Ecto.DateTime] do
    def to_iodata(t) do
      @for.to_string(t)
    end
  end
end
