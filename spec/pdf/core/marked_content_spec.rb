# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PDF::Core::MarkedContent do
  subject(:renderer) do
    PDF::Core::Renderer.new(PDF::Core::DocumentState.new({}))
  end

  before do
    renderer.start_new_page
  end

  describe '#begin_marked_content' do
    it 'emits BMC operator with tag' do
      renderer.begin_marked_content(:P)
      content = renderer.state.page.content.stream.filtered_stream

      expect(content).to include('/P BMC')
    end
  end

  describe '#end_marked_content' do
    it 'emits EMC operator' do
      renderer.end_marked_content
      content = renderer.state.page.content.stream.filtered_stream

      expect(content).to include('EMC')
    end
  end

  describe '#begin_marked_content_with_properties' do
    it 'emits BDC operator with tag and properties' do
      renderer.begin_marked_content_with_properties(:P, { MCID: 0 })
      content = renderer.state.page.content.stream.filtered_stream

      expect(content).to include('/P << /MCID 0')
      expect(content).to include('BDC')
    end
  end

  describe '#marked_content_sequence' do
    it 'wraps content in BMC/EMC' do
      renderer.marked_content_sequence(:Artifact) do
        renderer.add_content('some content')
      end
      content = renderer.state.page.content.stream.filtered_stream

      expect(content).to include('/Artifact BMC')
      expect(content).to include('some content')
      expect(content).to include('EMC')
    end
  end

  describe '#marked_content_sequence_with_properties' do
    it 'wraps content in BDC/EMC with properties' do
      renderer.marked_content_sequence_with_properties(:P, { MCID: 0 }) do
        renderer.add_content('tagged text')
      end
      content = renderer.state.page.content.stream.filtered_stream

      expect(content).to include('/P << /MCID 0')
      expect(content).to include('BDC')
      expect(content).to include('tagged text')
      expect(content).to include('EMC')
    end
  end
end
