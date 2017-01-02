# encoding: utf-8

require_relative "spec_helper"

RSpec.describe "Stream object" do
  it "compresses a stream upon request" do
    stream = PDF::Core::Stream.new
    stream << "Hi There " * 20

    cstream = PDF::Core::Stream.new
    cstream << "Hi There " * 20
    cstream.compress!

    expect(cstream.filtered_stream.length).to be < stream.length,
      "compressed stream expected to be smaller than source but wasn't"
    expect(cstream.data[:Filter]).to eq [:FlateDecode]
  end

  it "exposes compression state" do
    stream = PDF::Core::Stream.new
    stream << "Hello"
    stream.compress!

    expect(stream).to be_compressed
  end

  it "detects from filters if stream is compressed" do
    stream = PDF::Core::Stream.new
    stream << "Hello"
    stream.filters << :FlateDecode

    expect(stream).to be_compressed
  end

  it "has Length if in data" do
    stream = PDF::Core::Stream.new
    stream << "hello"

    expect(stream.data[:Length]).to eq 5
  end

  it "updates Length when updated" do
    stream = PDF::Core::Stream.new
    stream << "hello"
    expect(stream.data[:Length]).to eq 5

    stream << " world"
    expect(stream.data[:Length]).to eq 11
  end

  it "corecly handles decode params" do
    stream = PDF::Core::Stream.new
    stream << "Hello"
    stream.filters << { :FlateDecode => { :Predictor => 15 } }

    expect(stream.data[:DecodeParms]).to eq [{ :Predictor => 15 }]
  end
end

