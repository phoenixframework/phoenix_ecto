if Code.ensure_loaded?(Poison) do
  defimpl Poison.Encoder, for: Ecto.Changeset do
    def encode(%{errors: errors}, opts) do
      errors
      |> Enum.reverse()
      |> merge_error_keys()
      |> Poison.Encoder.encode(opts)
    end

    defp merge_error_keys(errors) do
      Enum.reduce(errors, %{}, fn({k, v}, acc ) ->
        v = json_error(v)
        Map.update(acc, k, [v], &[v|&1])
      end)
    end

    defp json_error(msg) when is_binary(msg), do: msg
    defp json_error({msg, count: count}) when is_binary(msg) do
      String.replace(msg, "%{count}", Integer.to_string(count))
    end
  end

  defimpl Poison.Encoder, for: Ecto.Association.NotLoaded do
    def encode(%{__owner__: owner, __field__: field}, _) do
      raise "cannot encode association #{inspect field} from #{inspect owner} to " <>
            "JSON because the association was not loaded. Please make sure you have " <>
            "preloaded the association or remove it from the data to be encoded"
    end
  end
end
