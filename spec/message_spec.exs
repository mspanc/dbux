defmodule DBux.MessageSpec do
  use ESpec

  # In practice the order of header fields may vary, and this is allowed
  # by the specification. We test against specific order of header fields
  # and endianness here.
  describe ".marshall/2" do
    context "in case of some well-known messages" do
      context "Hello" do
        let :message, do: DBux.Message.build_method_call("/org/freedesktop/DBus", "org.freedesktop.DBus", "Hello", "", [], "org.freedesktop.DBus", 1)
        let :endianness, do: :little_endian

        let :expected_bitstring, do: << 0x6c, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x6d, 0x00, 0x00, 0x00, 0x01, 0x01, 0x6f, 0x00, 0x15, 0x00, 0x00, 0x00, 0x2f, 0x6f, 0x72, 0x67, 0x2f, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2f, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00, 0x03, 0x01, 0x73, 0x00, 0x05, 0x00, 0x00, 0x00, 0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x00, 0x00, 0x00, 0x02, 0x01, 0x73, 0x00, 0x14, 0x00, 0x00, 0x00, 0x6f, 0x72, 0x67, 0x2e, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2e, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00, 0x00, 0x06, 0x01, 0x73, 0x00, 0x14, 0x00, 0x00, 0x00, 0x6f, 0x72, 0x67, 0x2e, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2e, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00, 0x00>>

        it "should return ok result" do
          expect(described_module.marshall(message, endianness)).to be_ok_result
        end

        it "should return valid bitstring" do
          {:ok, bitstring} = described_module.marshall(message, endianness)
          expect(bitstring).to eq expected_bitstring
        end
      end

      context "RequestName" do
        let :message, do: DBux.Message.build_method_call("/org/freedesktop/DBus", "org.freedesktop.DBus", "RequestName", "su", [%DBux.Value{type: :string, value: "com.example.dbus"}, %DBux.Value{type: :uint32, value: 0}], "org.freedesktop.DBus", 2) |> Map.put(:sender, ":1.1646")
        let :endianness, do: :little_endian

        let :expected_bitstring, do: << 0x6c, 0x01, 0x00, 0x01, 0x1c, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x90, 0x00, 0x00, 0x00,  0x08, 0x01, 0x67, 0x00, 0x02, 0x73, 0x75, 0x00,  0x01, 0x01, 0x6f, 0x00, 0x15, 0x00, 0x00, 0x00, 0x2f, 0x6f, 0x72, 0x67, 0x2f, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2f, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00,  0x03, 0x01, 0x73, 0x00, 0x0b, 0x00, 0x00, 0x00, 0x52, 0x65, 0x71, 0x75, 0x65, 0x73, 0x74, 0x4e, 0x61, 0x6d, 0x65, 0x00, 0x00, 0x00, 0x00, 0x00,  0x02, 0x01, 0x73, 0x00, 0x14, 0x00, 0x00, 0x00, 0x6f, 0x72, 0x67, 0x2e, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2e, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00, 0x00,  0x06, 0x01, 0x73, 0x00, 0x14, 0x00, 0x00, 0x00, 0x6f, 0x72, 0x67, 0x2e, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2e, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00, 0x00,  0x07, 0x01, 0x73, 0x00, 0x07, 0x00, 0x00, 0x00, 0x3a, 0x31, 0x2e, 0x31, 0x36, 0x34, 0x36, 0x00,  0x10, 0x00, 0x00, 0x00, 0x63, 0x6f, 0x6d, 0x2e, 0x65, 0x78, 0x61, 0x6d, 0x70, 0x6c, 0x65, 0x2e, 0x64, 0x62, 0x75, 0x73, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 >>

        it "should return ok result" do
          expect(described_module.marshall(message, endianness)).to be_ok_result
        end

        it "should return valid bitstring" do
          {:ok, bitstring} = described_module.marshall(message, endianness)
          expect(bitstring).to eq expected_bitstring
        end
      end
    end

    xcontext "if message body contains a dict" do
      let :message, do: DBux.Message.build_method_call("/Test", "org.example.dbux", "Test", "a{ss}", [%DBux.Value{type: :array, value: [%DBux.Value{type: :dict_entry, value: [%DBux.Value{type: :string, value: "abcde"}, %DBux.Value{type: :string, value: "fg"}]}]}], "org.example.dbux", 2)
      let :endianness, do: :little_endian

      # Generated with dbus-send --type=method_call --dest=org.example.dbux /Test org.example.dbux.Test dict:string:string:"abcde","fg"
      let :expected_bitstring, do: << 0x6c, 0x01, 0x00, 0x01, 0x1b, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x6b, 0x00, 0x00, 0x00, 0x01, 0x01, 0x6f, 0x00, 0x05, 0x00, 0x00, 0x00, 0x2f, 0x54, 0x65, 0x73, 0x74, 0x00, 0x00, 0x00, 0x02, 0x01, 0x73, 0x00, 0x10, 0x00, 0x00, 0x00, 0x6f, 0x72, 0x67, 0x2e, 0x65, 0x78, 0x61, 0x6d, 0x70, 0x6c, 0x65, 0x2e, 0x64, 0x62, 0x75, 0x78, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0x01, 0x73, 0x00, 0x04, 0x00, 0x00, 0x00, 0x54, 0x65, 0x73, 0x74, 0x00, 0x00, 0x00, 0x00, 0x06, 0x01, 0x73, 0x00, 0x10, 0x00, 0x00, 0x00, 0x6f, 0x72, 0x67, 0x2e, 0x65, 0x78, 0x61, 0x6d, 0x70, 0x6c, 0x65, 0x2e, 0x64, 0x62, 0x75, 0x78, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0x01, 0x67, 0x00, 0x05, 0x61, 0x7b, 0x73, 0x73, 0x7d, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x13, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x05, 0x00, 0x00, 0x00, 0x61, 0x62, 0x63, 0x64, 0x65, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x66, 0x67, 0x00 >>

      it "should return ok result" do
        expect(described_module.marshall(message, endianness)).to be_ok_result
      end

      it "should return valid bitstring" do
        {:ok, bitstring} = described_module.marshall(message, endianness)
        expect(bitstring).to eq expected_bitstring
      end
    end

  end


  describe ".unmarshall/2" do
    # These bitstrings come from real messages generated by GDBus, use only
    # messages generated by the reference implementation or GDBus when adding
    # new test cases.
    context "if passed bitstring contains exactly one message" do
      context "in case of some well-known messages" do
        context "Hello" do
          let :bitstring, do: << 0x6c, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x6d, 0x00, 0x00, 0x00, 0x01, 0x01, 0x6f, 0x00, 0x15, 0x00, 0x00, 0x00, 0x2f, 0x6f, 0x72, 0x67, 0x2f, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2f, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00, 0x03, 0x01, 0x73, 0x00, 0x05, 0x00, 0x00, 0x00, 0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x00, 0x00, 0x00, 0x02, 0x01, 0x73, 0x00, 0x14, 0x00, 0x00, 0x00, 0x6f, 0x72, 0x67, 0x2e, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2e, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00, 0x00, 0x06, 0x01, 0x73, 0x00, 0x14, 0x00, 0x00, 0x00, 0x6f, 0x72, 0x67, 0x2e, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2e, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00, 0x00>>
          let :unwrap_values, do: true

          it "should return ok result" do
            expect(described_module.unmarshall(bitstring, unwrap_values)).to be_ok_result
          end

          it "should have destination set to \"org.freedesktop.DBus\"" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.destination).to eq "org.freedesktop.DBus"
          end

          it "should have error_name set to nil" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.error_name).to be_nil
          end

          it "should have flags set to 0" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.flags).to eq 0
          end

          it "should have interface set to \"org.freedesktop.DBus\"" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.interface).to eq "org.freedesktop.DBus"
          end

          it "should have member set to \"Hello\"" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.member).to eq "Hello"
          end

          it "should have path set to \"/org/freedesktop/DBus\"" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.path).to eq "/org/freedesktop/DBus"
          end

          it "should have reply_serial set to nil" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.reply_serial).to be_nil
          end

          it "should have sender set to nil" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.sender).to be_nil
          end

          it "should have serial set to 1" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.serial).to eq 1
          end

          it "should have signature set to \"\"" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.signature).to eq ""
          end

          it "should have message_type set to :method_call" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.message_type).to eq :method_call
          end

          it "should have unix_fds set to nil" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.unix_fds).to be_nil
          end

          it "should have body set to empty list" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.body).to eq []
          end

          it "should leave no rest" do
            {:ok, {_message, rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(rest).to eq << >>
          end
        end

        context "NameOwnerChanged" do
          let :bitstring, do: << 0x6c, 0x04, 0x01, 0x01, 0x1d, 0x00, 0x00, 0x00, 0x1d, 0x00, 0x00, 0x00, 0x89, 0x00, 0x00, 0x00, 0x01, 0x01, 0x6f, 0x00, 0x15, 0x00, 0x00, 0x00, 0x2f, 0x6f, 0x72, 0x67, 0x2f, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2f, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00, 0x02, 0x01, 0x73, 0x00, 0x14, 0x00, 0x00, 0x00, 0x6f, 0x72, 0x67, 0x2e, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2e, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00, 0x00, 0x03, 0x01, 0x73, 0x00, 0x10, 0x00, 0x00, 0x00, 0x4e, 0x61, 0x6d, 0x65, 0x4f, 0x77, 0x6e, 0x65, 0x72, 0x43, 0x68, 0x61, 0x6e, 0x67, 0x65, 0x64, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x07, 0x01, 0x73, 0x00, 0x14, 0x00, 0x00, 0x00, 0x6f, 0x72, 0x67, 0x2e, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2e, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00, 0x00, 0x08, 0x01, 0x67, 0x00, 0x03, 0x73, 0x73, 0x73, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x07, 0x00, 0x00, 0x00, 0x3a, 0x31, 0x2e, 0x31, 0x36, 0x32, 0x34, 0x00, 0x07, 0x00, 0x00, 0x00, 0x3a, 0x31, 0x2e, 0x31, 0x36, 0x32, 0x34, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 >>
          let :unwrap_values, do: true

          it "should return ok result" do
            expect(described_module.unmarshall(bitstring, unwrap_values)).to be_ok_result
          end

          it "should have destination set to nil" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.destination).to be_nil
          end

          it "should have error_name set to nil" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.error_name).to be_nil
          end

          it "should have flags set to 1" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.flags).to eq 1
          end

          it "should have interface set to \"org.freedesktop.DBus\"" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.interface).to eq "org.freedesktop.DBus"
          end

          it "should have member set to \"NameOwnerChanged\"" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.member).to eq "NameOwnerChanged"
          end

          it "should have path set to \"/org/freedesktop/DBus\"" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.path).to eq "/org/freedesktop/DBus"
          end

          it "should have reply_serial set to nil" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.reply_serial).to be_nil
          end

          it "should have sender set to \"org.freedesktop.DBus\"" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.sender).to eq "org.freedesktop.DBus"
          end

          it "should have serial set to 29" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.serial).to eq 29
          end

          it "should have signature set to \"sss\"" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.signature).to eq "sss"
          end

          it "should have message_type set to :signal" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.message_type).to eq :signal
          end

          it "should have unix_fds set to nil" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.unix_fds).to be_nil
          end

          it "should have body set to list of strings" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.body).to eq [":1.1624", ":1.1624", ""]
          end

          it "should leave no rest" do
            {:ok, {_message, rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(rest).to eq << >>
          end
        end

        context "RequestName" do
          let :bitstring, do: << 0x6c, 0x01, 0x00, 0x01, 0x1c, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x90, 0x00, 0x00, 0x00, 0x08, 0x01, 0x67, 0x00, 0x02, 0x73, 0x75, 0x00, 0x01, 0x01, 0x6f, 0x00, 0x15, 0x00, 0x00, 0x00, 0x2f, 0x6f, 0x72, 0x67, 0x2f, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2f, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00, 0x03, 0x01, 0x73, 0x00, 0x0b, 0x00, 0x00, 0x00, 0x52, 0x65, 0x71, 0x75, 0x65, 0x73, 0x74, 0x4e, 0x61, 0x6d, 0x65, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x01, 0x73, 0x00, 0x14, 0x00, 0x00, 0x00, 0x6f, 0x72, 0x67, 0x2e, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2e, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00, 0x00, 0x06, 0x01, 0x73, 0x00, 0x14, 0x00, 0x00, 0x00, 0x6f, 0x72, 0x67, 0x2e, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2e, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00, 0x00, 0x07, 0x01, 0x73, 0x00, 0x07, 0x00, 0x00, 0x00, 0x3a, 0x31, 0x2e, 0x31, 0x36, 0x34, 0x30, 0x00, 0x10, 0x00, 0x00, 0x00, 0x63, 0x6f, 0x6d, 0x2e, 0x65, 0x78, 0x61, 0x6d, 0x70, 0x6c, 0x65, 0x2e, 0x64, 0x62, 0x75, 0x73, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 >>
          let :unwrap_values, do: true

          it "should return ok result" do
            expect(described_module.unmarshall(bitstring, unwrap_values)).to be_ok_result
          end

          it "should have destination set to \"org.freedesktop.DBus\"" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.destination).to eq "org.freedesktop.DBus"
          end

          it "should have error_name set to nil" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.error_name).to be_nil
          end

          it "should have flags set to 0" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.flags).to eq 0
          end

          it "should have interface set to \"org.freedesktop.DBus\"" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.interface).to eq "org.freedesktop.DBus"
          end

          it "should have member set to \"RequestName\"" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.member).to eq "RequestName"
          end

          it "should have path set to \"/org/freedesktop/DBus\"" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.path).to eq "/org/freedesktop/DBus"
          end

          it "should have reply_serial set to nil" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.reply_serial).to be_nil
          end

          it "should have sender set to \":1.1640\"" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.sender).to eq ":1.1640"
          end

          it "should have serial set to 2" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.serial).to eq 2
          end

          it "should have signature set to \"su\"" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.signature).to eq "su"
          end

          it "should have message_type set to :method_call" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.message_type).to eq :method_call
          end

          it "should have unix_fds set to nil" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.unix_fds).to be_nil
          end

          it "should have body set to list of values" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.body).to eq ["com.example.dbus", 0]
          end

          it "should leave no rest" do
            {:ok, {_message, rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(rest).to eq << >>
          end
        end

        context "reply to ListNames" do
          let :bitstring, do: << 0x6c, 0x02, 0x01, 0x01, 0xb9, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x3d, 0x00, 0x00, 0x00, 0x06, 0x01, 0x73, 0x00, 0x06, 0x00, 0x00, 0x00, 0x3a, 0x31, 0x2e, 0x31, 0x30, 0x35, 0x00, 0x00, 0x05, 0x01, 0x75, 0x00, 0x02, 0x00, 0x00, 0x00, 0x08, 0x01, 0x67, 0x00, 0x02, 0x61, 0x73, 0x00, 0x07, 0x01, 0x73, 0x00, 0x14, 0x00, 0x00, 0x00, 0x6f, 0x72, 0x67, 0x2e, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2e, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00, 0x00, 0xb5, 0x00, 0x00, 0x00, 0x14, 0x00, 0x00, 0x00, 0x6f, 0x72, 0x67, 0x2e, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2e, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x3a, 0x31, 0x2e, 0x33, 0x00, 0x00, 0x00, 0x00, 0x1c, 0x00, 0x00, 0x00, 0x6f, 0x72, 0x67, 0x2e, 0x72, 0x61, 0x64, 0x69, 0x6f, 0x6b, 0x69, 0x74, 0x2e, 0x70, 0x6c, 0x75, 0x6d, 0x62, 0x65, 0x72, 0x2e, 0x62, 0x61, 0x63, 0x6b, 0x65, 0x6e, 0x64, 0x00, 0x00, 0x00, 0x00, 0x05, 0x00, 0x00, 0x00, 0x3a, 0x31, 0x2e, 0x35, 0x33, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x3a, 0x31, 0x2e, 0x34, 0x00, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x3a, 0x31, 0x2e, 0x30, 0x00, 0x00, 0x00, 0x00, 0x05, 0x00, 0x00, 0x00, 0x3a, 0x31, 0x2e, 0x31, 0x30, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x3a, 0x31, 0x2e, 0x39, 0x00, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x3a, 0x31, 0x2e, 0x35, 0x00, 0x00, 0x00, 0x00, 0x06, 0x00, 0x00, 0x00, 0x3a, 0x31, 0x2e, 0x31, 0x30, 0x35, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x3a, 0x31, 0x2e, 0x36, 0x00, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x3a, 0x31, 0x2e, 0x32, 0x00 >>
          let :unwrap_values, do: true

          it "should return ok result" do
            expect(described_module.unmarshall(bitstring, unwrap_values)).to be_ok_result
          end

          it "should have destination set to \":1.105\"" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.destination).to eq ":1.105"
          end

          it "should have error_name set to nil" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.error_name).to be_nil
          end

          it "should have flags set to 1" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.flags).to eq 1
          end

          it "should have interface set to nil" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.interface).to be_nil
          end

          it "should have member set to nil" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.member).to be_nil
          end

          it "should have path set to nil" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.path).to be_nil
          end

          it "should have reply_serial set to 2" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.reply_serial).to eq 2
          end

          it "should have sender set to \"org.freedesktop.DBus\"" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.sender).to eq "org.freedesktop.DBus"
          end

          it "should have serial set to 3" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.serial).to eq 3
          end

          it "should have signature set to \"as\"" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.signature).to eq "as"
          end

          it "should have message_type set to :method_return" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.message_type).to eq :method_return
          end

          it "should have unix_fds set to nil" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.unix_fds).to be_nil
          end

          it "should have body set to list of values" do
            {:ok, {message, _rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(message.body).to eq [["org.freedesktop.DBus", ":1.3",
                "org.radiokit.plumber.backend", ":1.53", ":1.4", ":1.0", ":1.10", ":1.9",
                ":1.5", ":1.105", ":1.6", ":1.2"]]
          end

          it "should leave no rest" do
            {:ok, {_message, rest}} = described_module.unmarshall(bitstring, unwrap_values)
            expect(rest).to eq << >>
          end
        end
      end
    end

    context "if passed bitstring contains message with missing data" do
      let :unwrap_values, do: true

      context "at the end of header padding" do
        # Hello with stripped 1 byte at the end of header padding
        let :bitstring, do: << 0x6c, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x6d, 0x00, 0x00, 0x00, 0x01, 0x01, 0x6f, 0x00, 0x15, 0x00, 0x00, 0x00, 0x2f, 0x6f, 0x72, 0x67, 0x2f, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2f, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00, 0x03, 0x01, 0x73, 0x00, 0x05, 0x00, 0x00, 0x00, 0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x00, 0x00, 0x00, 0x02, 0x01, 0x73, 0x00, 0x14, 0x00, 0x00, 0x00, 0x6f, 0x72, 0x67, 0x2e, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2e, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00, 0x00, 0x06, 0x01, 0x73, 0x00, 0x14, 0x00, 0x00, 0x00, 0x6f, 0x72, 0x67, 0x2e, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2e, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00>>

        it "should return error result" do
          expect(described_module.unmarshall(bitstring, unwrap_values)).to be_error_result
        end

        it "should return :bitstring_too_short as a reason" do
          {:error, reason} = described_module.unmarshall(bitstring, unwrap_values)
          expect(reason).to eq :bitstring_too_short
        end
      end

      context "at the end of body" do
        # Reply to ListNames with stripped 1 byte at the end of body
        let :bitstring, do: << 0x6c, 0x02, 0x01, 0x01, 0xb9, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x3d, 0x00, 0x00, 0x00, 0x06, 0x01, 0x73, 0x00, 0x06, 0x00, 0x00, 0x00, 0x3a, 0x31, 0x2e, 0x31, 0x30, 0x35, 0x00, 0x00, 0x05, 0x01, 0x75, 0x00, 0x02, 0x00, 0x00, 0x00, 0x08, 0x01, 0x67, 0x00, 0x02, 0x61, 0x73, 0x00, 0x07, 0x01, 0x73, 0x00, 0x14, 0x00, 0x00, 0x00, 0x6f, 0x72, 0x67, 0x2e, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2e, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00, 0x00, 0xb5, 0x00, 0x00, 0x00, 0x14, 0x00, 0x00, 0x00, 0x6f, 0x72, 0x67, 0x2e, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2e, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x3a, 0x31, 0x2e, 0x33, 0x00, 0x00, 0x00, 0x00, 0x1c, 0x00, 0x00, 0x00, 0x6f, 0x72, 0x67, 0x2e, 0x72, 0x61, 0x64, 0x69, 0x6f, 0x6b, 0x69, 0x74, 0x2e, 0x70, 0x6c, 0x75, 0x6d, 0x62, 0x65, 0x72, 0x2e, 0x62, 0x61, 0x63, 0x6b, 0x65, 0x6e, 0x64, 0x00, 0x00, 0x00, 0x00, 0x05, 0x00, 0x00, 0x00, 0x3a, 0x31, 0x2e, 0x35, 0x33, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x3a, 0x31, 0x2e, 0x34, 0x00, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x3a, 0x31, 0x2e, 0x30, 0x00, 0x00, 0x00, 0x00, 0x05, 0x00, 0x00, 0x00, 0x3a, 0x31, 0x2e, 0x31, 0x30, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x3a, 0x31, 0x2e, 0x39, 0x00, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x3a, 0x31, 0x2e, 0x35, 0x00, 0x00, 0x00, 0x00, 0x06, 0x00, 0x00, 0x00, 0x3a, 0x31, 0x2e, 0x31, 0x30, 0x35, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x3a, 0x31, 0x2e, 0x36, 0x00, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x3a, 0x31, 0x2e, 0x32 >>

        it "should return error result" do
          expect(described_module.unmarshall(bitstring, unwrap_values)).to be_error_result
        end

        it "should return :bitstring_too_short as a reason" do
          {:error, reason} = described_module.unmarshall(bitstring, unwrap_values)
          expect(reason).to eq :bitstring_too_short
        end
      end
    end
  end
end
