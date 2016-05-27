defmodule DBux.TypeSpec do
  use ESpec

  describe ".type_from_signature/1" do
    context "for empty signature" do
      let :signature, do: ""

      it "returns an empty list" do
        expect(described_module.type_from_signature(signature)).to eq {:ok, []}
      end
    end

    context "for signature containing only simple types" do
      let :signature, do: "ybnqiuxtdsogh"

      it "returns a list of atoms of appropriate types" do
        expect(described_module.type_from_signature(signature)).to eq {:ok, [
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
        ]}
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
              expect(described_module.type_from_signature(signature)).to eq {:ok, [{:struct, [:boolean, :uint32]}]}
            end
          end

          context "if it is prefixed by other simple values" do
            let :signature, do: "i(bu)"

            it "returns a list of atoms and tuples of appropriate types" do
              expect(described_module.type_from_signature(signature)).to eq {:ok, [:int32, {:struct, [:boolean, :uint32]}]}
            end
          end

          context "if it is suffixed by other simple values" do
            let :signature, do: "(bu)i"

            it "returns a list of atoms and tuples of appropriate types" do
              expect(described_module.type_from_signature(signature)).to eq {:ok, [{:struct, [:boolean, :uint32]}, :int32]}
            end
          end

          context "if it is both prefixed suffixed by other simple values" do
            let :signature, do: "h(bu)i"

            it "returns a list of atoms and tuples of appropriate types" do
              expect(described_module.type_from_signature(signature)).to eq {:ok, [:unix_fd, {:struct, [:boolean, :uint32]}, :int32]}
            end
          end

          context "if it is prefixed by other structs" do
            let :signature, do: "(i)(bu)"

            it "returns a list of atoms and tuples of appropriate types" do
              expect(described_module.type_from_signature(signature)).to eq {:ok, [{:struct, [:int32]}, {:struct, [:boolean, :uint32]}]}
            end
          end

          context "if it is suffixed by other structs" do
            let :signature, do: "(bu)(i)"

            it "returns a list of atoms and tuples of appropriate types" do
              expect(described_module.type_from_signature(signature)).to eq {:ok, [{:struct, [:boolean, :uint32]}, {:struct, [:int32]}]}
            end
          end

          context "if it is both prefixed suffixed by other structs" do
            let :signature, do: "(h)(bu)(i)"

            it "returns a list of atoms and tuples of appropriate types" do
              expect(described_module.type_from_signature(signature)).to eq {:ok, [{:struct, [:unix_fd]}, {:struct, [:boolean, :uint32]}, {:struct, [:int32]}]}
            end
          end

          context "if it is nested" do
            let :signature, do: "h(bu(ds)i)(o)"

            it "returns a list of atoms and tuples of appropriate types" do
              expect(described_module.type_from_signature(signature)).to eq {:ok, [
                :unix_fd, {:struct, [:boolean, :uint32, {:struct, [:double, :string]}, :int32]},
                {:struct, [:object_path]}
              ]}
            end
          end
        end
      end
    end


    context "for signature containing dicts" do
      context "in case of unfinished dicts" do
        context "with dict that is opened but not closed" do
          let :signature, do: "uua{bb"

          it "should return {:error, {:badsignature, :unmatcheddict}}" do
            expect(described_module.type_from_signature(signature)).to eq {:error, {:badsignature, :unmatcheddict}}
          end
        end

        context "with dict that is closed but not opened" do
          let :signature, do: "uua}bb"

          it "should return {:error, {:badsignature, :unmatcheddict}}" do
            expect(described_module.type_from_signature(signature)).to eq {:error, {:badsignature, :unmatcheddict}}
          end
        end
      end

      context "in case of empty dicts" do
        context "with only one empty dict" do
          let :signature, do: "a{}"

          it "should return {:error, {:badsignature, :emptydict}}" do
            expect(described_module.type_from_signature(signature)).to eq {:error, {:badsignature, :emptydict}}
          end
        end

        context "with only one empty dict embedded between other types" do
          let :signature, do: "bba{}uu"

          it "should return {:error, {:badsignature, :emptydict}}" do
            expect(described_module.type_from_signature(signature)).to eq {:error, {:badsignature, :emptydict}}
          end
        end
      end

      context "in case of unwrapped dicts" do
        context "with only one empty dict" do
          let :signature, do: "{}"

          it "should return {:error, {:badsignature, :unwrappeddict}}" do
            expect(described_module.type_from_signature(signature)).to eq {:error, {:badsignature, :unwrappeddict}}
          end
        end

        context "with only one empty dict embedded between other types" do
          let :signature, do: "bb{}uu"

          it "should return {:error, {:badsignature, :unwrappeddict}}" do
            expect(described_module.type_from_signature(signature)).to eq {:error, {:badsignature, :unwrappeddict}}
          end
        end
      end

      context "in case of valid dicts" do
        context "for signature containing only one dict with simple types inside" do
          context "if it is not prefixed or suffixed by any other values" do
            let :signature, do: "a{bu}"

            it "returns a list of atoms and tuples of appropriate types" do
              expect(described_module.type_from_signature(signature)).to eq {:ok, [{:array, [{:dict, [:boolean, :uint32]}]}]}
            end
          end

          context "if it is prefixed by other simple values" do
            let :signature, do: "ia{bu}"

            it "returns a list of atoms and tuples of appropriate types" do
              expect(described_module.type_from_signature(signature)).to eq {:ok, [:int32, {:array, [{:dict, [:boolean, :uint32]}]}]}
            end
          end

          context "if it is suffixed by other simple values" do
            let :signature, do: "a{bu}i"

            it "returns a list of atoms and tuples of appropriate types" do
              expect(described_module.type_from_signature(signature)).to eq {:ok, [{:array, [{:dict, [:boolean, :uint32]}]}, :int32]}
            end
          end

          context "if it is both prefixed suffixed by other simple values" do
            let :signature, do: "ha{bu}i"

            it "returns a list of atoms and tuples of appropriate types" do
              expect(described_module.type_from_signature(signature)).to eq {:ok, [:unix_fd, {:array, [{:dict, [:boolean, :uint32]}]}, :int32]}
            end
          end

          context "if it is prefixed by other dicts" do
            let :signature, do: "a{is}a{bu}"

            it "returns a list of atoms and tuples of appropriate types" do
              expect(described_module.type_from_signature(signature)).to eq {:ok, [{:array, [{:dict, [:int32, :string]}]}, {:array, [{:dict, [:boolean, :uint32]}]}]}
            end
          end

          context "if it is suffixed by other dicts" do
            let :signature, do: "a{bu}a{is}"

            it "returns a list of atoms and tuples of appropriate types" do
              expect(described_module.type_from_signature(signature)).to eq {:ok, [{:array, [{:dict, [:boolean, :uint32]}]}, {:array, [{:dict, [:int32, :string]}]}]}
            end
          end


          context "if it is nested" do
            let :signature, do: "h(bua{ds}i)(o)"

            it "returns a list of atoms and tuples of appropriate types" do
              expect(described_module.type_from_signature(signature)).to eq {:ok, [
                :unix_fd,
                {:struct, [
                  :boolean,
                  :uint32,
                  {:array, [
                    {:dict, [:double, :string]},
                  ]},
                  :int32
                ]},
                {:struct, [:object_path]}
              ]}
            end
          end
        end
      end
    end


    context "for signature containing arrays" do
      context "for array with no type" do
        let :signature, do: "a"

        it "should return {:error, {:badsignature, :emptyarray}}" do
          expect(described_module.type_from_signature(signature)).to eq {:error, {:badsignature, :emptyarray}}
        end
      end

      context "for signature containing only one struct with simple types inside" do
        context "if it is not prefixed or suffixed by any other values" do
          let :signature, do: "ai"

          it "returns a list of atoms and tuples of appropriate types" do
            expect(described_module.type_from_signature(signature)).to eq {:ok, [{:array, [:int32]}]}
          end
        end

        context "if it is prefixed by other simple values" do
          let :signature, do: "iai"

          it "returns a list of atoms and tuples of appropriate types" do
            expect(described_module.type_from_signature(signature)).to eq {:ok, [:int32, {:array, [:int32]}]}
          end
        end

        context "if it is suffixed by other simple values" do
          let :signature, do: "aiu"

          it "returns a list of atoms and tuples of appropriate types" do
            expect(described_module.type_from_signature(signature)).to eq {:ok, [{:array, [:int32]}, :uint32]}
          end
        end

        context "if it is both prefixed suffixed by other simple values" do
          let :signature, do: "haiu"

          it "returns a list of atoms and tuples of appropriate types" do
            expect(described_module.type_from_signature(signature)).to eq {:ok, [:unix_fd, {:array, [:int32]}, :uint32]}
          end
        end
      end

      context "for signature containing only one struct with container types inside" do
        context "if it is not prefixed or suffixed by any other values" do
          let :signature, do: "a(i)"

          it "returns a list of atoms and tuples of appropriate types" do
            expect(described_module.type_from_signature(signature)).to eq {:ok, [{:array, [{:struct, [:int32]}]}]}
          end
        end
      end

      context "for signature containing array in array" do
        context "if it is not prefixed or suffixed by any other values" do
          let :signature, do: "aai"

          it "returns a list of atoms and tuples of appropriate types" do
            expect(described_module.type_from_signature(signature)).to eq {:ok, [{:array, [{:array, [:int32]}]}]}
          end
        end
      end

      context "for signature containing dict in array" do
        context "if it is not prefixed or suffixed by any other values" do
          let :signature, do: "a{ss}"

          it "returns a list of atoms and tuples of appropriate types" do
            expect(described_module.type_from_signature(signature)).to eq {:ok, [{:array, [{:dict, [:string, :string]}]}]}
          end
        end
      end

      context "for signature containing dict with struct in array" do
        context "if it is not prefixed or suffixed by any other values" do
          let :signature, do: "a{s(is)}"

          it "returns a list of atoms and tuples of appropriate types" do
            expect(described_module.type_from_signature(signature)).to eq {:ok, [{:array, [{:dict, [:string, {:struct, [:int32, :string]}]}]}]}
          end
        end
      end
    end
  end
end
