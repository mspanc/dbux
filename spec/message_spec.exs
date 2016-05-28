defmodule DBux.MessageSpec do
  use ESpec

  describe ".marshall/2" do
  end


  describe ".unmarshall/1" do
    context "in case of some well-known messages" do
      context "Hello" do
        let :bitstring, do: <<0x6c, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x70, 0x00, 0x00, 0x00, 0x01, 0x01, 0x6f, 0x00, 0x15, 0x00, 0x00, 0x00, 0x2f, 0x6f, 0x72, 0x67, 0x2f, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2f, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00, 0x03, 0x01, 0x73, 0x00, 0x05, 0x00, 0x00, 0x00, 0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x00, 0x00, 0x00, 0x02, 0x01, 0x73, 0x00, 0x14, 0x00, 0x00, 0x00, 0x6f, 0x72, 0x67, 0x2e, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2e, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00, 0x00, 0x06, 0x01, 0x73, 0x00, 0x14, 0x00, 0x00, 0x00, 0x6f, 0x72, 0x67, 0x2e, 0x66, 0x72, 0x65, 0x65, 0x64, 0x65, 0x73, 0x6b, 0x74, 0x6f, 0x70, 0x2e, 0x44, 0x42, 0x75, 0x73, 0x00, 0x00, 0x00, 0x00>>

        it "should return {:ok, result}" do
          expect(described_module.unmarshall(bitstring)).to be_ok_result
        end

        it "should have destination set to \"org.freedesktop.DBus\"" do
          {:ok, message} = described_module.unmarshall(bitstring)
          expect(message.destination).to eq "org.freedesktop.DBus"
        end

        it "should have error_name set to nil" do
          {:ok, message} = described_module.unmarshall(bitstring)
          expect(message.error_name).to be_nil
        end

        it "should have flags set to 0" do
          {:ok, message} = described_module.unmarshall(bitstring)
          expect(message.flags).to eq 0
        end

        it "should have interface set to \"org.freedesktop.DBus\"" do
          {:ok, message} = described_module.unmarshall(bitstring)
          expect(message.interface).to eq "org.freedesktop.DBus"
        end

        it "should have member set to \"Hello\"" do
          {:ok, message} = described_module.unmarshall(bitstring)
          expect(message.member).to eq "Hello"
        end

        it "should have path set to \"/org/freedesktop/DBus\"" do
          {:ok, message} = described_module.unmarshall(bitstring)
          expect(message.path).to eq "/org/freedesktop/DBus"
        end

        it "should have reply_serial set to nil" do
          {:ok, message} = described_module.unmarshall(bitstring)
          expect(message.reply_serial).to be_nil
        end

        it "should have sender set to nil" do
          {:ok, message} = described_module.unmarshall(bitstring)
          expect(message.sender).to be_nil
        end

        it "should have serial set to 1" do
          {:ok, message} = described_module.unmarshall(bitstring)
          expect(message.serial).to eq 1
        end

        it "should have signature set to \"\"" do
          {:ok, message} = described_module.unmarshall(bitstring)
          expect(message.signature).to eq ""
        end

        it "should have type set to :method_call" do
          {:ok, message} = described_module.unmarshall(bitstring)
          expect(message.type).to eq :method_call
        end

        it "should have unix_fds set to nil" do
          {:ok, message} = described_module.unmarshall(bitstring)
          expect(message.unix_fds).to be_nil
        end
      end
    end
  end
end
