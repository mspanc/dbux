defmodule DBux.ValueSpec do
  use ESpec, async: false

  context ".marshall/2" do
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


    context "if passed 'double' value" do
      let :type, do: :double

      context "that is valid" do
        context "and represented as float" do
          let :value, do: 312321321321.1312321321

          context "and endianness is little-endian" do
            let :endianness, do: :little_endian

            it "should return a bitstring" do
              expect(result).to be_bitstring
            end

            it "should return 8-byte long bitstring" do
              expect(byte_size(result)).to eq 8
            end

            it "should return bitstring containing its little-endian representation" do
              expect(result).to eq <<value :: float-size(8)-unit(8)-little >>
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
              expect(result).to eq <<value :: float-size(8)-unit(8)-big >>
            end
          end
        end
      end
    end


    context "if passed 'string' value" do
      let :type, do: :string

      context "that is valid" do
        context "and represented as string" do
          let :value, do: "abcdłóż"

          context "and endianness is little-endian" do
            let :endianness, do: :little_endian

            it "should return a bitstring" do
              expect(result).to be_bitstring
            end

            it "should return bitstring that uses appropriate length for storing UTF-8 characters plus 4-byte length plus NUL terminator" do
              expect(byte_size(result)).to eq byte_size(<< value :: binary-unit(8)-little >>) + 4 + 1
            end

            it "should return bitstring containing its byte length (including NUL terminator) stored as uint32 plus little-endian representation plus NUL terminator" do
              expect(result).to eq(<< byte_size(value) + 1 :: unit(8)-size(4)-unsigned-little >> <> << value :: binary-unit(8)-little >> <> << 0 >>)
            end
          end

          context "and endianness is big-endian" do
            let :endianness, do: :big_endian

            it "should return a bitstring" do
              expect(result).to be_bitstring
            end

            it "should return bitstring that uses appropriate length for storing UTF-8 characters plus 4-byte length plus NUL terminator" do
              expect(byte_size(result)).to eq byte_size(<< value :: binary-unit(8)-big >>) + 4 + 1
            end

            it "should return bitstring containing its byte length (including NUL terminator) stored as uint32 plus big-endian representation plus NUL terminator" do
              expect(result).to eq(<< byte_size(value) + 1 :: unit(8)-size(4)-unsigned-big >> <> << value :: binary-unit(8)-big >> <> << 0 >>)
            end
          end
        end
      end

      context "that is invalid" do
        context "and represented as string" do
          context "but value contains null bytes" do
            let :value, do: "ABC" <> << 0 >> <> "DEF"

            it "throws {:badarg, :value, :invalid}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :invalid})
            end
          end

          # FIXME this does not work
          xcontext "but value's byte representation is longer than 0xFFFFFFFE" do
            before do
              allow(Kernel).to accept(:byte_size, fn(_) -> 0xFFFFFFFE + 1 end)
            end

            let :value, do: "anything as we mock String.length because generating string that is so long kills the VM"

            it "throws {:badarg, :value, :outofrange}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :outofrange})
              expect(Kernel).to accepted(:byte_size, [value])
            end
          end
        end
      end
    end


    context "if passed 'object_path' value" do
      let :type, do: :object_path

      context "that is valid" do
        context "and represented as string" do
          let :value, do: "/com/example/MusicPlayer1"

          context "and endianness is little-endian" do
            let :endianness, do: :little_endian

            it "should return a bitstring" do
              expect(result).to be_bitstring
            end

            it "should return bitstring that uses appropriate length for storing UTF-8 characters plus 4-byte length plus NUL terminator" do
              expect(byte_size(result)).to eq byte_size(<< value :: binary-unit(8)-little >>) + 4 + 1
            end

            it "should return bitstring containing its byte length (including NUL terminator) stored as uint32 plus little-endian representation plus NUL terminator" do
              expect(result).to eq(<< byte_size(value) + 1 :: unit(8)-size(4)-unsigned-little >> <> << value :: binary-unit(8)-little >> <> << 0 >>)
            end
          end

          context "and endianness is big-endian" do
            let :endianness, do: :big_endian

            it "should return a bitstring" do
              expect(result).to be_bitstring
            end

            it "should return bitstring that uses appropriate length for storing UTF-8 characters plus 4-byte length plus NUL terminator" do
              expect(byte_size(result)).to eq byte_size(<< value :: binary-unit(8)-big >>) + 4 + 1
            end

            it "should return bitstring containing its byte length (including NUL terminator) stored as uint32 plus big-endian representation plus NUL terminator" do
              expect(result).to eq(<< byte_size(value) + 1 :: unit(8)-size(4)-unsigned-big >> <> << value :: binary-unit(8)-big >> <> << 0 >>)
            end
          end
        end
      end

      context "that is invalid" do
        context "and represented as string" do
          context "but value contains null bytes" do
            let :value, do: "ABC" <> << 0 >> <> "DEF"

            it "throws {:badarg, :value, :invalid}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :invalid})
            end
          end

          # FIXME this does not work
          xcontext "but value's byte representation is longer than 0xFFFFFFFE" do
            before do
              allow(Kernel).to accept(:byte_size, fn(_) -> 0xFFFFFFFE + 1 end)
            end

            let :value, do: "anything as we mock String.length because generating string that is so long kills the VM"

            it "throws {:badarg, :value, :outofrange}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :outofrange})
              expect(Kernel).to accepted(:byte_size, [value])
            end
          end

          pending "but value contains object path of invalid syntax"
        end
      end
    end


    context "if passed 'signature' value" do
      let :type, do: :signature

      context "that is valid" do
        context "and represented as string" do
          let :value, do: "yyyyuua(yv)"

          context "and endianness is little-endian" do
            let :endianness, do: :little_endian

            it "should return a bitstring" do
              expect(result).to be_bitstring
            end

            it "should return bitstring that uses appropriate length for storing UTF-8 characters plus 1-byte length plus NUL terminator" do
              expect(byte_size(result)).to eq byte_size(<< value :: binary-unit(8)-little >>) + 1 + 1
            end

            it "should return bitstring containing its byte length (including NUL terminator) stored as uint32 plus little-endian representation plus NUL terminator" do
              expect(result).to eq(<< byte_size(value) + 1 :: unit(8)-size(1)-unsigned-little >> <> << value :: binary-unit(8)-little >> <> << 0 >>)
            end
          end

          context "and endianness is big-endian" do
            let :endianness, do: :big_endian

            it "should return a bitstring" do
              expect(result).to be_bitstring
            end

            it "should return bitstring that uses appropriate length for storing UTF-8 characters plus 1-byte length plus NUL terminator" do
              expect(byte_size(result)).to eq byte_size(<< value :: binary-unit(8)-big >>) + 1 + 1
            end

            it "should return bitstring containing its byte length (including NUL terminator) stored as uint32 plus big-endian representation plus NUL terminator" do
              expect(result).to eq(<< byte_size(value) + 1 :: unit(8)-size(1)-unsigned-big >> <> << value :: binary-unit(8)-big >> <> << 0 >>)
            end
          end
        end
      end

      context "that is invalid" do
        context "and represented as string" do
          context "but value contains null bytes" do
            let :value, do: "ABC" <> << 0 >> <> "DEF"

            it "throws {:badarg, :value, :invalid}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :invalid})
            end
          end

          context "but value's byte representation is longer than 0xFE" do
            let :value, do: String.duplicate("i", 0xFE + 1)

            it "throws {:badarg, :value, :outofrange}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :outofrange})
            end
          end

          pending "but value contains signature of invalid syntax"
        end
      end
    end
  end
end
