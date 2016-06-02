defmodule DBux.ProtocolSpec do
  use ESpec

  describe ".unmarshall_bitstring/4" do
    context "for sample little-endian bitstring that is supposed to contain message header" do
      let :signature, do: "yyyyuua(yv)"
      let :endianness, do: :little_endian

      context "if bitstring is empty" do
        let :bitstring, do: << >>

        context "if it is set to return plain values" do
          let :unwrap_values, do: true

          it "should return error result" do
            expect(described_module.unmarshall_bitstring(bitstring, endianness, signature, unwrap_values)).to be_error_result
          end

          it "should return :bitstring_too_short as a reason" do
            {:error, reason} = described_module.unmarshall_bitstring(bitstring, endianness, signature, unwrap_values)
            expect(reason).to eq :bitstring_too_short
          end
        end

        context "if it is set to return wrapped values" do
          let :unwrap_values, do: false

          it "should return error result" do
            expect(described_module.unmarshall_bitstring(bitstring, endianness, signature, unwrap_values)).to be_error_result
          end

          it "should return :bitstring_too_short as a reason" do
            {:error, reason} = described_module.unmarshall_bitstring(bitstring, endianness, signature, unwrap_values)
            expect(reason).to eq :bitstring_too_short
          end
        end
      end


      context "for list of simple types that need to be aligned" do
        let :bitstring, do: <<5, 0, 0, 0, 97, 98, 99, 100, 101, 0, 0, 0, 210, 4, 0, 0>>
        let :signature, do: "si"

        context "if it is set to return plain values" do
          let :unwrap_values, do: true

          it "should return an ok result" do
            expect(described_module.unmarshall_bitstring(bitstring, endianness, signature, unwrap_values)).to be_ok_result
          end

          it "should return a valid list of values" do
            {:ok, {values, _rest}} = described_module.unmarshall_bitstring(bitstring, endianness, signature, unwrap_values)
            expect(values).to eq ["abcde", 1234]
          end

          it "should return an empty rest" do
            {:ok, {_values, rest}} = described_module.unmarshall_bitstring(bitstring, endianness, signature, unwrap_values)
            expect(rest).to eq << >>
          end
        end

        context "if it is set to return wrapped values" do
          let :unwrap_values, do: false

          it "should return an ok result" do
            expect(described_module.unmarshall_bitstring(bitstring, endianness, signature, unwrap_values)).to be_ok_result
          end

          it "should return a valid list of values" do
            {:ok, {values, _rest}} = described_module.unmarshall_bitstring(bitstring, endianness, signature, unwrap_values)
            expect(values).to eq [%DBux.Value{type: :string, value: "abcde"}, %DBux.Value{type: :int32, value: 1234}]
          end

          it "should return an empty rest" do
            {:ok, {_values, rest}} = described_module.unmarshall_bitstring(bitstring, endianness, signature, unwrap_values)
            expect(rest).to eq << >>
          end
        end
      end


      context "if bitstring contains not enough data for values that match signature" do
        let :bitstring, do: << 0x6c, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x6d, 0x00, 0x00, 0x00, 0x01, 0x01, 0x6f, 0x00, 0x15, 0x00, 0x00, 0x00, 0x2f, 0x6f, 0x72, 0x67, 0x2f, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2f, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00, 0x03, 0x01, 0x73, 0x00, 0x05, 0x00, 0x00, 0x00, 0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x00, 0x00, 0x00, 0x02, 0x01, 0x73, 0x00, 0x14, 0x00, 0x00, 0x00, 0x6f, 0x72, 0x67, 0x2e, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2e, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00, 0x00, 0x06, 0x01, 0x73, 0x00, 0x14, 0x00, 0x00, 0x00, 0x6f, 0x72, 0x67, 0x2e, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2e, 0x44, 0x42, 0x75, 0x73>> # 1 byte removed

        context "if it is set to return plain values" do
          let :unwrap_values, do: true

          it "should return error result" do
            expect(described_module.unmarshall_bitstring(bitstring, endianness, signature, unwrap_values)).to be_error_result
          end

          it "should return :bitstring_too_short as a reason" do
            {:error, reason} = described_module.unmarshall_bitstring(bitstring, endianness, signature, unwrap_values)
            expect(reason).to eq :bitstring_too_short
          end
        end

        context "if it is set to return wrapped values" do
          let :unwrap_values, do: false

          it "should return error result" do
            expect(described_module.unmarshall_bitstring(bitstring, endianness, signature, unwrap_values)).to be_error_result
          end

          it "should return :bitstring_too_short as a reason" do
            {:error, reason} = described_module.unmarshall_bitstring(bitstring, endianness, signature, unwrap_values)
            expect(reason).to eq :bitstring_too_short
          end
        end
      end

      context "if bitstring contains only data for values that exactly match signature" do
        let :bitstring, do: << 0x6c, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x6d, 0x00, 0x00, 0x00, 0x01, 0x01, 0x6f, 0x00, 0x15, 0x00, 0x00, 0x00, 0x2f, 0x6f, 0x72, 0x67, 0x2f, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2f, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00, 0x03, 0x01, 0x73, 0x00, 0x05, 0x00, 0x00, 0x00, 0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x00, 0x00, 0x00, 0x02, 0x01, 0x73, 0x00, 0x14, 0x00, 0x00, 0x00, 0x6f, 0x72, 0x67, 0x2e, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2e, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00, 0x00, 0x06, 0x01, 0x73, 0x00, 0x14, 0x00, 0x00, 0x00, 0x6f, 0x72, 0x67, 0x2e, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2e, 0x44, 0x42, 0x75, 0x73, 0x00>> # Exact amount of data

        context "if it is set to return plain values" do
          let :unwrap_values, do: true

          it "should return ok result" do
            expect(described_module.unmarshall_bitstring(bitstring, endianness, signature, unwrap_values)).to be_ok_result
          end

          it "should return appropriate list of values" do
            {:ok, {list_of_values, _rest}} = described_module.unmarshall_bitstring(bitstring, endianness, signature, unwrap_values)

            expect(list_of_values).to eq [108, 1, 0, 1, 0, 1, [
                {1, "/org/freedesktop/DBus"},
                {3, "Hello"},
                {2, "org.freedesktop.DBus"},
                {6, "org.freedesktop.DBus"}]]
          end

          it "should return empty rest" do
            {:ok, {_list_of_values, rest}} = described_module.unmarshall_bitstring(bitstring, endianness, signature, unwrap_values)

            expect(rest).to eq ""
          end
        end

        context "if it is set to return wrapped values" do
          let :unwrap_values, do: false

          it "should return ok result" do
            expect(described_module.unmarshall_bitstring(bitstring, endianness, signature, unwrap_values)).to be_ok_result
          end

          it "should return appropriate list of values" do
            {:ok, {list_of_values, _rest}} = described_module.unmarshall_bitstring(bitstring, endianness, signature, unwrap_values)

            expect(list_of_values).to eq [
              %DBux.Value{type: :byte, value: 108},
              %DBux.Value{type: :byte, value: 1},
              %DBux.Value{type: :byte, value: 0},
              %DBux.Value{type: :byte, value: 1},
              %DBux.Value{type: :uint32, value: 0},
              %DBux.Value{type: :uint32, value: 1},
              %DBux.Value{type: :array,
               value: [%DBux.Value{type: :struct,
                 value: [%DBux.Value{type: :byte, value: 1},
                  %DBux.Value{type: :variant,
                   value: %DBux.Value{type: :object_path,
                    value: "/org/freedesktop/DBus"}}]},
                %DBux.Value{type: :struct,
                 value: [%DBux.Value{type: :byte, value: 3},
                  %DBux.Value{type: :variant,
                   value: %DBux.Value{type: :string, value: "Hello"}}]},
                %DBux.Value{type: :struct,
                 value: [%DBux.Value{type: :byte, value: 2},
                  %DBux.Value{type: :variant,
                   value: %DBux.Value{type: :string,
                    value: "org.freedesktop.DBus"}}]},
                %DBux.Value{type: :struct,
                 value: [%DBux.Value{type: :byte, value: 6},
                  %DBux.Value{type: :variant,
                   value: %DBux.Value{type: :string,
                    value: "org.freedesktop.DBus"}}]}]}]
          end

          it "should return empty rest" do
            {:ok, {_list_of_values, rest}} = described_module.unmarshall_bitstring(bitstring, endianness, signature, unwrap_values)

            expect(rest).to eq ""
          end
        end
      end

      context "if bitstring contains more data than needed for values that match signature" do
        let :bitstring, do: << 0x6c, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x6d, 0x00, 0x00, 0x00, 0x01, 0x01, 0x6f, 0x00, 0x15, 0x00, 0x00, 0x00, 0x2f, 0x6f, 0x72, 0x67, 0x2f, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2f, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00, 0x03, 0x01, 0x73, 0x00, 0x05, 0x00, 0x00, 0x00, 0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x00, 0x00, 0x00, 0x02, 0x01, 0x73, 0x00, 0x14, 0x00, 0x00, 0x00, 0x6f, 0x72, 0x67, 0x2e, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2e, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00, 0x00, 0x06, 0x01, 0x73, 0x00, 0x14, 0x00, 0x00, 0x00, 0x6f, 0x72, 0x67, 0x2e, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2e, 0x44, 0x42, 0x75, 0x73, 0x00, "a", "b", "c">>

        context "if it is set to return plain values" do
          let :unwrap_values, do: true

          it "should return ok result" do
            expect(described_module.unmarshall_bitstring(bitstring, endianness, signature, unwrap_values)).to be_ok_result
          end

          it "should return appropriate list of values" do
            {:ok, {list_of_values, _rest}} = described_module.unmarshall_bitstring(bitstring, endianness, signature, unwrap_values)

            expect(list_of_values).to eq [108, 1, 0, 1, 0, 1, [
                {1, "/org/freedesktop/DBus"},
                {3, "Hello"},
                {2, "org.freedesktop.DBus"},
                {6, "org.freedesktop.DBus"}]]
          end

          it "should return rest containing remaining data" do
            {:ok, {_list_of_values, rest}} = described_module.unmarshall_bitstring(bitstring, endianness, signature, unwrap_values)

            expect(rest).to eq "abc"
          end
        end

        context "if it is set to return wrapped values" do
          let :unwrap_values, do: false

          it "should return ok result" do
            expect(described_module.unmarshall_bitstring(bitstring, endianness, signature, unwrap_values)).to be_ok_result
          end

          it "should return appropriate list of values" do
            {:ok, {list_of_values, _rest}} = described_module.unmarshall_bitstring(bitstring, endianness, signature, unwrap_values)

            expect(list_of_values).to eq [
              %DBux.Value{type: :byte, value: 108},
              %DBux.Value{type: :byte, value: 1},
              %DBux.Value{type: :byte, value: 0},
              %DBux.Value{type: :byte, value: 1},
              %DBux.Value{type: :uint32, value: 0},
              %DBux.Value{type: :uint32, value: 1},
              %DBux.Value{type: :array,
               value: [%DBux.Value{type: :struct,
                 value: [%DBux.Value{type: :byte, value: 1},
                  %DBux.Value{type: :variant,
                   value: %DBux.Value{type: :object_path,
                    value: "/org/freedesktop/DBus"}}]},
                %DBux.Value{type: :struct,
                 value: [%DBux.Value{type: :byte, value: 3},
                  %DBux.Value{type: :variant,
                   value: %DBux.Value{type: :string, value: "Hello"}}]},
                %DBux.Value{type: :struct,
                 value: [%DBux.Value{type: :byte, value: 2},
                  %DBux.Value{type: :variant,
                   value: %DBux.Value{type: :string,
                    value: "org.freedesktop.DBus"}}]},
                %DBux.Value{type: :struct,
                 value: [%DBux.Value{type: :byte, value: 6},
                  %DBux.Value{type: :variant,
                   value: %DBux.Value{type: :string,
                    value: "org.freedesktop.DBus"}}]}]}]
          end

          it "should return rest containing remaining data" do
            {:ok, {_list_of_values, rest}} = described_module.unmarshall_bitstring(bitstring, endianness, signature, unwrap_values)

            expect(rest).to eq "abc"
          end
        end
      end
    end
  end


  describe ".marshall_bitstring/2" do
    let :endianness, do: :little_endian

    context "if passed list of values is empty" do
      let :values, do: []

      it "should return ok result" do
        expect(described_module.marshall_bitstring(values, endianness)).to be_ok_result
      end

      it "should return an empty bitstring" do
        {:ok, bitstring} = described_module.marshall_bitstring(values, endianness)
        expect(bitstring).to eq ""
      end
    end


    context "if passed list of values is non-empty" do
      context "and it contains only simple types" do
        context "and one thay may need a padding is naturally aligned" do
          let :values, do: [
            %DBux.Value{type: :int32, value: 1234},
            %DBux.Value{type: :string, value: "abcde"}
          ]

          it "should return ok result" do
            expect(described_module.marshall_bitstring(values, endianness)).to be_ok_result
          end

          it "should return a bitstring that contains serialized values without any padding" do
            {:ok, bitstring} = described_module.marshall_bitstring(values, endianness)
            expect(bitstring).to eq <<210, 4, 0, 0, 5, 0, 0, 0, 97, 98, 99, 100, 101, 0>>
          end
        end

        context "and one thay may need a padding is not aligned" do
          let :values, do: [
            %DBux.Value{type: :string, value: "abcde"},
            %DBux.Value{type: :int32, value: 1234} # needs align of 4, previous string is 5 + 1
          ]

          it "should return ok result" do
            expect(described_module.marshall_bitstring(values, endianness)).to be_ok_result
          end

          it "should return a bitstring that contains serialized values without any padding" do
            {:ok, bitstring} = described_module.marshall_bitstring(values, endianness)
            expect(bitstring).to eq <<5, 0, 0, 0, 97, 98, 99, 100, 101, 0, 0, 0, 210, 4, 0, 0>>
          end
        end
      end
    end
  end
end
