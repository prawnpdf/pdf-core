# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PDF::Core::StructureTree do
  let(:state) { PDF::Core::DocumentState.new(marked: true) }
  let(:renderer) { PDF::Core::Renderer.new(state) }
  let(:structure_tree) { renderer.structure_tree }

  before do
    renderer.start_new_page
  end

  describe 'initialization' do
    it 'creates a structure tree when marked: true' do
      expect(structure_tree).to be_a(PDF::Core::StructureTree)
    end

    it 'does not create a structure tree when marked is not set' do
      plain_renderer = PDF::Core::Renderer.new(
        PDF::Core::DocumentState.new({}),
      )
      expect(plain_renderer.structure_tree).to be_nil
    end
  end

  describe '#marked?' do
    it 'returns true for marked documents' do
      expect(renderer.marked?).to be true
    end

    it 'returns false for unmarked documents' do
      plain_renderer = PDF::Core::Renderer.new(
        PDF::Core::DocumentState.new({}),
      )
      expect(plain_renderer.marked?).to be false
    end
  end

  describe '#allocate_mcid' do
    it 'returns sequential MCIDs starting from 0' do
      expect(structure_tree.allocate_mcid).to eq(0)
      expect(structure_tree.allocate_mcid).to eq(1)
      expect(structure_tree.allocate_mcid).to eq(2)
    end

    it 'resets MCIDs for new pages' do
      structure_tree.allocate_mcid # 0 on page 1
      structure_tree.allocate_mcid # 1 on page 1

      renderer.start_new_page

      expect(structure_tree.allocate_mcid).to eq(0) # 0 on page 2
    end
  end

  describe '#add_element' do
    it 'creates a structure element reference' do
      elem = structure_tree.add_element(:P)

      expect(elem).to be_a(PDF::Core::Reference)
      expect(elem.data[:Type]).to eq(:StructElem)
      expect(elem.data[:S]).to eq(:P)
    end

    it 'adds element as child of Document element' do
      elem = structure_tree.add_element(:P)
      doc_elem = structure_tree.document_elem_ref

      expect(doc_elem.data[:K]).to include(elem)
    end

    it 'supports Alt text attribute' do
      elem = structure_tree.add_element(:Figure, Alt: 'A photo')

      expect(elem.data[:Alt]).to eq('A photo')
    end

    it 'supports Scope attribute for table headers' do
      elem = structure_tree.add_element(:TH, Scope: :Column)

      expect(elem.data[:A]).to eq({ O: :Table, Scope: :Column })
    end

    it 'supports ActualText attribute' do
      elem = structure_tree.add_element(:Span, ActualText: 'required')

      expect(elem.data[:ActualText]).to eq('required')
    end

    it 'includes ActualText in rendered PDF output' do
      structure_tree.begin_element(:P)
      span = structure_tree.begin_element(:Span, ActualText: 'selected')
      structure_tree.mark_content(:Span) do
        renderer.add_content('BT /F1 12 Tf (X) Tj ET')
      end
      structure_tree.end_element # Span
      structure_tree.end_element # P

      output = renderer.render

      expect(output).to include('/ActualText')
    end
  end

  describe '#begin_element / #end_element' do
    it 'manages an element stack' do
      table_elem = structure_tree.begin_element(:Table)
      row_elem = structure_tree.add_element(:TR)

      # TR should be child of Table, not Document
      expect(table_elem.data[:K]).to include(row_elem)

      structure_tree.end_element
      # After ending Table, next element goes to Document
      p_elem = structure_tree.add_element(:P)
      doc_elem = structure_tree.document_elem_ref
      expect(doc_elem.data[:K]).to include(p_elem)
    end
  end

  describe '#mark_content' do
    it 'emits BDC/EMC operators with MCID' do
      structure_tree.begin_element(:P)
      structure_tree.mark_content(:Span) do
        renderer.add_content('Hello')
      end
      structure_tree.end_element

      content = renderer.state.page.content.stream.filtered_stream
      expect(content).to include('/Span << /MCID 0')
      expect(content).to include('BDC')
      expect(content).to include('Hello')
      expect(content).to include('EMC')
    end

    it 'records MCR in the structure element K array' do
      elem = structure_tree.begin_element(:P)
      structure_tree.mark_content(:Span) do
        renderer.add_content('text')
      end
      structure_tree.end_element

      mcr = elem.data[:K].find { |k| k.is_a?(Hash) && k[:Type] == :MCR }
      expect(mcr).not_to be_nil
      expect(mcr[:MCID]).to eq(0)
    end
  end

  describe '#mark_artifact' do
    it 'emits BMC /Artifact' do
      structure_tree.mark_artifact do
        renderer.add_content('decorative')
      end

      content = renderer.state.page.content.stream.filtered_stream
      expect(content).to include('/Artifact BMC')
      expect(content).to include('decorative')
      expect(content).to include('EMC')
    end

    it 'emits BDC with artifact type when specified' do
      structure_tree.mark_artifact(artifact_type: :Pagination) do
        renderer.add_content('page 1')
      end

      content = renderer.state.page.content.stream.filtered_stream
      expect(content).to include('/Artifact')
      expect(content).to include('/Type /Pagination')
      expect(content).to include('BDC')
    end
  end

  describe '#finalize!' do
    it 'sets MarkInfo on catalog' do
      root_data = renderer.state.store.root.data
      expect(root_data[:MarkInfo]).to eq({ Marked: true })
    end

    it 'builds StructTreeRoot and attaches to catalog after render' do
      structure_tree.begin_element(:P)
      structure_tree.mark_content(:Span) do
        renderer.add_content('text')
      end
      structure_tree.end_element

      # Render triggers before_render callback which calls finalize!
      output = renderer.render

      root_data = renderer.state.store.root.data
      expect(root_data[:StructTreeRoot]).to be_a(PDF::Core::Reference)
      expect(root_data[:StructTreeRoot].data[:Type]).to eq(:StructTreeRoot)
    end

    it 'creates a Document structure element as root K' do
      structure_tree.add_element(:P)
      renderer.render

      struct_root = renderer.state.store.root.data[:StructTreeRoot]
      doc_elem = struct_root.data[:K]
      expect(doc_elem).to be_a(PDF::Core::Reference)
      expect(doc_elem.data[:S]).to eq(:Document)
    end

    it 'builds a ParentTree' do
      structure_tree.begin_element(:P)
      structure_tree.mark_content(:Span) do
        renderer.add_content('text')
      end
      structure_tree.end_element

      renderer.render

      struct_root = renderer.state.store.root.data[:StructTreeRoot]
      parent_tree = struct_root.data[:ParentTree]
      expect(parent_tree).to be_a(PDF::Core::Reference)
      expect(parent_tree.data[:Nums]).not_to be_empty
    end

    it 'assigns StructParents to pages with marked content' do
      structure_tree.begin_element(:P)
      structure_tree.mark_content(:Span) do
        renderer.add_content('text')
      end
      structure_tree.end_element

      renderer.render

      page_dict = renderer.state.pages.first.dictionary.data
      expect(page_dict[:StructParents]).to be_a(Integer)
    end

    it 'produces a valid PDF' do
      structure_tree.begin_element(:H1)
      structure_tree.mark_content(:Span) do
        renderer.add_content('BT /F1 12 Tf (Heading) Tj ET')
      end
      structure_tree.end_element

      structure_tree.begin_element(:P)
      structure_tree.mark_content(:Span) do
        renderer.add_content('BT /F1 12 Tf (Body text) Tj ET')
      end
      structure_tree.end_element

      output = renderer.render

      expect(output).to start_with('%PDF-1.7')
      expect(output).to include('/MarkInfo')
      expect(output).to include('/Marked true')
      expect(output).to include('/StructTreeRoot')
      expect(output).to include('/StructElem')
    end
  end
end
