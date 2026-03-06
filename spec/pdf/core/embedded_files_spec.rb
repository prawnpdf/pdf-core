# frozen_string_literal: true

require 'spec_helper'

class EmbeddedFiles
  include PDF::Core::EmbeddedFiles

  class InnerRenderer; def min_version(value); end; end

  attr_reader :renderer

  def initialize
    @size = 0
    @root = ref!(Type: :Catalog)
    @renderer = InnerRenderer.new
  end

  def names
    @root.data[:Names] ||= ref!(Type: :Names)
  end

  def ref!(data)
    @size += 1

    PDF::Core::Reference.new(@size, data)
  end
end

RSpec.describe EmbeddedFiles do
  it 'has an empty catalog object' do
    t = described_class.new
    pdf_object = "2 0 obj\n<< /Type /Names\n>>\nendobj\n"
    expect(t.names.object).to eq pdf_object
  end

  it 'has an embedded files object with no names' do
    t = described_class.new
    pdf_object = "3 0 obj\n<< /Names []\n>>\nendobj\n"
    expect(t.embedded_files.object).to eq pdf_object
  end

  it 'has a catalog object with an embedded files reference' do
    t = described_class.new
    t.embedded_files

    pdf_object = "2 0 obj\n<< /Type /Names\n/EmbeddedFiles 3 0 R\n>>\nendobj\n"
    expect(t.names.object).to eq pdf_object
  end

  it 'has an embedded files object with one name reference' do
    t = described_class.new
    file_name = PDF::Core::LiteralString.new('my_file')

    t.add_embedded_file(file_name, t.ref!(Type: :Filespec))

    pdf_object = "4 0 obj\n<< /Names [(my_file) 2 0 R]\n>>\nendobj\n"
    expect(t.embedded_files.data.size).to eq 1
    expect(t.embedded_files.object).to eq pdf_object
  end
end
