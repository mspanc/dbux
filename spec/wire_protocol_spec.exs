defmodule DBux.WireProtocolSpec do
  use ESpec

  context ".marshall/2" do
    let :result, do: DBux.WireProtocol.marshall(signature, values, endianness)

    context "if passed valid signature and accompanying value list" do
      context "and endianness is little endian" do
        let :endianness, do: :little_endian

        context "and it contains only basic types" do
          let :signature,         do: "ybnqiuxtdsogh"
          let :byte_value,        do: 100
          let :boolean_value,     do: true
          let :int16_value,       do: -0xAB
          let :uint16_value,      do: 0xAB
          let :int32_value,       do: -0xABCD
          let :uint32_value,      do: 0xABCD
          let :int64_value,       do: -0xABCDABCD
          let :uint64_value,      do: 0xABCDABCD
          let :double_value,      do: 0.12345
          let :string_value,      do: "qwertyąść"
          let :object_path_value, do: "/object/path"
          let :signature_value,   do: "ybnqiuxtdsogh(ss)"
          let :unix_fd_value,     do: 33
          let :values, do: [byte_value, boolean_value, int16_value, uint16_value, int32_value, uint32_value, int64_value, uint64_value, double_value, string_value, object_path_value, signature_value, unix_fd_value]

          it "should return {:ok, bitstring}" do
            {:ok, marshalled_value} = result
            expect(marshalled_value).to be_bitstring
          end

          it "should return {:ok, bitstring containing concatenated representation of all passed values}" do
            expect(result).to eq({:ok,
              DBux.Value.marshall(%DBux.Value{type: :byte,value:  byte_value}, endianness) <>
              DBux.Value.marshall(%DBux.Value{type: :boolean, value: boolean_value}, endianness) <>
              DBux.Value.marshall(%DBux.Value{type: :int16, value: int16_value}, endianness) <>
              DBux.Value.marshall(%DBux.Value{type: :uint16, value: uint16_value}, endianness) <>
              DBux.Value.marshall(%DBux.Value{type: :int32, value: int32_value}, endianness) <>
              DBux.Value.marshall(%DBux.Value{type: :uint32, value: uint32_value}, endianness) <>
              DBux.Value.marshall(%DBux.Value{type: :int64, value: int64_value}, endianness) <>
              DBux.Value.marshall(%DBux.Value{type: :uint64, value: uint64_value}, endianness) <>
              DBux.Value.marshall(%DBux.Value{type: :double, value: double_value}, endianness) <>
              DBux.Value.marshall(%DBux.Value{type: :string, value: string_value}, endianness) <>
              DBux.Value.marshall(%DBux.Value{type: :object_path, value: object_path_value}, endianness) <>
              DBux.Value.marshall(%DBux.Value{type: :signature, value: signature_value}, endianness) <>
              DBux.Value.marshall(%DBux.Value{type: :unix_fd, value: unix_fd_value}, endianness)
            })
          end
        end
      end
    end
  end
end
