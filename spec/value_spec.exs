defmodule DBux.ValueSpec do
  use ESpec

  context ".marshall/1" do
    let :result, do: DBux.Value.marshall(value)

    context "if passed 'byte' value" do
      let :type, do: :byte

      context "that is valid" do
        context "and represented as 1-char long string" do
          let :value, do: %DBux.Value{type: type, value: "x"}

          it "should return a bitstring" do
            expect(result).to be_bitstring
          end

          it "should return 1-byte long bitstring" do
            expect(byte_size(result)).to eq 1
          end

          it "should return bitstring containing its ASCII representation" do
            expect(result).to eq << 120 >>
          end
        end

        context "and represented as integer" do
          let :value, do: %DBux.Value{type: type, value: 150}

          it "should return a bitstring" do
            expect(result).to be_bitstring
          end

          it "should return 1-byte long bitstring" do
            expect(byte_size(result)).to eq 1
          end

          it "should return bitstring containing its ASCII representation" do
            expect(result).to eq << 150 >>
          end
        end
      end

      context "that is invalid" do
        context "and represented as a string" do
          context "but value is blank" do
            let :value, do: %DBux.Value{type: type, value: ""}

            it "throws {:badarg, :value, :outofrange}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :outofrange})
            end
          end

          context "but value has more than 1 character" do
            let :value, do: %DBux.Value{type: type, value: "ab"}

            it "throws {:badarg, :value, :outofrange}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :outofrange})
            end
          end
        end

        context "and represented as an integer" do
          context "but value is smaller than 0" do
            let :value, do: %DBux.Value{type: type, value: -1}

            it "throws {:badarg, :value, :outofrange}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :outofrange})
            end
          end

          context "but value is larger than 255" do
            let :value, do: %DBux.Value{type: type, value: 256}

            it "throws {:badarg, :value, :outofrange}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :outofrange})
            end
          end
        end
      end
    end
  end
end
