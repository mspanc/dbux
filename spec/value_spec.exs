defmodule DBux.ValueSpec do
  use ESpec, async: false

  describe ".marshall/2" do
    let :result, do: DBux.Value.marshall(%DBux.Value{type: type, value: value}, endianness)

    context "if passed 'byte' value" do
      let :type, do: :byte
      let :endianness, do: :little_endian

      context "that is valid" do
        context "and represented as 1-char long string" do
          let :value, do: "x"

          it "should return a tuple of format {:ok, bitstring, padding_size}" do
            expect(result).to be_tuple

            {status, {bitstring, padding_size}} = result
            expect(status).to eq :ok
            expect(bitstring).to be_bitstring
            expect(padding_size).to be_number
          end

          it "should return 1-byte long bitstring" do
            {:ok, {bitstring, _}} = result
            expect(byte_size(bitstring)).to eq 1
          end

          it "should return bitstring containing its ASCII representation" do
            {:ok, {bitstring, _}} = result
            expect(bitstring).to eq << 120 >>
          end

          it "should return padding set to 0" do
            {:ok, {_, padding}} = result
            expect(padding).to eq 0
          end
        end

        context "and represented as integer" do
          let :value, do: 150

          it "should return a tuple of format {:ok, bitstring, padding_size}" do
            expect(result).to be_tuple

            {status, {bitstring, padding_size}} = result
            expect(status).to eq :ok
            expect(bitstring).to be_bitstring
            expect(padding_size).to be_number
          end

          it "should return 1-byte long bitstring" do
            {:ok, {bitstring, _}} = result
            expect(byte_size(bitstring)).to eq 1
          end

          it "should return bitstring containing passed integer" do
            {:ok, {bitstring, _}} = result
            expect(bitstring).to eq << 150 >>
          end

          it "should return padding set to 0" do
            {:ok, {_, padding}} = result
            expect(padding).to eq 0
          end
        end
      end

      context "that is invalid" do
        let :endianness, do: :little_endian

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

              it "should return a tuple of format {:ok, bitstring, padding_size}" do
                expect(result).to be_tuple

                {status, {bitstring, padding_size}} = result
                expect(status).to eq :ok
                expect(bitstring).to be_bitstring
                expect(padding_size).to be_number
              end

              it "should return 4-byte long bitstring" do
                {:ok, {bitstring, _}} = result
                expect(byte_size(bitstring)).to eq 4
              end

              it "should return bitstring equal to 1 marshalled as uint32" do
                {:ok, {bitstring, _}} = result
                expect(bitstring).to eq <<1, 0, 0, 0>>
              end

              it "should return padding set to 0" do
                {:ok, {_, padding}} = result
                expect(padding).to eq 0
              end
            end

            context "and endianness is big-endian" do
              let :endianness, do: :big_endian

              it "should return a tuple of format {:ok, bitstring, padding_size}" do
                expect(result).to be_tuple

                {status, {bitstring, padding_size}} = result
                expect(status).to eq :ok
                expect(bitstring).to be_bitstring
                expect(padding_size).to be_number
              end

              it "should return 4-byte long bitstring" do
                {:ok, {bitstring, _}} = result
                expect(byte_size(bitstring)).to eq 4
              end

              it "should return bitstring equal to 1 marshalled as uint32" do
                {:ok, {bitstring, _}} = result
                expect(bitstring).to eq <<0, 0, 0, 1>>
              end

              it "should return padding set to 0" do
                {:ok, {_, padding}} = result
                expect(padding).to eq 0
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

            it "should return a tuple of format {:ok, bitstring, padding_size}" do
              expect(result).to be_tuple

              {status, {bitstring, padding_size}} = result
              expect(status).to eq :ok
              expect(bitstring).to be_bitstring
              expect(padding_size).to be_number
            end

            it "should return 2-byte long bitstring" do
              {:ok, {bitstring, _}} = result
              expect(byte_size(bitstring)).to eq 2
            end

            it "should return bitstring containing its little-endian representation" do
              {:ok, {bitstring, _}} = result
              expect(bitstring).to eq <<value :: size(2)-unit(8)-signed-little >>
            end

            it "should return padding set to 0" do
              {:ok, {_, padding}} = result
              expect(padding).to eq 0
            end
          end

          context "and endianness is big-endian" do
            let :endianness, do: :big_endian

            it "should return a tuple of format {:ok, bitstring, padding_size}" do
              expect(result).to be_tuple

              {status, {bitstring, padding_size}} = result
              expect(status).to eq :ok
              expect(bitstring).to be_bitstring
              expect(padding_size).to be_number
            end

            it "should return 2-byte long bitstring" do
              {:ok, {bitstring, _}} = result
              expect(byte_size(bitstring)).to eq 2
            end

            it "should return bitstring containing its big-endian representation" do
              {:ok, {bitstring, _}} = result
              expect(bitstring).to eq <<value :: size(2)-unit(8)-signed-big >>
            end

            it "should return padding set to 0" do
              {:ok, {_, padding}} = result
              expect(padding).to eq 0
            end
          end
        end
      end

      context "that is invalid" do
        let :endianness, do: :little_endian

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

            it "should return a tuple of format {:ok, bitstring, padding_size}" do
              expect(result).to be_tuple

              {status, {bitstring, padding_size}} = result
              expect(status).to eq :ok
              expect(bitstring).to be_bitstring
              expect(padding_size).to be_number
            end

            it "should return 2-byte long bitstring" do
              {:ok, {bitstring, _}} = result
              expect(byte_size(bitstring)).to eq 2
            end

            it "should return bitstring containing its little-endian representation" do
              {:ok, {bitstring, _}} = result
              expect(bitstring).to eq <<value :: size(2)-unit(8)-unsigned-little >>
            end

            it "should return padding set to 0" do
              {:ok, {_, padding}} = result
              expect(padding).to eq 0
            end
          end

          context "and endianness is big-endian" do
            let :endianness, do: :big_endian

            it "should return a tuple of format {:ok, bitstring, padding_size}" do
              expect(result).to be_tuple

              {status, {bitstring, padding_size}} = result
              expect(status).to eq :ok
              expect(bitstring).to be_bitstring
              expect(padding_size).to be_number
            end

            it "should return 2-byte long bitstring" do
              {:ok, {bitstring, _}} = result
              expect(byte_size(bitstring)).to eq 2
            end

            it "should return bitstring containing its big-endian representation" do
              {:ok, {bitstring, _}} = result
              expect(bitstring).to eq <<value :: size(2)-unit(8)-unsigned-big >>
            end

            it "should return padding set to 0" do
              {:ok, {_, padding}} = result
              expect(padding).to eq 0
            end
          end
        end
      end

      context "that is invalid" do
        let :endianness, do: :little_endian

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

            it "should return a tuple of format {:ok, bitstring, padding_size}" do
              expect(result).to be_tuple

              {status, {bitstring, padding_size}} = result
              expect(status).to eq :ok
              expect(bitstring).to be_bitstring
              expect(padding_size).to be_number
            end

            it "should return 4-byte long bitstring" do
              {:ok, {bitstring, _}} = result
              expect(byte_size(bitstring)).to eq 4
            end

            it "should return bitstring containing its little-endian representation" do
              {:ok, {bitstring, _}} = result
              expect(bitstring).to eq <<value :: size(4)-unit(8)-signed-little >>
            end

            it "should return padding set to 0" do
              {:ok, {_, padding}} = result
              expect(padding).to eq 0
            end
          end

          context "and endianness is big-endian" do
            let :endianness, do: :big_endian

            it "should return a tuple of format {:ok, bitstring, padding_size}" do
              expect(result).to be_tuple

              {status, {bitstring, padding_size}} = result
              expect(status).to eq :ok
              expect(bitstring).to be_bitstring
              expect(padding_size).to be_number
            end

            it "should return 4-byte long bitstring" do
              {:ok, {bitstring, _}} = result
              expect(byte_size(bitstring)).to eq 4
            end

            it "should return bitstring containing its big-endian representation" do
              {:ok, {bitstring, _}} = result
              expect(bitstring).to eq <<value :: size(4)-unit(8)-signed-big >>
            end

            it "should return padding set to 0" do
              {:ok, {_, padding}} = result
              expect(padding).to eq 0
            end
          end
        end
      end

      context "that is invalid" do
        let :endianness, do: :little_endian

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

            it "should return a tuple of format {:ok, bitstring, padding_size}" do
              expect(result).to be_tuple

              {status, {bitstring, padding_size}} = result
              expect(status).to eq :ok
              expect(bitstring).to be_bitstring
              expect(padding_size).to be_number
            end

            it "should return 4-byte long bitstring" do
              {:ok, {bitstring, _}} = result
              expect(byte_size(bitstring)).to eq 4
            end

            it "should return bitstring containing its little-endian representation" do
              {:ok, {bitstring, _}} = result
              expect(bitstring).to eq <<value :: size(4)-unit(8)-unsigned-little >>
            end

            it "should return padding set to 0" do
              {:ok, {_, padding}} = result
              expect(padding).to eq 0
            end
          end

          context "and endianness is big-endian" do
            let :endianness, do: :big_endian

            it "should return a tuple of format {:ok, bitstring, padding_size}" do
              expect(result).to be_tuple

              {status, {bitstring, padding_size}} = result
              expect(status).to eq :ok
              expect(bitstring).to be_bitstring
              expect(padding_size).to be_number
            end

            it "should return 4-byte long bitstring" do
              {:ok, {bitstring, _}} = result
              expect(byte_size(bitstring)).to eq 4
            end

            it "should return bitstring containing its big-endian representation" do
              {:ok, {bitstring, _}} = result
              expect(bitstring).to eq <<value :: size(4)-unit(8)-unsigned-big >>
            end

            it "should return padding set to 0" do
              {:ok, {_, padding}} = result
              expect(padding).to eq 0
            end
          end
        end
      end

      context "that is invalid" do
        let :endianness, do: :little_endian

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

            it "should return a tuple of format {:ok, bitstring, padding_size}" do
              expect(result).to be_tuple

              {status, {bitstring, padding_size}} = result
              expect(status).to eq :ok
              expect(bitstring).to be_bitstring
              expect(padding_size).to be_number
            end

            it "should return 8-byte long bitstring" do
              {:ok, {bitstring, _}} = result
              expect(byte_size(bitstring)).to eq 8
            end

            it "should return bitstring containing its little-endian representation" do
              {:ok, {bitstring, _}} = result
              expect(bitstring).to eq <<value :: size(8)-unit(8)-signed-little >>
            end

            it "should return padding set to 0" do
              {:ok, {_, padding}} = result
              expect(padding).to eq 0
            end
          end

          context "and endianness is big-endian" do
            let :endianness, do: :big_endian

            it "should return a tuple of format {:ok, bitstring, padding_size}" do
              expect(result).to be_tuple

              {status, {bitstring, padding_size}} = result
              expect(status).to eq :ok
              expect(bitstring).to be_bitstring
              expect(padding_size).to be_number
            end

            it "should return 8-byte long bitstring" do
              {:ok, {bitstring, _}} = result
              expect(byte_size(bitstring)).to eq 8
            end

            it "should return bitstring containing its big-endian representation" do
              {:ok, {bitstring, _}} = result
              expect(bitstring).to eq <<value :: size(8)-unit(8)-signed-big >>
            end

            it "should return padding set to 0" do
              {:ok, {_, padding}} = result
              expect(padding).to eq 0
            end
          end
        end
      end

      context "that is invalid" do
        let :endianness, do: :little_endian

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

            it "should return a tuple of format {:ok, bitstring, padding_size}" do
              expect(result).to be_tuple

              {status, {bitstring, padding_size}} = result
              expect(status).to eq :ok
              expect(bitstring).to be_bitstring
              expect(padding_size).to be_number
            end

            it "should return 8-byte long bitstring" do
              {:ok, {bitstring, _}} = result
              expect(byte_size(bitstring)).to eq 8
            end

            it "should return bitstring containing its little-endian representation" do
              {:ok, {bitstring, _}} = result
              expect(bitstring).to eq <<value :: size(8)-unit(8)-unsigned-little >>
            end

            it "should return padding set to 0" do
              {:ok, {_, padding}} = result
              expect(padding).to eq 0
            end
          end

          context "and endianness is big-endian" do
            let :endianness, do: :big_endian

            it "should return a tuple of format {:ok, bitstring, padding_size}" do
              expect(result).to be_tuple

              {status, {bitstring, padding_size}} = result
              expect(status).to eq :ok
              expect(bitstring).to be_bitstring
              expect(padding_size).to be_number
            end

            it "should return 8-byte long bitstring" do
              {:ok, {bitstring, _}} = result
              expect(byte_size(bitstring)).to eq 8
            end

            it "should return bitstring containing its big-endian representation" do
              {:ok, {bitstring, _}} = result
              expect(bitstring).to eq <<value :: size(8)-unit(8)-unsigned-big >>
            end

            it "should return padding set to 0" do
              {:ok, {_, padding}} = result
              expect(padding).to eq 0
            end
          end
        end
      end

      context "that is invalid" do
        let :endianness, do: :little_endian

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

            it "should return a tuple of format {:ok, bitstring, padding_size}" do
              expect(result).to be_tuple

              {status, {bitstring, padding_size}} = result
              expect(status).to eq :ok
              expect(bitstring).to be_bitstring
              expect(padding_size).to be_number
            end

            it "should return 8-byte long bitstring" do
              {:ok, {bitstring, _}} = result
              expect(byte_size(bitstring)).to eq 8
            end

            it "should return bitstring containing its little-endian representation" do
              {:ok, {bitstring, _}} = result
              expect(bitstring).to eq <<value :: float-size(8)-unit(8)-little >>
            end

            it "should return padding set to 0" do
              {:ok, {_, padding}} = result
              expect(padding).to eq 0
            end
          end

          context "and endianness is big-endian" do
            let :endianness, do: :big_endian

            it "should return a tuple of format {:ok, bitstring, padding_size}" do
              expect(result).to be_tuple

              {status, {bitstring, padding_size}} = result
              expect(status).to eq :ok
              expect(bitstring).to be_bitstring
              expect(padding_size).to be_number
            end

            it "should return 8-byte long bitstring" do
              {:ok, {bitstring, _}} = result
              expect(byte_size(bitstring)).to eq 8
            end

            it "should return bitstring containing its big-endian representation" do
              {:ok, {bitstring, _}} = result
              expect(bitstring).to eq <<value :: float-size(8)-unit(8)-big >>
            end

            it "should return padding set to 0" do
              {:ok, {_, padding}} = result
              expect(padding).to eq 0
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

            it "should return a tuple of format {:ok, bitstring, padding_size}" do
              expect(result).to be_tuple

              {status, {bitstring, padding_size}} = result
              expect(status).to eq :ok
              expect(bitstring).to be_bitstring
              expect(padding_size).to be_number
            end

            it "should return bitstring that uses appropriate length for storing UTF-8 characters plus 4-byte length plus NUL terminator" do
              {:ok, {bitstring, _}} = result
              expect(byte_size(bitstring)).to eq 15
            end

            it "should return bitstring containing its byte length (excluding NUL terminator) stored as uint32 plus little-endian representation plus NUL terminator" do
              {:ok, {bitstring, _}} = result
              expect(bitstring).to eq(<<10, 0, 0, 0, 97, 98, 99, 100, 197, 130, 195, 179, 197, 188, 0>>)
            end

            it "should return padding set to 0" do
              {:ok, {_, padding}} = result
              expect(padding).to eq 0
            end
          end

          context "and endianness is big-endian" do
            let :endianness, do: :big_endian

            it "should return a tuple of format {:ok, bitstring, padding_size}" do
              expect(result).to be_tuple

              {status, {bitstring, padding_size}} = result
              expect(status).to eq :ok
              expect(bitstring).to be_bitstring
              expect(padding_size).to be_number
            end

            it "should return bitstring that uses appropriate length for storing UTF-8 characters plus 4-byte length plus NUL terminator" do
              {:ok, {bitstring, _}} = result
              expect(byte_size(bitstring)).to eq 15
            end

            it "should return bitstring containing its byte length (excluding NUL terminator) stored as uint32 plus little-endian representation plus NUL terminator" do
              {:ok, {bitstring, _}} = result
              expect(bitstring).to eq(<<0, 0, 0, 10, 97, 98, 99, 100, 197, 130, 195, 179, 197, 188, 0>>)
            end

            it "should return padding set to 0" do
              {:ok, {_, padding}} = result
              expect(padding).to eq 0
            end
          end
        end
      end

      context "that is invalid" do
        let :endianness, do: :little_endian

        context "and represented as string" do
          context "but value contains invalid UTF-8" do
            let :value, do: "ABC" <> <<0xffff :: 16>> <> "DEF"

            it "throws {:badarg, :value, :invalid}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :invalid})
            end
          end

          context "but value contains null bytes" do
            let :value, do: "ABC" <> << 0 >> <> "DEF"

            it "throws {:badarg, :value, :invalid}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :invalid})
            end
          end

          # FIXME this does not work
          xcontext "but value's byte representation is longer than 0xFFFFFFFF" do
            before do
              allow(Kernel).to accept(:byte_size, fn(_) -> 0xFFFFFFFF + 1 end)
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


    context "if passed 'unix_fd' value" do
      let :type, do: :unix_fd

      context "that is valid" do
        context "and represented as integer" do
          let :value, do: 85555

          context "and endianness is little-endian" do
            let :endianness, do: :little_endian

            it "should return a tuple of format {:ok, bitstring, padding_size}" do
              expect(result).to be_tuple

              {status, {bitstring, padding_size}} = result
              expect(status).to eq :ok
              expect(bitstring).to be_bitstring
              expect(padding_size).to be_number
            end

            it "should return 4-byte long bitstring" do
              {:ok, {bitstring, _}} = result
              expect(byte_size(bitstring)).to eq 4
            end

            it "should return bitstring containing its little-endian representation" do
              {:ok, {bitstring, _}} = result
              expect(bitstring).to eq <<value :: size(4)-unit(8)-unsigned-little >>
            end

            it "should return padding set to 0" do
              {:ok, {_, padding}} = result
              expect(padding).to eq 0
            end
          end

          context "and endianness is big-endian" do
            let :endianness, do: :big_endian

            it "should return a tuple of format {:ok, bitstring, padding_size}" do
              expect(result).to be_tuple

              {status, {bitstring, padding_size}} = result
              expect(status).to eq :ok
              expect(bitstring).to be_bitstring
              expect(padding_size).to be_number
            end

            it "should return 4-byte long bitstring" do
              {:ok, {bitstring, _}} = result
              expect(byte_size(bitstring)).to eq 4
            end

            it "should return bitstring containing its big-endian representation" do
              {:ok, {bitstring, _}} = result
              expect(bitstring).to eq <<value :: size(4)-unit(8)-unsigned-big >>
            end

            it "should return padding set to 0" do
              {:ok, {_, padding}} = result
              expect(padding).to eq 0
            end
          end
        end
      end

      context "that is invalid" do
        let :endianness, do: :little_endian

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


    context "if passed 'object_path' value" do
      let :type, do: :object_path

      context "that is valid" do
        context "and represented as string" do
          let :value, do: "/com/example/MusicPlayer1"

          context "and endianness is little-endian" do
            let :endianness, do: :little_endian

            it "should return a tuple of format {:ok, bitstring, padding_size}" do
              expect(result).to be_tuple

              {status, {bitstring, padding_size}} = result
              expect(status).to eq :ok
              expect(bitstring).to be_bitstring
              expect(padding_size).to be_number
            end

            it "should return bitstring that uses appropriate length for storing UTF-8 characters plus 4-byte length plus NUL terminator" do
              {:ok, {bitstring, _}} = result
              expect(byte_size(bitstring)).to eq 30
            end

            it "should return bitstring containing its byte length (excluding NUL terminator) stored as uint32 plus little-endian representation plus NUL terminator" do
              {:ok, {bitstring, _}} = result
              expect(bitstring).to eq(<<25, 0, 0, 0, 47, 99, 111, 109, 47, 101, 120, 97, 109, 112, 108, 101, 47, 77, 117, 115, 105, 99, 80, 108, 97, 121, 101, 114, 49, 0>>)
            end

            it "should return padding set to 0" do
              {:ok, {_, padding}} = result
              expect(padding).to eq 0
            end
          end

          context "and endianness is big-endian" do
            let :endianness, do: :big_endian

            it "should return a tuple of format {:ok, bitstring, padding_size}" do
              expect(result).to be_tuple

              {status, {bitstring, padding_size}} = result
              expect(status).to eq :ok
              expect(bitstring).to be_bitstring
              expect(padding_size).to be_number
            end

            it "should return bitstring that uses appropriate length for storing UTF-8 characters plus 4-byte length plus NUL terminator" do
              {:ok, {bitstring, _}} = result
              expect(byte_size(bitstring)).to eq 30
            end

            it "should return bitstring containing its byte length (excluding NUL terminator) stored as uint32 plus little-endian representation plus NUL terminator" do
              {:ok, {bitstring, _}} = result
              expect(bitstring).to eq(<<0, 0, 0, 25, 47, 99, 111, 109, 47, 101, 120, 97, 109, 112, 108, 101, 47, 77, 117, 115, 105, 99, 80, 108, 97, 121, 101, 114, 49, 0>>)
            end

            it "should return padding set to 0" do
              {:ok, {_, padding}} = result
              expect(padding).to eq 0
            end
          end
        end
      end

      context "that is invalid" do
        let :endianness, do: :little_endian

        context "and represented as string" do
          context "but value contains invalid UTF-8" do
            let :value, do: "ABC" <> <<0xffff :: 16>> <> "DEF"

            it "throws {:badarg, :value, :invalid}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :invalid})
            end
          end

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

            it "should return a tuple of format {:ok, bitstring, padding_size}" do
              expect(result).to be_tuple

              {status, {bitstring, padding_size}} = result
              expect(status).to eq :ok
              expect(bitstring).to be_bitstring
              expect(padding_size).to be_number
            end

            it "should return bitstring that uses appropriate length for storing UTF-8 characters plus 1-byte length plus NUL terminator" do
              {:ok, {bitstring, _}} = result
              expect(byte_size(bitstring)).to eq 13
            end

            it "should return bitstring containing its byte length (excluding NUL terminator) stored as uint32 plus little-endian representation plus NUL terminator" do
              {:ok, {bitstring, _}} = result
              expect(bitstring).to eq(<<11, 121, 121, 121, 121, 117, 117, 97, 40, 121, 118, 41, 0>>)
            end

            it "should return padding set to 0" do
              {:ok, {_, padding}} = result
              expect(padding).to eq 0
            end
          end

          context "and endianness is big-endian" do
            let :endianness, do: :big_endian

            it "should return bitstring that uses appropriate length for storing UTF-8 characters plus 1-byte length plus NUL terminator" do
              {:ok, {bitstring, _}} = result
              expect(byte_size(bitstring)).to eq 13
            end

            it "should return bitstring containing its byte length (excluding NUL terminator) stored as uint32 plus little-endian representation plus NUL terminator" do
              {:ok, {bitstring, _}} = result
              expect(bitstring).to eq(<<11, 121, 121, 121, 121, 117, 117, 97, 40, 121, 118, 41, 0>>)
            end

            it "should return padding set to 0" do
              {:ok, {_, padding}} = result
              expect(padding).to eq 0
            end
          end
        end
      end

      context "that is invalid" do
        let :endianness, do: :little_endian

        context "and represented as string" do
          context "but value contains invalid UTF-8" do
            let :value, do: "ABC" <> <<0xffff :: 16>> <> "DEF"

            it "throws {:badarg, :value, :invalid}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :invalid})
            end
          end

          context "but value contains null bytes" do
            let :value, do: "ABC" <> << 0 >> <> "DEF"

            it "throws {:badarg, :value, :invalid}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :invalid})
            end
          end

          context "but value's byte representation is longer than 0xFF" do
            let :value, do: String.duplicate("i", 0xFF + 1)

            it "throws {:badarg, :value, :outofrange}" do
              expect(fn -> result end).to throw_term({:badarg, :value, :outofrange})
            end
          end

          pending "but value contains signature of invalid syntax"
        end
      end
    end


    context "if passed 'array' value" do
      let :type, do: :array

      pending "and subtype is a simple type"

      context "and subtype is a struct" do
        let :value, do: %DBux.Value{type: type, subtype: [:struct], value: subvalues}

        context "and its elements need padding" do
          let :subvalues, do: [
            %DBux.Value{type: :struct, subtype: [:string], value: [%DBux.Value{type: :string, value: "abcdefgh"}]},
            %DBux.Value{type: :struct, subtype: [:string], value: [%DBux.Value{type: :string, value: "12345678"}]}]

          context "and endianness is little-endian" do
            let :endianness, do: :little_endian

            it "should return an ok result" do
              expect(described_module.marshall(value, endianness)).to be_ok_result
            end

            it "should return an a valid bitstring aligned to the array element type alignment size, with length header that does not include padding of the last element" do
              {:ok, {bitstring, _padding}} = described_module.marshall(value, endianness)
              expect(bitstring).to eq <<29, 0, 0, 0, 8, 0, 0, 0, 97, 98, 99, 100, 101, 102, 103, 104, 0, 0, 0, 0, 8, 0, 0, 0, 49, 50, 51, 52, 53, 54, 55, 56, 0, 0, 0, 0>>
            end

            it "should return a last element padding" do
              {:ok, {_bitstring, padding}} = described_module.marshall(value, endianness)
              expect(padding).to eq 3
            end
          end

          pending "and endianness is big-endian"
        end
      end
    end


    context "if passed 'struct' value" do
      let :type, do: :struct

      context "and subtype is a single simple type" do
        let :value, do: %DBux.Value{type: type, subtype: [:string], value: [%DBux.Value{type: :string, value: subvalue}]}

        context "and its elements need padding" do
          let :subvalue, do: "abcdefgh"

          context "and endianness is little-endian" do
            let :endianness, do: :little_endian

            it "should return an ok result" do
              expect(described_module.marshall(value, endianness)).to be_ok_result
            end

            it "should return an a valid bitstring aligned to the array element type alignment size" do
              {:ok, {bitstring, _padding}} = described_module.marshall(value, endianness)
              expect(bitstring).to eq <<8, 0, 0, 0, 97, 98, 99, 100, 101, 102, 103, 104, 0, 0, 0, 0 >>
            end

            it "should return a last element padding" do
              {:ok, {_bitstring, padding}} = described_module.marshall(value, endianness)
              expect(padding).to eq 3
            end
          end

          context "and endianness is big-endian" do
            let :endianness, do: :big_endian

            it "should return an ok result" do
              expect(described_module.marshall(value, endianness)).to be_ok_result
            end

            it "should return an a valid bitstring aligned to the array element type alignment size" do
              {:ok, {bitstring, _padding}} = described_module.marshall(value, endianness)
              expect(bitstring).to eq <<0, 0, 0, 8, 97, 98, 99, 100, 101, 102, 103, 104, 0, 0, 0, 0 >>
            end

            it "should return a last element padding" do
              {:ok, {_bitstring, padding}} = described_module.marshall(value, endianness)
              expect(padding).to eq 3
            end
          end
        end

        context "and its elements do not need padding" do
          let :subvalue, do: "abc"

          context "and endianness is little-endian" do
            let :endianness, do: :little_endian

            it "should return an ok result" do
              expect(described_module.marshall(value, endianness)).to be_ok_result
            end

            it "should return an a valid bitstring aligned to the array element type alignment size" do
              {:ok, {bitstring, _padding}} = described_module.marshall(value, endianness)
              expect(bitstring).to eq <<3, 0, 0, 0, 97, 98, 99, 0 >>
            end

            it "should return a last element padding" do
              {:ok, {_bitstring, padding}} = described_module.marshall(value, endianness)
              expect(padding).to eq 0
            end
          end

          context "and endianness is big-endian" do
            let :endianness, do: :big_endian

            it "should return an ok result" do
              expect(described_module.marshall(value, endianness)).to be_ok_result
            end

            it "should return an a valid bitstring aligned to the array element type alignment size" do
              {:ok, {bitstring, _padding}} = described_module.marshall(value, endianness)
              expect(bitstring).to eq <<0, 0, 0, 3, 97, 98, 99, 0 >>
            end

            it "should return a last element padding" do
              {:ok, {_bitstring, padding}} = described_module.marshall(value, endianness)
              expect(padding).to eq 0
            end
          end
        end
      end

      pending "and subtype is a container type"
    end


    xcontext "if passed 'dict' value" do
      let :type, do: :dict

    end


    xcontext "if passed 'variant' value" do
      let :type, do: :variant

    end
  end


  describe ".unmarshall/6" do
    let :depth, do: 0

    xcontext "if type is array" do

    end

    xcontext "if type is variant" do

    end

    xcontext "if type is dict_entry" do

    end

    xcontext "if type is struct" do

    end

    context "if type is byte" do
      let :type, do: :byte
      let :subtype, do: nil

      context "and given bitstring is too short" do
        let :unwrap_values, do: true

        context "if endianness is little-endian" do
          let :bitstring, do: << >>
          let :endianness, do: :little_endian

          it "should return an error result" do
            expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_error_result
          end

          it "should return :bitstring_too_short as an error reason" do
            {:error, reason} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
            expect(reason).to eq :bitstring_too_short
          end
        end

        context "if endianness is big-endian" do
          let :bitstring, do: << >>
          let :endianness, do: :big_endian

          it "should return an error result" do
            expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_error_result
          end

          it "should return :bitstring_too_short as an error reason" do
            {:error, reason} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
            expect(reason).to eq :bitstring_too_short
          end
        end
      end

      context "and given bitstring contains exactly the marshalled value" do
        context "if endianness is little-endian" do
          let :endianness, do: :little_endian
          let :bitstring, do: <<115>>
          let :expected_value, do: 115

          context "and unwrap values is set to true" do
            let :unwrap_values, do: true

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq expected_value
            end

            it "should return an empty rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << >>
            end
          end

          context "and unwrap values is set to false" do
            let :unwrap_values, do: false

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string wrapped in a struct" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq %DBux.Value{type: type, subtype: subtype, value: expected_value}
            end

            it "should return an empty rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << >>
            end
          end
        end

        context "if endianness is big-endian" do
          let :endianness, do: :big_endian
          let :bitstring, do: <<115>>
          let :expected_value, do: 115

          context "and unwrap values is set to true" do
            let :unwrap_values, do: true

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq expected_value
            end

            it "should return an empty rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << >>
            end
          end

          context "and unwrap values is set to false" do
            let :unwrap_values, do: false

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string wrapped in a struct" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq %DBux.Value{type: type, subtype: subtype, value: expected_value}
            end

            it "should return an empty rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << >>
            end
          end
        end
      end

      context "and given bitstring contains more data than the marshalled value" do
        context "if endianness is little-endian" do
          let :endianness, do: :little_endian
          let :bitstring, do: <<115, "a", "b", "c">>
          let :expected_value, do: 115

          context "and unwrap values is set to true" do
            let :unwrap_values, do: true

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq expected_value
            end

            it "should return extra data as rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << "a", "b", "c" >>
            end
          end

          context "and unwrap values is set to false" do
            let :unwrap_values, do: false

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string wrapped in a struct" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq %DBux.Value{type: type, subtype: subtype, value: expected_value}
            end

            it "should return extra data as rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << "a", "b", "c" >>
            end
          end
        end

        context "if endianness is big-endian" do
          let :endianness, do: :big_endian
          let :bitstring, do: <<115, "a", "b", "c">>
          let :expected_value, do: 115

          context "and unwrap values is set to true" do
            let :unwrap_values, do: true

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq expected_value
            end

            it "should return extra data as rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << "a", "b", "c" >>
            end
          end

          context "and unwrap values is set to false" do
            let :unwrap_values, do: false

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string wrapped in a struct" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq %DBux.Value{type: type, subtype: subtype, value: expected_value}
            end

            it "should return extra data as rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << "a", "b", "c" >>
            end
          end
        end
      end
    end

    xcontext "if type is uint16" do

    end

    xcontext "if type is int16" do

    end

    xcontext "if type is uint32" do

    end

    xcontext "if type is int32" do

    end

    xcontext "if type is uint64" do

    end

    xcontext "if type is int64" do

    end

    xcontext "if type is unix_fd" do

    end

    xcontext "if type is double" do

    end

    context "if type is object_path" do
      let :type, do: :object_path
      let :subtype, do: nil

      context "and given bitstring is too short" do
        let :unwrap_values, do: true

        context "if endianness is little-endian" do
          let :bitstring, do: <<17, 0, 0, 0, 111, 114, 103, 46, 114, 97, 100, 105, 111, 107, 105, 116, 46, 116, 101, 115, 116>> # nul byte removed
          let :endianness, do: :little_endian

          it "should return an error result" do
            expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_error_result
          end

          it "should return :bitstring_too_short as an error reason" do
            {:error, reason} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
            expect(reason).to eq :bitstring_too_short
          end
        end

        context "if endianness is big-endian" do
          let :bitstring, do: <<0, 0, 0, 17, 111, 114, 103, 46, 114, 97, 100, 105, 111, 107, 105, 116, 46, 116, 101, 115, 116>> # nul byte removed
          let :endianness, do: :big_endian

          it "should return an error result" do
            expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_error_result
          end

          it "should return :bitstring_too_short as an error reason" do
            {:error, reason} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
            expect(reason).to eq :bitstring_too_short
          end
        end
      end

      context "and given bitstring contains exactly the marshalled value" do
        context "if endianness is little-endian" do
          let :endianness, do: :little_endian
          let :bitstring, do: <<17, 0, 0, 0, 111, 114, 103, 46, 114, 97, 100, 105, 111, 107, 105, 116, 46, 116, 101, 115, 116, 0>>
          let :expected_value, do: "org.radiokit.test"

          context "and unwrap values is set to true" do
            let :unwrap_values, do: true

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq expected_value
            end

            it "should return an empty rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << >>
            end
          end

          context "and unwrap values is set to false" do
            let :unwrap_values, do: false

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string wrapped in a struct" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq %DBux.Value{type: type, subtype: subtype, value: expected_value}
            end

            it "should return an empty rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << >>
            end
          end
        end

        context "if endianness is big-endian" do
          let :endianness, do: :big_endian
          let :bitstring, do: <<0, 0, 0, 17, 111, 114, 103, 46, 114, 97, 100, 105, 111, 107, 105, 116, 46, 116, 101, 115, 116, 0>>
          let :expected_value, do: "org.radiokit.test"

          context "and unwrap values is set to true" do
            let :unwrap_values, do: true

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq expected_value
            end

            it "should return an empty rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << >>
            end
          end

          context "and unwrap values is set to false" do
            let :unwrap_values, do: false

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string wrapped in a struct" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq %DBux.Value{type: type, subtype: subtype, value: expected_value}
            end

            it "should return an empty rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << >>
            end
          end
        end
      end

      context "and given bitstring contains more data than the marshalled value" do
        context "if endianness is little-endian" do
          let :endianness, do: :little_endian
          let :bitstring, do: <<17, 0, 0, 0, 111, 114, 103, 46, 114, 97, 100, 105, 111, 107, 105, 116, 46, 116, 101, 115, 116, 0, "a", "b", "c">>
          let :expected_value, do: "org.radiokit.test"

          context "and unwrap values is set to true" do
            let :unwrap_values, do: true

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq expected_value
            end

            it "should return extra data as rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << "a", "b", "c" >>
            end
          end

          context "and unwrap values is set to false" do
            let :unwrap_values, do: false

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string wrapped in a struct" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq %DBux.Value{type: type, subtype: subtype, value: expected_value}
            end

            it "should return extra data as rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << "a", "b", "c" >>
            end
          end
        end

        context "if endianness is big-endian" do
          let :endianness, do: :big_endian
          let :bitstring, do: <<0, 0, 0, 17, 111, 114, 103, 46, 114, 97, 100, 105, 111, 107, 105, 116, 46, 116, 101, 115, 116, 0, "a", "b", "c">>
          let :expected_value, do: "org.radiokit.test"

          context "and unwrap values is set to true" do
            let :unwrap_values, do: true

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq expected_value
            end

            it "should return extra data as rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << "a", "b", "c" >>
            end
          end

          context "and unwrap values is set to false" do
            let :unwrap_values, do: false

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string wrapped in a struct" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq %DBux.Value{type: type, subtype: subtype, value: expected_value}
            end

            it "should return extra data as rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << "a", "b", "c" >>
            end
          end
        end
      end
    end

    context "if type is string" do
      let :type, do: :string
      let :subtype, do: nil

      context "and given bitstring is too short" do
        let :unwrap_values, do: true

        context "if endianness is little-endian" do
          let :bitstring, do: <<17, 0, 0, 0, 111, 114, 103, 46, 114, 97, 100, 105, 111, 107, 105, 116, 46, 116, 101, 115, 116>> # nul byte removed
          let :endianness, do: :little_endian

          it "should return an error result" do
            expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_error_result
          end

          it "should return :bitstring_too_short as an error reason" do
            {:error, reason} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
            expect(reason).to eq :bitstring_too_short
          end
        end

        context "if endianness is big-endian" do
          let :bitstring, do: <<0, 0, 0, 17, 111, 114, 103, 46, 114, 97, 100, 105, 111, 107, 105, 116, 46, 116, 101, 115, 116>> # nul byte removed
          let :endianness, do: :big_endian

          it "should return an error result" do
            expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_error_result
          end

          it "should return :bitstring_too_short as an error reason" do
            {:error, reason} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
            expect(reason).to eq :bitstring_too_short
          end
        end
      end

      context "and given bitstring contains exactly the marshalled value" do
        context "if endianness is little-endian" do
          let :endianness, do: :little_endian
          let :bitstring, do: <<17, 0, 0, 0, 111, 114, 103, 46, 114, 97, 100, 105, 111, 107, 105, 116, 46, 116, 101, 115, 116, 0>>
          let :expected_value, do: "org.radiokit.test"

          context "and unwrap values is set to true" do
            let :unwrap_values, do: true

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq expected_value
            end

            it "should return an empty rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << >>
            end
          end

          context "and unwrap values is set to false" do
            let :unwrap_values, do: false

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string wrapped in a struct" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq %DBux.Value{type: type, subtype: subtype, value: expected_value}
            end

            it "should return an empty rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << >>
            end
          end
        end

        context "if endianness is big-endian" do
          let :endianness, do: :big_endian
          let :bitstring, do: <<0, 0, 0, 17, 111, 114, 103, 46, 114, 97, 100, 105, 111, 107, 105, 116, 46, 116, 101, 115, 116, 0>>
          let :expected_value, do: "org.radiokit.test"

          context "and unwrap values is set to true" do
            let :unwrap_values, do: true

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq expected_value
            end

            it "should return an empty rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << >>
            end
          end

          context "and unwrap values is set to false" do
            let :unwrap_values, do: false

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string wrapped in a struct" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq %DBux.Value{type: type, subtype: subtype, value: expected_value}
            end

            it "should return an empty rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << >>
            end
          end
        end
      end

      context "and given bitstring contains more data than the marshalled value" do
        context "if endianness is little-endian" do
          let :endianness, do: :little_endian
          let :bitstring, do: <<17, 0, 0, 0, 111, 114, 103, 46, 114, 97, 100, 105, 111, 107, 105, 116, 46, 116, 101, 115, 116, 0, "a", "b", "c">>
          let :expected_value, do: "org.radiokit.test"

          context "and unwrap values is set to true" do
            let :unwrap_values, do: true

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq expected_value
            end

            it "should return extra data as rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << "a", "b", "c" >>
            end
          end

          context "and unwrap values is set to false" do
            let :unwrap_values, do: false

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string wrapped in a struct" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq %DBux.Value{type: type, subtype: subtype, value: expected_value}
            end

            it "should return extra data as rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << "a", "b", "c" >>
            end
          end
        end

        context "if endianness is big-endian" do
          let :endianness, do: :big_endian
          let :bitstring, do: <<0, 0, 0, 17, 111, 114, 103, 46, 114, 97, 100, 105, 111, 107, 105, 116, 46, 116, 101, 115, 116, 0, "a", "b", "c">>
          let :expected_value, do: "org.radiokit.test"

          context "and unwrap values is set to true" do
            let :unwrap_values, do: true

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq expected_value
            end

            it "should return extra data as rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << "a", "b", "c" >>
            end
          end

          context "and unwrap values is set to false" do
            let :unwrap_values, do: false

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string wrapped in a struct" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq %DBux.Value{type: type, subtype: subtype, value: expected_value}
            end

            it "should return extra data as rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << "a", "b", "c" >>
            end
          end
        end
      end
    end

    context "if type is signature" do
      let :type, do: :signature
      let :subtype, do: nil

      context "and given bitstring is too short" do
        let :unwrap_values, do: true

        context "if endianness is little-endian" do
          let :bitstring, do: <<2, 115, 118>> # nul byte removed
          let :endianness, do: :little_endian

          it "should return an error result" do
            expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_error_result
          end

          it "should return :bitstring_too_short as an error reason" do
            {:error, reason} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
            expect(reason).to eq :bitstring_too_short
          end
        end

        context "if endianness is big-endian" do
          let :bitstring, do: <<2, 115, 118>> # nul byte removed
          let :endianness, do: :big_endian

          it "should return an error result" do
            expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_error_result
          end

          it "should return :bitstring_too_short as an error reason" do
            {:error, reason} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
            expect(reason).to eq :bitstring_too_short
          end
        end
      end

      context "and given bitstring contains exactly the marshalled value" do
        context "if endianness is little-endian" do
          let :endianness, do: :little_endian
          let :bitstring, do: <<2, 115, 118, 0>>
          let :expected_value, do: "sv"

          context "and unwrap values is set to true" do
            let :unwrap_values, do: true

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq expected_value
            end

            it "should return an empty rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << >>
            end
          end

          context "and unwrap values is set to false" do
            let :unwrap_values, do: false

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string wrapped in a struct" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq %DBux.Value{type: type, subtype: subtype, value: expected_value}
            end

            it "should return an empty rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << >>
            end
          end
        end

        context "if endianness is big-endian" do
          let :endianness, do: :big_endian
          let :bitstring, do: <<2, 115, 118, 0>>
          let :expected_value, do: "sv"

          context "and unwrap values is set to true" do
            let :unwrap_values, do: true

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq expected_value
            end

            it "should return an empty rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << >>
            end
          end

          context "and unwrap values is set to false" do
            let :unwrap_values, do: false

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string wrapped in a struct" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq %DBux.Value{type: type, subtype: subtype, value: expected_value}
            end

            it "should return an empty rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << >>
            end
          end
        end
      end

      context "and given bitstring contains more data than the marshalled value" do
        context "if endianness is little-endian" do
          let :endianness, do: :little_endian
          let :bitstring, do: <<2, 115, 118, 0, "a", "b", "c">>
          let :expected_value, do: "sv"

          context "and unwrap values is set to true" do
            let :unwrap_values, do: true

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq expected_value
            end

            it "should return extra data as rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << "a", "b", "c" >>
            end
          end

          context "and unwrap values is set to false" do
            let :unwrap_values, do: false

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string wrapped in a struct" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq %DBux.Value{type: type, subtype: subtype, value: expected_value}
            end

            it "should return extra data as rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << "a", "b", "c" >>
            end
          end
        end

        context "if endianness is big-endian" do
          let :endianness, do: :big_endian
          let :bitstring, do: <<2, 115, 118, 0, "a", "b", "c">>
          let :expected_value, do: "sv"

          context "and unwrap values is set to true" do
            let :unwrap_values, do: true

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq expected_value
            end

            it "should return extra data as rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << "a", "b", "c" >>
            end
          end

          context "and unwrap values is set to false" do
            let :unwrap_values, do: false

            it "should return an ok result" do
              expect(described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)).to be_ok_result
            end

            it "should return a parsed string wrapped in a struct" do
              {:ok, {value, _rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(value).to eq %DBux.Value{type: type, subtype: subtype, value: expected_value}
            end

            it "should return extra data as rest" do
              {:ok, {_value, rest}} = described_module.unmarshall(bitstring, endianness, type, subtype, unwrap_values, depth)
              expect(rest).to eq << "a", "b", "c" >>
            end
          end
        end
      end
    end
  end
end
