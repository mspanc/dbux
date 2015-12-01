defmodule DBux.Transport.TCPSpec do
  use ESpec

  context ".connect/1" do
    context "if passed incomplete options" do
      context "passed an empty list as options" do
        it "throws {:badopts, :hostname, :missing}" do
          expect(fn -> DBux.Transport.TCP.connect([]) end) |> to throw_term({:badopts, :hostname, :missing})
        end
      end

      context "passed only hostname" do
        it "throws {:badopts, :port, :missing}" do
          expect(fn -> DBux.Transport.TCP.connect([hostname: "example.com"]) end) |> to throw_term({:badopts, :port, :missing})
        end
      end

      context "passed only port" do
        it "throws {:badopts, :hostname, :missing}" do
          expect(fn -> DBux.Transport.TCP.connect([port: 1234]) end) |> to throw_term({:badopts, :hostname, :missing})
        end
      end

      context "passed only port" do
        it "throws {:badopts, :hostname, :missing}" do
          expect(fn -> DBux.Transport.TCP.connect([port: 1234]) end) |> to throw_term({:badopts, :hostname, :missing})
        end
      end
    end

    context "if passed invalid options" do
      context "passed non-string hostname" do
        it "throws {:badopts, :hostname, :invalidtype}" do
          expect(fn -> DBux.Transport.TCP.connect([hostname: 1234, port: 1234]) end) |> to throw_term({:badopts, :hostname, :invalidtype})
        end
      end

      context "passed non-integer port" do
        it "throws {:badopts, :port, :invalidtype}" do
          expect(fn -> DBux.Transport.TCP.connect([hostname: "example.com", port: "1234"]) end) |> to throw_term({:badopts, :port, :invalidtype})
        end
      end

      context "passed integer port but < 1" do
        it "throws {:badopts, :port, :outofrange}" do
          expect(fn -> DBux.Transport.TCP.connect([hostname: "example.com", port: 0]) end) |> to throw_term({:badopts, :port, :outofrange})
        end
      end

      context "passed integer port but > 65535" do
        it "throws {:badopts, :port, :outofrange}" do
          expect(fn -> DBux.Transport.TCP.connect([hostname: "example.com", port: 65536]) end) |> to throw_term({:badopts, :port, :outofrange})
        end
      end
    end
  end
end
