if Code.ensure_loaded?(Phoenix.HTML) do
  defimpl Phoenix.HTML.FormData, for: Ecto.Changeset do
    def to_form(%Ecto.Changeset{model: model, params: params} = changeset, opts) do
      {name, opts} = Keyword.pop(opts, :name)
      name = to_string(name || form_for_name(model))

      %Phoenix.HTML.Form{
        source: changeset,
        impl: __MODULE__,
        id: name,
        name: name,
        errors: form_for_errors(changeset.errors),
        model: model,
        params: params || %{},
        hidden: form_for_hidden(model),
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
            impl: __MODULE__,
            id: id,
            name: name,
            errors: form_for_errors(changeset.errors),
            model: model,
            params: changeset.params || %{},
            hidden: form_for_hidden(model),
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
              impl: __MODULE__,
              id: id <> "_" <> index,
              name: name <> "[" <> index <> "]",
              errors: form_for_errors(changeset.errors),
              model: model,
              params: changeset.params || %{},
              hidden: form_for_hidden(model),
              options: opts
            }
          end
      end
    end

    def input_type(changeset, field) do
      type = Map.get(changeset.types, field, :string)
      type = if Ecto.Type.primitive?(type), do: type, else: type.type

      case type do
        :integer  -> :number_input
        :float    -> :number_input
        :decimal  -> :number_input
        :boolean  -> :checkbox
        :date     -> :date_select
        :time     -> :time_select
        :datetime -> :datetime_select
        _         -> :text_input
      end
    end

    def input_validations(changeset, field) do
      [required: field in changeset.required] ++
        for({key, validation} <- changeset.validations,
            key == field,
            attr <- validation_to_attrs(validation, field, changeset),
            do: attr)
    end

    defp validation_to_attrs({:length, opts}, _field, _changeset) do
      max =
        if val = Keyword.get(opts, :max) do
          [maxlength: val]
        else
          []
        end

      min =
        if val = Keyword.get(opts, :min) do
          [minlength: val]
        else
          []
        end

      max ++ min
    end

    defp validation_to_attrs({:number, opts}, field, changeset) do
      type = Map.get(changeset.types, field, :integer)
      step_for(type) ++ min_for(type, opts) ++ max_for(type, opts)
    end

    defp validation_to_attrs(_validation, _field, _changeset) do
      []
    end

    defp step_for(:integer), do: [step: 1]
    defp step_for(_other),   do: [step: "any"]

    defp max_for(type, opts) do
      cond do
        (type == :integer) && (max = Keyword.get(opts, :less_than)) ->
          [max: max - 1]
        max = Keyword.get(opts, :less_than_or_equal_to) ->
          [max: max]
        true ->
          []
      end
    end

    defp min_for(type, opts) do
      cond do
        (type == :integer) && (min = Keyword.get(opts, :greater_than)) ->
          [min: min + 1]
        min = Keyword.get(opts, :greater_than_or_equal_to) ->
          [min: min]
        true ->
          []
      end
    end

    defp find_inputs_for_type!(changeset, field) do
      case Map.fetch(changeset.types, field) do
        {:ok, {:embed, %{cardinality: cardinality, on_cast: cast, embed: module}}} ->
          {cardinality, cast, module}
        {:ok, type} ->
          raise ArgumentError,
            "cannot generate inputs_for for field #{inspect field} with type #{inspect type}"
        :error ->
          raise ArgumentError,
            "unknown inputs for #{inspect field}. Only fields and embeds are supported in inputs_for/4."
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
      String.replace(msg, "%{count}", to_string(count))
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
