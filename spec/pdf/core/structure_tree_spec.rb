# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PDF::Core::StructureTree do
  let(:renderer) { PDF::Core::Renderer.new(PDF::Core::DocumentState.new(tagged: true)) }
  let(:tree) { renderer.state.structure_tree }

  before { renderer.start_new_page }

  def reader
    @reader ||= PDF::Reader.new(StringIO.new(renderer.render))
  end

  def catalog
    reader.objects.deref(reader.objects.trailer[:Root])
  end

  def struct_root
    reader.objects.deref(catalog[:StructTreeRoot])
  end

  def kids(element)
    reader.objects.deref(element[:K]).map { |kid| reader.objects.deref(kid) }
  end

  def parent_tree_entry(key)
    nums = reader.objects.deref(struct_root[:ParentTree])[:Nums]
    nums.each_slice(2).to_h.fetch(key)
  end

  def page_dict(number)
    reader.page(number).page_object
  end

  it 'marks the catalog' do
    expect(catalog[:MarkInfo]).to eq(Marked: true)
    expect(struct_root[:Type]).to eq(:StructTreeRoot)
  end

  it 'does not mark untagged documents' do
    untagged = PDF::Core::Renderer.new(PDF::Core::DocumentState.new({}))
    untagged.start_new_page
    objects = PDF::Reader.new(StringIO.new(untagged.render)).objects

    expect(objects.deref(objects.trailer[:Root])).to_not include(:MarkInfo, :StructTreeRoot)
  end

  it 'sets the document language' do
    renderer = PDF::Core::Renderer.new(PDF::Core::DocumentState.new(language: 'pl-PL'))

    expect(renderer.state.store.root.data[:Lang]).to eq('pl-PL')
  end

  it 'wraps content of an element in a marked-content sequence' do
    tree.element(:P) { renderer.add_content('0 0 m') }

    expect(reader.page(1).raw_content).to include("/P << /MCID 0\n>> BDC\n0 0 m\nEMC")

    paragraph = kids(struct_root).first
    expect(paragraph).to include(S: :P, P: catalog[:StructTreeRoot])
    expect(kids(paragraph).first).to include(Type: :MCR, MCID: 0)
    expect(reader.objects.deref(parent_tree_entry(page_dict(1)[:StructParents]))).to eq([struct_root[:K].first])
  end

  it 'leaves content outside elements unmarked' do
    renderer.add_content('0 0 m')

    expect(reader.page(1).raw_content).to_not include('BDC', 'BMC')
  end

  it 'continues an element on the next page under a new MCID' do
    tree.element(:P) do
      renderer.add_content('0 0 m')
      renderer.start_new_page
      renderer.add_content('1 1 m')
    end

    expect(reader.page(1).raw_content).to include("0 0 m\nEMC")
    expect(reader.page(2).raw_content).to include("/P << /MCID 0\n>> BDC\n1 1 m\nEMC")

    mcrs = kids(kids(struct_root).first)
    expect(mcrs.map { |mcr| mcr[:Pg] }).to eq(reader.objects.page_references)
  end

  it 'interrupts an element for an artifact' do
    tree.element(:P) do
      renderer.add_content('0 0 m')
      tree.artifact(Type: :Pagination) { renderer.add_content('1 1 m') }
      renderer.add_content('2 2 m')
    end

    expect(reader.page(1).raw_content).to include(
      "0 0 m\nEMC\n/Artifact << /Type /Pagination\n>> BDC\n1 1 m\nEMC\n/P << /MCID 1\n>> BDC\n2 2 m",
    )
    expect(kids(kids(struct_root).first).map { |mcr| mcr[:MCID] }).to eq([0, 1])
  end

  it 'keeps reading order across nested elements' do
    tree.element(:P) do
      renderer.add_content('0 0 m')
      tree.element(:Span, Lang: 'de') { renderer.add_content('1 1 m') }
      renderer.add_content('2 2 m')
    end

    paragraph_kids = kids(kids(struct_root).first)
    expect(paragraph_kids.map { |kid| kid[:Type] }).to eq(%i[MCR StructElem MCR])
    expect(paragraph_kids[1][:S]).to eq(:Span)
  end

  it 'makes annotations part of the innermost element' do
    renderer.extend(PDF::Core::Annotations)
    tree.element(:Link) do
      renderer.add_content('0 0 m')
      renderer.link_annotation([0, 0, 1, 1], Contents: 'Example')
    end

    link = kids(struct_root).first
    objr = kids(link).last
    annotation = reader.objects.deref(objr[:Obj])
    expect(objr[:Type]).to eq(:OBJR)
    expect(parent_tree_entry(annotation[:StructParent])).to eq(struct_root[:K].first)
    expect(page_dict(1)[:Tabs]).to eq(:S)
  end
end
