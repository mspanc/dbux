defmodule DBux.TransportSpec do
  use ESpec

  describe ".get_module_for_address/1" do
    context "if given a TCP address" do
      context "that is valid" do
        let :address, do: "tcp:host=dbux.example.com,port=8888"

        it "returns an ok result" do
          expect(described_module.get_module_for_address(address)).to be_ok_result
        end

        it "returns DBux.Transport.TCP as a module" do
          {:ok, {mod, _opts}} = described_module.get_module_for_address(address)
          expect(mod).to eq DBux.Transport.TCP
        end

        it "returns parsed host & port as an options" do
          {:ok, {_mod, opts}} = described_module.get_module_for_address(address)
          expect(opts).to eq [host: "dbux.example.com", port: 8888]
        end
      end
    end
  end
end
