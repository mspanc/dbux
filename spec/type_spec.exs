defmodule DBux.TypeSpec do
  use ESpec

  describe ".type_from_signature/1" do
    context "for empty signature" do
      let :signature, do: ""

      it "returns an empty list" do
        expect(described_module.type_from_signature(signature)).to eq []
      end
    end

    context "for signature containing only simple types" do
      let :signature, do: "ybnqiuxtdsogh"

      it "returns a list of atoms of appropriate types" do
        expect(described_module.type_from_signature(signature)).to eq [
          :byte,
          :boolean,
          :int16,
          :uint16,
          :int32,
          :uint32,
          :int64,
          :uint64,
          :double,
          :string,
          :object_path,
          :signature,
          :unix_fd
        ]
      end
    end

    context "for signature containing structs" do
      context "in case of unfinished structs" do
        context "with struct that is opened but not closed" do
          let :signature, do: "uu(bb"

          it "should return {:error, {:badsignature, :unmatchedstruct}}" do
            expect(described_module.type_from_signature(signature)).to eq {:error, {:badsignature, :unmatchedstruct}}
          end
        end

        context "with struct that is closed but not opened" do
          let :signature, do: "uu)bb"

          it "should return {:error, {:badsignature, :unmatchedstruct}}" do
            expect(described_module.type_from_signature(signature)).to eq {:error, {:badsignature, :unmatchedstruct}}
          end
        end
      end

      context "in case of empty structs" do
        context "with only one empty struct" do
          let :signature, do: "()"

          it "should return {:error, {:badsignature, :emptystruct}}" do
            expect(described_module.type_from_signature(signature)).to eq {:error, {:badsignature, :emptystruct}}
          end
        end

        context "with only one empty struct embedded between other types" do
          let :signature, do: "bb()uu"

          it "should return {:error, {:badsignature, :emptystruct}}" do
            expect(described_module.type_from_signature(signature)).to eq {:error, {:badsignature, :emptystruct}}
          end
        end
      end

      context "in case of valid structs" do
        context "for signature containing only one struct with simple types inside" do
          context "if it is not prefixed or suffixed by any other values" do
            let :signature, do: "(bu)"

            it "returns a list of atoms and tuples of appropriate types" do
              expect(described_module.type_from_signature(signature)).to eq [{:struct, [:boolean, :uint32]}]
            end
          end

          context "if it is prefixed by other simple values" do
            let :signature, do: "i(bu)"

            it "returns a list of atoms and tuples of appropriate types" do
              expect(described_module.type_from_signature(signature)).to eq [:int32, {:struct, [:boolean, :uint32]}]
            end
          end

          context "if it is suffixed by other simple values" do
            let :signature, do: "(bu)i"

            it "returns a list of atoms and tuples of appropriate types" do
              expect(described_module.type_from_signature(signature)).to eq [{:struct, [:boolean, :uint32]}, :int32]
            end
          end

          context "if it is both prefixed suffixed by other simple values" do
            let :signature, do: "h(bu)i"

            it "returns a list of atoms and tuples of appropriate types" do
              expect(described_module.type_from_signature(signature)).to eq [:unix_fd, {:struct, [:boolean, :uint32]}, :int32]
            end
          end

          context "if it is prefixed by other structs" do
            let :signature, do: "(i)(bu)"

            it "returns a list of atoms and tuples of appropriate types" do
              expect(described_module.type_from_signature(signature)).to eq [{:struct, [:int32]}, {:struct, [:boolean, :uint32]}]
            end
          end

          context "if it is suffixed by other structs" do
            let :signature, do: "(bu)(i)"

            it "returns a list of atoms and tuples of appropriate types" do
              expect(described_module.type_from_signature(signature)).to eq [{:struct, [:boolean, :uint32]}, {:struct, [:int32]}]
            end
          end

          context "if it is both prefixed suffixed by other structs" do
            let :signature, do: "(h)(bu)(i)"

            it "returns a list of atoms and tuples of appropriate types" do
              expect(described_module.type_from_signature(signature)).to eq [{:struct, [:unix_fd]}, {:struct, [:boolean, :uint32]}, {:struct, [:int32]}]
            end
          end

          context "if it is nested" do
            let :signature, do: "h(bu(ds)i)(o)"

            it "returns a list of atoms and tuples of appropriate types" do
              expect(described_module.type_from_signature(signature)).to eq [
                :unix_fd, {:struct, [:boolean, :uint32, {:struct, [:double, :string]}, :int32]},
                {:struct, [:object_path]}
              ]
            end
          end
        end
      end
    end
  end
end
