defmodule DBux.WireProtocol do
  def marshall(signature, values, endianness) when is_binary(signature) and is_list(values) do
    signature_tokens = signature |> String.split("", trim: true)

    marshall_step(<<>>, signature_tokens, values, endianness)
  end


  defp marshall_step(acc, [signature_token|signature_token_rest], [value|values_rest], endianness) do
    marshalled_value = case signature_token do
      "y" -> DBux.Value.marshall(%DBux.Value{type: :byte, value: value}, endianness)
      "b" -> DBux.Value.marshall(%DBux.Value{type: :boolean, value: value}, endianness)
      "n" -> DBux.Value.marshall(%DBux.Value{type: :int16, value: value}, endianness)
      "q" -> DBux.Value.marshall(%DBux.Value{type: :uint16, value: value}, endianness)
      "i" -> DBux.Value.marshall(%DBux.Value{type: :int32, value: value}, endianness)
      "u" -> DBux.Value.marshall(%DBux.Value{type: :uint32, value: value}, endianness)
      "x" -> DBux.Value.marshall(%DBux.Value{type: :int64, value: value}, endianness)
      "t" -> DBux.Value.marshall(%DBux.Value{type: :uint64, value: value}, endianness)
      "d" -> DBux.Value.marshall(%DBux.Value{type: :double, value: value}, endianness)
      "s" -> DBux.Value.marshall(%DBux.Value{type: :string, value: value}, endianness)
      "o" -> DBux.Value.marshall(%DBux.Value{type: :object_path, value: value}, endianness)
      "g" -> DBux.Value.marshall(%DBux.Value{type: :signature, value: value}, endianness)
      "h" -> DBux.Value.marshall(%DBux.Value{type: :unix_fd, value: value}, endianness)
    end

    marshall_step(acc <> marshalled_value, signature_token_rest, values_rest, endianness)
  end


  defp marshall_step(acc, [], [value|values_rest], _) do
    {:error, :signature_too_short}
  end


  defp marshall_step(acc, [signature_token|signature_token_rest], [], _) do
    {:error, :value_list_too_short}
  end


  defp marshall_step(acc, [], [], _) do
    acc
  end
end
