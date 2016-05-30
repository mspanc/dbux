defmodule DBux.AuthSpec do
  use ESpec

  describe ".get_module_for_method/1" do
    context "if given :anonymous" do
      let :method, do: :anonymous
      it "returns an ok result" do
        expect(described_module.get_module_for_method(method)).to be_ok_result
      end

      it "returns DBux.Auth.Anonymous as a module" do
        {:ok, {mod, _opts}} = described_module.get_module_for_method(method)
        expect(mod).to eq DBux.Auth.Anonymous
      end

      it "returns empty options" do
        {:ok, {_mod, opts}} = described_module.get_module_for_method(method)
        expect(opts).to eq []
      end
    end
  end
end
