defmodule DBux.MessageTemplateSpec do
  use ESpec

  describe ".hello/1" do
    context "if no serial is given" do
      it "returns a valid Hello message with serial set to 0" do
        expect(described_module.hello()).to eq %DBux.Message{
          body: [], destination: "org.freedesktop.DBus", error_name: nil,
          flags: 0, interface: "org.freedesktop.DBus", member: "Hello",
          message_type: :method_call, path: "/org/freedesktop/DBus", reply_serial: nil,
          sender: nil, serial: 0, signature: "", unix_fds: nil}
      end
    end

    context "if serial is given" do
      it "returns a valid Hello message with serial set to given serial" do
        expect(described_module.hello(123)).to eq %DBux.Message{
          body: [], destination: "org.freedesktop.DBus", error_name: nil,
          flags: 0, interface: "org.freedesktop.DBus", member: "Hello",
          message_type: :method_call, path: "/org/freedesktop/DBus", reply_serial: nil,
          sender: nil, serial: 123, signature: "", unix_fds: nil}
      end
    end
  end


  describe ".request_name/3" do
    let :name, do: "org.something.dbux"

    context "if no serial and flags are given" do
      it "returns a valid RequestName message with serial and flags set to 0" do
        expect(described_module.request_name(name)).to eq %DBux.Message{
          body: [
            %DBux.Value{type: :string, value: name},
            %DBux.Value{type: :uint32, value: 0}
          ], destination: "org.freedesktop.DBus", error_name: nil,
          flags: 0, interface: "org.freedesktop.DBus", member: "RequestName",
          message_type: :method_call, path: "/org/freedesktop/DBus", reply_serial: nil,
          sender: nil, serial: 0, signature: "", unix_fds: nil}
      end
    end

    context "if no serial is given but flags are given" do
      it "returns a valid RequestName message with serial set to 0 and given flags" do
        expect(described_module.request_name(name, 1)).to eq %DBux.Message{
          body: [
            %DBux.Value{type: :string, value: name},
            %DBux.Value{type: :uint32, value: 1}
          ], destination: "org.freedesktop.DBus", error_name: nil,
          flags: 0, interface: "org.freedesktop.DBus", member: "RequestName",
          message_type: :method_call, path: "/org/freedesktop/DBus", reply_serial: nil,
          sender: nil, serial: 0, signature: "", unix_fds: nil}
      end
    end

    context "if both serial and flags are given" do
      it "returns a valid RequestName message with serial and flags given set to given values" do
        expect(described_module.request_name(name, 1, 123)).to eq %DBux.Message{
          body: [
            %DBux.Value{type: :string, value: name},
            %DBux.Value{type: :uint32, value: 1}
          ], destination: "org.freedesktop.DBus", error_name: nil,
          flags: 0, interface: "org.freedesktop.DBus", member: "RequestName",
          message_type: :method_call, path: "/org/freedesktop/DBus", reply_serial: nil,
          sender: nil, serial: 123, signature: "", unix_fds: nil}
      end
    end
  end


  describe ".list_names/1" do
    context "if no serial is given" do
      it "returns a valid ListNames message with serial set to 0" do
        expect(described_module.list_names()).to eq %DBux.Message{
          body: [], destination: "org.freedesktop.DBus", error_name: nil,
          flags: 0, interface: "org.freedesktop.DBus", member: "ListNames",
          message_type: :method_call, path: "/org/freedesktop/DBus", reply_serial: nil,
          sender: nil, serial: 0, signature: "", unix_fds: nil}
      end
    end

    context "if serial is given" do
      it "returns a valid ListNames message with serial set to given serial" do
        expect(described_module.list_names(123)).to eq %DBux.Message{
          body: [], destination: "org.freedesktop.DBus", error_name: nil,
          flags: 0, interface: "org.freedesktop.DBus", member: "ListNames",
          message_type: :method_call, path: "/org/freedesktop/DBus", reply_serial: nil,
          sender: nil, serial: 123, signature: "", unix_fds: nil}
      end
    end
  end
end
