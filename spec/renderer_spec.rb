require_relative "spec_helper"
require "digest/sha2"
require "tempfile"

describe PDF::Core::Renderer do
  let(:document_state) { PDF::Core::DocumentState.new({}) }
  let(:renderer) { described_class.new(document_state) }

  describe "#render" do
    it "renders the document" do
      expect { renderer.render }.to_not raise_error
    end

    let(:result_hash) { Digest::SHA2.new.update(result).hexdigest }
    let(:blank_document_hash) { "637198c6150ad98f4bf6382a9aeed13690dc91ed2c3e1042fbb91884bf9ab6d4" }

    context "when no IO is passed in" do
      let(:result) { renderer.render }

      it "returns a string" do
        expect(result).to be_a String
      end

      it "renders a blank document" do
        expect(result_hash).to eq blank_document_hash
      end
    end

    context "when IO is passed in" do
      let(:io) { Tempfile.open("pdf") }
      let(:result) do
        renderer.render(io)
        io.rewind
        io.read
      end

      after { io.close }

      it "returns nil" do
        expect(renderer.render(io)).to be nil
      end

      it "writes a blank document to the io" do
        expect(result_hash).to eq blank_document_hash
      end
    end

    context "when non-seekable IO is passed in" do
      class DummyIO
        def initialize
          @buffer = ""
        end

        def write(str)
          @buffer << str
        end

        def read
          @buffer
        end
      end

      let(:io) { DummyIO.new }
      let(:result) do
        renderer.render(io)
        io.read
      end

      it "returns nil" do
        expect(renderer.render(io)).to be nil
      end

      it "writes a blank document to the io" do
        expect(result_hash).to eq blank_document_hash
      end
    end
  end
end
