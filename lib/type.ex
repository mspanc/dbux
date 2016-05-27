defmodule DBux.Type do
  require Logger

  @doc """
  Returns bitstring that contains 1-byte D-Bus signature of given type.

  Reverse function is `type/1`.
  """
  @spec signature(:byte | :boolean | :int16 | :uint16 | :int32 | :uint32 | :int64 | :uint64 | :double | :string | :object_path | :signature | :array | :struct | :variant | :dict_entry | :unix_fd) :: Bitstring
  def signature(:byte),        do: << "y" >>
  def signature(:boolean),     do: << "b" >>
  def signature(:int16),       do: << "n" >>
  def signature(:uint16),      do: << "q" >>
  def signature(:int32),       do: << "i" >>
  def signature(:uint32),      do: << "u" >>
  def signature(:int64),       do: << "x" >>
  def signature(:uint64),      do: << "t" >>
  def signature(:double),      do: << "d" >>
  def signature(:string),      do: << "s" >>
  def signature(:object_path), do: << "o" >>
  def signature(:signature),   do: << "g" >>
  def signature(:unix_fd),     do: << "h" >>
  # TODO parse compound types


  @doc """
  Returns atom that contains atom identifying type.

  Reverse function is `signature/1`.
  """
  def type(<< "y" >>), do: :byte
  def type(<< "b" >>), do: :boolean
  def type(<< "n" >>), do: :int16
  def type(<< "q" >>), do: :uint16
  def type(<< "i" >>), do: :int32
  def type(<< "u" >>), do: :uint32
  def type(<< "x" >>), do: :int64
  def type(<< "t" >>), do: :uint64
  def type(<< "d" >>), do: :double
  def type(<< "s" >>), do: :string
  def type(<< "o" >>), do: :object_path
  def type(<< "g" >>), do: :signature
  def type(<< "h" >>), do: :unix_fd


  def type_from_signature(signature) when is_binary(signature) do
    parse(signature, [])
  end


  defp parse(<< >>, acc) do
    acc
  end


  defp parse(<< "(", rest :: binary >>, acc) do
    case parse_struct(rest, []) do
      {:ok, value_parsed, rest_after_parse} ->
        parse(rest_after_parse, acc ++ [value_parsed])

      {:error, reason} ->
        {:error, reason}
    end
  end


  defp parse(<< ")", rest :: binary >>, acc) do
    {:error, {:badsignature, :unmatchedstruct}}
  end


  defp parse(<< head :: binary-size(1), rest :: binary >>, acc) do
    parse(rest, acc ++ [type(head)])
  end


  defp parse_struct(<< "(", rest :: binary >>, acc) do
    case parse_struct(rest, []) do
      {:ok, value_parsed, rest_after_parse} ->
        parse_struct(rest_after_parse, acc ++ [value_parsed])

      {:error, reason} ->
        {:error, reason}
    end
  end


  defp parse_struct(<< ")", rest :: binary >>, []) do
    {:error, {:badsignature, :emptystruct}}
  end


  defp parse_struct(<< ")", rest :: binary >>, acc) do
    {:ok, {:struct, acc}, rest}
  end


  defp parse_struct(<< >>, acc) do
    {:error, {:badsignature, :unmatchedstruct}}
  end


  defp parse_struct(<< head :: binary-size(1), rest :: binary >>, acc) do
    parse_struct(rest, acc ++ [type(head)])
  end
end
