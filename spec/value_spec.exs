defmodule DBux.ValueSpec do
  use ESpec

  context ".marshall/1" do
    let :result, do: DBux.Value.marshall(%DBux.Value{type: type, value: value}, endianness)

    context "if passed 'byte' value" do
      let :type, do: :byte
      let :endianness, do: :little_endian

      context "that is valid" do
        context "and represented as 1-char long string" do
          let :value, do: "x"

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
          let :value, do: 150

          it "should return a bitstring" do
            expect(result).to be_bitstring
          end

          it "should return 1-byte long bitstring" do
            expect(byte_size(result)).to eq 1
          end

          it "should return bitstring containing passed integer" do
            expect(result).to eq << 150 >>
          end
        end
      end

      context "that is invalid" do
        context "and represented as a string" do
          context "but value is blank" do
            let :value, do: ""

            it "throws {:badarg, :value, :outofrange}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :outofrange})
            end
          end

          context "but value has more than 1 character" do
            let :value, do: "ab"

            it "throws {:badarg, :value, :outofrange}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :outofrange})
            end
          end
        end

        context "and represented as an integer" do
          context "but value is smaller than 0" do
            let :value, do: -1

            it "throws {:badarg, :value, :outofrange}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :outofrange})
            end
          end

          context "but value is larger than 255" do
            let :value, do: 256

            it "throws {:badarg, :value, :outofrange}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :outofrange})
            end
          end
        end
      end
    end


    context "if passed 'boolean' value" do
      let :type, do: :boolean

      context "that is valid" do
        context "and represented as boolean" do
          context "equal to true" do
            let :value, do: true

            context "and endianness is little-endian" do
              let :endianness, do: :little_endian

              it "should return a bitstring" do
                expect(result).to be_bitstring
              end

              it "should return 4-byte long bitstring" do
                expect(byte_size(result)).to eq 4
              end

              it "should return bitstring equal to 1 marshalled as uint32" do
                expect(result).to eq <<1, 0, 0, 0>>
              end
            end

            context "and endianness is big-endian" do
              let :endianness, do: :big_endian

              it "should return a bitstring" do
                expect(result).to be_bitstring
              end

              it "should return 4-byte long bitstring" do
                expect(byte_size(result)).to eq 4
              end

              it "should return bitstring equal to 1 marshalled as uint32" do
                expect(result).to eq <<0, 0, 0, 1>>
              end
            end
          end
        end
      end
    end


    context "if passed 'int16' value" do
      let :type, do: :int16

      context "that is valid" do
        context "and represented as integer" do
          let :value, do: -0x3E8

          context "and endianness is little-endian" do
            let :endianness, do: :little_endian

            it "should return a bitstring" do
              expect(result).to be_bitstring
            end

            it "should return 2-byte long bitstring" do
              expect(byte_size(result)).to eq 2
            end

            it "should return bitstring containing its little-endian representation" do
              expect(result).to eq <<value :: size(2)-unit(8)-signed-little >>
            end
          end

          context "and endianness is big-endian" do
            let :endianness, do: :big_endian

            it "should return a bitstring" do
              expect(result).to be_bitstring
            end

            it "should return 2-byte long bitstring" do
              expect(byte_size(result)).to eq 2
            end

            it "should return bitstring containing its big-endian representation" do
              expect(result).to eq <<value :: size(2)-unit(8)-signed-big >>
            end
          end
        end
      end

      context "that is invalid" do
        context "and represented as integer" do
          context "but value is smaller than -0x8000" do
            let :value, do: -0x8000 - 1

            it "throws {:badarg, :value, :outofrange}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :outofrange})
            end
          end

          context "but value is larger than 0x7FFF" do
            let :value, do: 0x7FFF + 1

            it "throws {:badarg, :value, :outofrange}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :outofrange})
            end
          end
        end
      end
    end


    context "if passed 'uint16' value" do
      let :type, do: :uint16

      context "that is valid" do
        context "and represented as integer" do
          let :value, do: 0xABCD

          context "and endianness is little-endian" do
            let :endianness, do: :little_endian

            it "should return a bitstring" do
              expect(result).to be_bitstring
            end

            it "should return 2-byte long bitstring" do
              expect(byte_size(result)).to eq 2
            end

            it "should return bitstring containing its little-endian representation" do
              expect(result).to eq <<value :: size(2)-unit(8)-unsigned-little >>
            end
          end

          context "and endianness is big-endian" do
            let :endianness, do: :big_endian

            it "should return a bitstring" do
              expect(result).to be_bitstring
            end

            it "should return 2-byte long bitstring" do
              expect(byte_size(result)).to eq 2
            end

            it "should return bitstring containing its big-endian representation" do
              expect(result).to eq <<value :: size(2)-unit(8)-unsigned-big >>
            end
          end
        end
      end

      context "that is invalid" do
        context "and represented as integer" do
          context "but value is smaller than 0" do
            let :value, do: -1

            it "throws {:badarg, :value, :outofrange}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :outofrange})
            end
          end

          context "but value is larger than 0xFFFF" do
            let :value, do: 0xFFFF + 1

            it "throws {:badarg, :value, :outofrange}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :outofrange})
            end
          end
        end
      end
    end


    context "if passed 'int32' value" do
      let :type, do: :int32

      context "that is valid" do
        context "and represented as integer" do
          let :value, do: -0x12345678

          context "and endianness is little-endian" do
            let :endianness, do: :little_endian

            it "should return a bitstring" do
              expect(result).to be_bitstring
            end

            it "should return 4-byte long bitstring" do
              expect(byte_size(result)).to eq 4
            end

            it "should return bitstring containing its little-endian representation" do
              expect(result).to eq <<value :: size(4)-unit(8)-signed-little >>
            end
          end

          context "and endianness is big-endian" do
            let :endianness, do: :big_endian

            it "should return a bitstring" do
              expect(result).to be_bitstring
            end

            it "should return 4-byte long bitstring" do
              expect(byte_size(result)).to eq 4
            end

            it "should return bitstring containing its big-endian representation" do
              expect(result).to eq <<value :: size(4)-unit(8)-signed-big >>
            end
          end
        end
      end

      context "that is invalid" do
        context "and represented as integer" do
          context "but value is smaller than -0x80000000" do
            let :value, do: -0x80000000 - 1

            it "throws {:badarg, :value, :outofrange}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :outofrange})
            end
          end

          context "but value is larger than 0x7FFFFFFF" do
            let :value, do: 0x7FFFFFFF + 1

            it "throws {:badarg, :value, :outofrange}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :outofrange})
            end
          end
        end
      end
    end


    context "if passed 'uint32' value" do
      let :type, do: :uint32

      context "that is valid" do
        context "and represented as integer" do
          let :value, do: 85555

          context "and endianness is little-endian" do
            let :endianness, do: :little_endian

            it "should return a bitstring" do
              expect(result).to be_bitstring
            end

            it "should return 4-byte long bitstring" do
              expect(byte_size(result)).to eq 4
            end

            it "should return bitstring containing its little-endian representation" do
              expect(result).to eq <<value :: size(4)-unit(8)-unsigned-little >>
            end
          end

          context "and endianness is big-endian" do
            let :endianness, do: :big_endian

            it "should return a bitstring" do
              expect(result).to be_bitstring
            end

            it "should return 4-byte long bitstring" do
              expect(byte_size(result)).to eq 4
            end

            it "should return bitstring containing its big-endian representation" do
              expect(result).to eq <<value :: size(4)-unit(8)-unsigned-big >>
            end
          end
        end
      end

      context "that is invalid" do
        context "and represented as integer" do
          context "but value is smaller than 0" do
            let :value, do: -1

            it "throws {:badarg, :value, :outofrange}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :outofrange})
            end
          end

          context "but value is larger than 0xFFFFFFFF" do
            let :value, do: 0xFFFFFFFF + 1

            it "throws {:badarg, :value, :outofrange}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :outofrange})
            end
          end
        end
      end
    end


    context "if passed 'int64' value" do
      let :type, do: :int64

      context "that is valid" do
        context "and represented as integer" do
          let :value, do: -0x1234567890ABCDEF

          context "and endianness is little-endian" do
            let :endianness, do: :little_endian

            it "should return a bitstring" do
              expect(result).to be_bitstring
            end

            it "should return 8-byte long bitstring" do
              expect(byte_size(result)).to eq 8
            end

            it "should return bitstring containing its little-endian representation" do
              expect(result).to eq <<value :: size(8)-unit(8)-signed-little >>
            end
          end

          context "and endianness is big-endian" do
            let :endianness, do: :big_endian

            it "should return a bitstring" do
              expect(result).to be_bitstring
            end

            it "should return 8-byte long bitstring" do
              expect(byte_size(result)).to eq 8
            end

            it "should return bitstring containing its big-endian representation" do
              expect(result).to eq <<value :: size(8)-unit(8)-signed-big >>
            end
          end
        end
      end

      context "that is invalid" do
        context "and represented as integer" do
          context "but value is smaller than -0x8000000000000000" do
            let :value, do: -0x8000000000000000 - 1

            it "throws {:badarg, :value, :outofrange}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :outofrange})
            end
          end

          context "but value is larger than 0x7FFFFFFFFFFFFFFF" do
            let :value, do: 0x7FFFFFFFFFFFFFFF + 1

            it "throws {:badarg, :value, :outofrange}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :outofrange})
            end
          end
        end
      end
    end


    context "if passed 'uint64' value" do
      let :type, do: :uint64

      context "that is valid" do
        context "and represented as integer" do
          let :value, do: 0xABCDEF0123456789

          context "and endianness is little-endian" do
            let :endianness, do: :little_endian

            it "should return a bitstring" do
              expect(result).to be_bitstring
            end

            it "should return 8-byte long bitstring" do
              expect(byte_size(result)).to eq 8
            end

            it "should return bitstring containing its little-endian representation" do
              expect(result).to eq <<value :: size(8)-unit(8)-unsigned-little >>
            end
          end

          context "and endianness is big-endian" do
            let :endianness, do: :big_endian

            it "should return a bitstring" do
              expect(result).to be_bitstring
            end

            it "should return 8-byte long bitstring" do
              expect(byte_size(result)).to eq 8
            end

            it "should return bitstring containing its big-endian representation" do
              expect(result).to eq <<value :: size(8)-unit(8)-unsigned-big >>
            end
          end
        end
      end

      context "that is invalid" do
        context "and represented as integer" do
          context "but value is smaller than 0" do
            let :value, do: -1

            it "throws {:badarg, :value, :outofrange}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :outofrange})
            end
          end

          context "but value is larger than 0xFFFFFFFFFFFFFFFF" do
            let :value, do: 0xFFFFFFFFFFFFFFFF + 1

            it "throws {:badarg, :value, :outofrange}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :outofrange})
            end
          end
        end
      end
    end
  end
end
