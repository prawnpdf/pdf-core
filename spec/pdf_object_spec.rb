# encoding: ASCII-8BIT
require_relative "spec_helper"

# See PDF Reference, Sixth Edition (1.7) pp51-60 for details
RSpec.describe "PDF Object Serialization" do

  it "converts Ruby's nil to PDF null" do
    expect(PDF::Core::PdfObject(nil)).to eq "null"
  end

  it "converts Ruby booleans to PDF booleans" do
    expect(PDF::Core::PdfObject(true)).to eq "true"
    expect(PDF::Core::PdfObject(false)).to eq "false"
  end

  it "converts a Ruby number to PDF number" do
    expect(PDF::Core::PdfObject(42)).to eq "42"

    # numbers are rounded to four decimal places
    expect(PDF::Core::PdfObject(1.214112421)).to eq "1.2141"
  end

  it "converts a Ruby time object to a PDF timestamp" do
    t = Time.now
    expect(PDF::Core::PdfObject(t))
      .to eq t.strftime("(D:%Y%m%d%H%M%S%z").chop.chop + "'00')"
  end

  it "converts a Ruby string to PDF string when inside a content stream" do
    s = "I can has a string"
    expect(PDF::Inspector.parse(PDF::Core::PdfObject(s, true))).to eq s
  end

  it "converts a Ruby string to a UTF-16 PDF string when outside a content stream" do
    s = "I can has a string"
    s_utf16 = "\xFE\xFF" + s.unpack("U*").pack("n*")
    expect(PDF::Inspector.parse(PDF::Core::PdfObject(s, false))).to eq s_utf16
  end

  it "converts a Ruby string with characters outside the BMP to its " +
     "UTF-16 representation with a BOM" do
    # U+10192 ROMAN SEMUNCIA SIGN
    semuncia = [65938].pack("U")
    expect(PDF::Core::PdfObject(semuncia, false).upcase).to eq "<FEFFD800DD92>"
  end

  it "passes through bytes regardless of content stream status for ByteString" do
    expect(
      PDF::Core::PdfObject(PDF::Core::ByteString.new("\xDE\xAD\xBE\xEF")).upcase
    ).to eq "<DEADBEEF>"
  end

  it "escapes parens when converting from Ruby string to PDF" do
    s =  'I )(can has a string'
    expect(PDF::Inspector.parse(PDF::Core::PdfObject(s, true))).to eq s
  end

  it "handles ruby escaped parens when converting to PDF string" do
    s = 'I can \\)( has string'
    expect(PDF::Inspector.parse(PDF::Core::PdfObject(s, true))).to eq s
  end

  it "escapes various strings correctly when converting a LiteralString" do
    ls = PDF::Core::LiteralString.new("abc")
    expect(PDF::Core::PdfObject(ls)).to eq "(abc)"

    ls = PDF::Core::LiteralString.new("abc\x0Ade") # should escape \n
    expect(PDF::Core::PdfObject(ls)).to eq "(abc\x5C\x0Ade)"

    ls = PDF::Core::LiteralString.new("abc\x0Dde") # should escape \r
    expect(PDF::Core::PdfObject(ls)).to eq "(abc\x5C\x0Dde)"

    ls = PDF::Core::LiteralString.new("abc\x09de") # should escape \t
    expect(PDF::Core::PdfObject(ls)).to eq "(abc\x5C\x09de)"

    ls = PDF::Core::LiteralString.new("abc\x08de") # should escape \b
    expect(PDF::Core::PdfObject(ls)).to eq "(abc\x5C\x08de)"

    ls = PDF::Core::LiteralString.new("abc\x0Cde") # should escape \f
    expect(PDF::Core::PdfObject(ls)).to eq "(abc\x5C\x0Cde)"

    ls = PDF::Core::LiteralString.new("abc(de") # should escape \(
    expect(PDF::Core::PdfObject(ls)).to eq "(abc\x5C(de)"

    ls = PDF::Core::LiteralString.new("abc)de") # should escape \)
    expect(PDF::Core::PdfObject(ls)).to eq "(abc\x5C)de)"

    ls = PDF::Core::LiteralString.new("abc\x5Cde") # should escape \\
    expect(PDF::Core::PdfObject(ls)).to eq "(abc\x5C\x5Cde)"
    expect(PDF::Core::PdfObject(ls).size).to eq 9
  end

  it "escapes strings correctly when converting a LiteralString that is not utf-8" do
    data = "\x43\xaf\xc9\x7f\xef\xf\xe6\xa8\xcb\x5c\xaf\xd0"
    ls = PDF::Core::LiteralString.new(data)
    expect(PDF::Core::PdfObject(ls))
      .to eq "(\x43\xaf\xc9\x7f\xef\xf\xe6\xa8\xcb\x5c\x5c\xaf\xd0)"
  end

  it "converts a Ruby symbol to PDF name" do
    expect(PDF::Core::PdfObject(:my_symbol)).to eq "/my_symbol"
    expect(
      PDF::Core::PdfObject(:"A;Name_With-Various***Characters?")
    ).to eq "/A;Name_With-Various***Characters?"
  end

  it "converts a whitespace or delimiter containing Ruby symbol to a PDF name" do
    expect(PDF::Core::PdfObject(:"my symbol")).to eq "/my#20symbol"
    expect(PDF::Core::PdfObject(:"my#symbol")).to eq "/my#23symbol"
    expect(PDF::Core::PdfObject(:"my/symbol")).to eq "/my#2Fsymbol"
    expect(PDF::Core::PdfObject(:"my(symbol")).to eq "/my#28symbol"
    expect(PDF::Core::PdfObject(:"my)symbol")).to eq "/my#29symbol"
    expect(PDF::Core::PdfObject(:"my<symbol")).to eq "/my#3Csymbol"
    expect(PDF::Core::PdfObject(:"my>symbol")).to eq "/my#3Esymbol"
  end

  it "converts a Ruby array to PDF Array when inside a content stream" do
    expect(PDF::Core::PdfObject([1,2,3])).to eq "[1 2 3]"
    expect(
      PDF::Inspector.parse(PDF::Core::PdfObject([[1,2],:foo,"Bar"], true))
    ).to eq [[1,2],:foo, "Bar"]
  end

  it "converts a Ruby array to PDF Array when outside a content stream" do
    bar = "\xFE\xFF" + "Bar".unpack("U*").pack("n*")
    expect(PDF::Core::PdfObject([1,2,3])).to eq "[1 2 3]"

    expect(
      PDF::Inspector.parse(PDF::Core::PdfObject([[1,2],:foo,"Bar"], false))
    ).to eq [[1,2],:foo, bar]
  end

  it "converts a Ruby hash to a PDF Dictionary when inside a content stream" do
    dict = PDF::Core::PdfObject( {:foo  => :bar,
                              "baz" => [1,2,3],
                              :bang => {:a => "what", :b => [:you, :say] }}, true )

    res = PDF::Inspector.parse(dict)

    expect(res[:foo]).to eq :bar
    expect(res[:baz]).to eq [1,2,3]
    expect(res[:bang]).to eq(:a => "what", :b => [:you, :say])
  end

  it "converts a Ruby hash to a PDF Dictionary when outside a content stream" do
    what = "\xFE\xFF" + "what".unpack("U*").pack("n*")
    dict = PDF::Core::PdfObject( {:foo  => :bar,
                              "baz" => [1,2,3],
                              :bang => {:a => "what", :b => [:you, :say] }}, false )

    res = PDF::Inspector.parse(dict)

    expect(res[:foo]).to eq :bar
    expect(res[:baz]).to eq [1, 2, 3]
    expect(res[:bang]).to eq(:a => what, :b => [:you, :say])
  end

  it "does not allow keys other than strings or symbols for PDF dicts" do
    expect { PDF::Core::PdfObject(:foo => :bar, :baz => :bang, 1 => 4) }
      .to raise_error(PDF::Core::Errors::FailedObjectConversion)
  end

  it "converts a Prawn::Reference to a PDF indirect object reference" do
    ref = PDF::Core::Reference(1,true)
    expect(PDF::Core::PdfObject(ref)).to eq ref.to_s
  end

  it "converts a NameTree::Node to a PDF hash" do
    # FIXME: Soft dependench on Prawn::Document exists in Node
    node = PDF::Core::NameTree::Node.new(nil, 10)
    node.add "hello", 1.0
    node.add "world", 2.0
    data = PDF::Core::PdfObject(node)
    res = PDF::Inspector.parse(data)
    expect(res).to eq(:Names => ["hello", 1.0, "world", 2.0])
  end
end
