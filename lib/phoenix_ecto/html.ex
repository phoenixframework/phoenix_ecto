if Code.ensure_loaded?(Phoenix.HTML) do
  defimpl Phoenix.HTML.FormData, for: Ecto.Changeset do
    def to_form(%Ecto.Changeset{model: model, params: params} = changeset, opts) do
      {name, opts} = Keyword.pop(opts, :name)
      name = to_string(name || form_for_name(model))

      %Phoenix.HTML.Form{
        source: changeset,
        id: name,
        name: name,
        errors: form_for_errors(changeset.errors),
        model: model,
        params: params || %{},
        hidden: form_for_hidden(model),
        validations: changeset.validations,
        options: Keyword.put_new(opts, :method, form_for_method(model))
      }
    end

    def to_form(source, form, field, opts) do
      {default, opts} = Keyword.pop(opts, :default)
      {prepend, opts} = Keyword.pop(opts, :prepend, [])
      {append, opts} = Keyword.pop(opts, :append, [])
      {name, opts} = Keyword.pop(opts, :name)
      {id, opts} = Keyword.pop(opts, :id)

      id    = to_string(id || form.id <> "_#{field}")
      name  = to_string(name || form.name <> "[#{field}]")

      case find_inputs_for_type!(source, field) do
        {:one, cast, module} ->
          changeset =
            validate_map!(Map.get(source.changes, field), field) ||
            validate_map!(default, "default") || module.__struct__

          changeset = to_changeset(changeset, module, cast)
          model = changeset.model

          [%Phoenix.HTML.Form{
            source: changeset,
            id: id,
            name: name,
            errors: form_for_errors(changeset.errors),
            model: model,
            params: changeset.params || %{},
            hidden: form_for_hidden(model),
            validations: changeset.validations,
            options: opts
          }]

        {:many, cast, module} ->
          changesets =
            validate_list!(Map.get(source.changes, field), field) ||
            validate_list!(default, "default") || []

          changesets =
            if form.params[Atom.to_string(field)] do
              changesets
            else
              prepend ++ changesets ++ append
            end

          for {changeset, index} <- Enum.with_index(changesets) do
            changeset = to_changeset(changeset, module, cast)
            model = changeset.model
            index = Integer.to_string(index)

            %Phoenix.HTML.Form{
              source: changeset,
              id: id <> "_" <> index,
              name: name <> "[" <> index <> "]",
              errors: form_for_errors(changeset.errors),
              model: model,
              params: changeset.params || %{},
              hidden: form_for_hidden(model),
              validations: changeset.validations,
              options: opts
            }
          end
      end
    end

    defp find_inputs_for_type!(changeset, field) do
      case Map.fetch(changeset.types, field) do
        {:ok, {:embed, %{cardinality: cardinality, on_cast: cast, embed: module}}} ->
          {cardinality, cast, module}
        {:ok, type} ->
          raise ArgumentError, "cannot generate inputs_for for type #{inspect type}"
        :error ->
          raise ArgumentError, "unknown field #{inspect field}"
      end
    end

    defp to_changeset(%Ecto.Changeset{} = changeset, _module, _cast), do: changeset
    defp to_changeset(%{} = model, module, cast), do: apply(module, cast, [model, :empty])

    defp validate_list!(value, _what) when is_list(value) or is_nil(value), do: value
    defp validate_list!(value, what) do
      raise ArgumentError, "expected #{what} to be a list, got: #{inspect value}"
    end

    defp validate_map!(value, _what) when is_map(value) or is_nil(value), do: value
    defp validate_map!(value, what) do
      raise ArgumentError, "expected #{what} to be a map/struct, got: #{inspect value}"
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
    defp form_for_error({msg, count: count}) when is_binary(msg) do
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
