# encoding: utf-8

require_relative "spec_helper"

RSpec.describe "A Reference object" do
  it "produces a PDF reference on #to_s call" do
    ref = PDF::Core::Reference(1,true)
    expect(ref.to_s).to eq "1 0 R"
  end

  it "allows changing generation number" do
    ref = PDF::Core::Reference(1,true)
    ref.gen = 1
    expect(ref.to_s).to eq "1 1 R"
  end

  it "generates a valid PDF object for the referenced data" do
    ref = PDF::Core::Reference(2,[1,"foo"])
    expect(ref.object).to eq(
      "2 0 obj\n#{PDF::Core::PdfObject([1,"foo"])}\nendobj\n"
    )
  end

  it "includes stream fileds in dictionary when serializing" do
     ref = PDF::Core::Reference(1, {})
     ref.stream << 'Hello'
     expect(ref.object).to eq(
       "1 0 obj\n<< /Length 5\n>>\nstream\nHello\nendstream\nendobj\n"
     )
  end

  it "appends data to stream when #<< is used" do
     ref = PDF::Core::Reference(1, {})
     ref << "BT\n/F1 12 Tf\n72 712 Td\n( A stream ) Tj\nET"
     expect(ref.object).to eq(
       "1 0 obj\n<< /Length 41\n>>\nstream"\
       "\nBT\n/F1 12 Tf\n72 712 Td\n( A stream ) Tj\nET"\
       "\nendstream\nendobj\n"
     )
  end

  it "copies the data and stream from another ref on #replace" do
    from = PDF::Core::Reference(3, {:foo => 'bar'})
    from << "has a stream too"

    to = PDF::Core::Reference(4, {:foo => 'baz'})
    to.replace from

    # preserves identifier but copies data and stream
    expect(to.identifier).to eq 4
    expect(to.data).to eq from.data
    expect(to.stream).to eq from.stream
  end

  it "copies a compressed stream from a compressed ref on #replace" do
    from = PDF::Core::Reference(5, {:foo => 'bar'})
    from << "has a stream too " * 20
    from.stream.compress!

    to = PDF::Core::Reference(6, {:foo => 'baz'})
    to.replace from

    expect(to.identifier).to eq 6
    expect(to.data).to eq from.data
    expect(to.stream).to eq from.stream
    expect(to.stream.compressed?).to eq true
  end
end
