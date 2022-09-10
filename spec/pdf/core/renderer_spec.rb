# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PDF::Core::Renderer do
  subject(:renderer) do
    pdf = PDF::Core::Renderer.new(PDF::Core::DocumentState.new({}))
    pdf.start_new_page
    pdf.add_content("#{PDF::Core.real_params([100, 500])} m")
    pdf.add_content("#{PDF::Core.real_params([300, 550])} l")
    pdf.add_content('S')
    pdf
  end

  describe '.render' do
    it 'requires output object to only support method <<' do
      output = Class.new { def <<(*); self end }.new
      expect { subject.render(output) }.to_not raise_error
    end

    it 'returns the rendered string when output is not given' do
      expect(subject.render).to be_a(String)
    end

    it 'returns the rendered string when output is StringIO' do
      expect(subject.render(StringIO.new)).to be_a(String)
    end

    it 'returns nil when output is not StringIO' do
      output = Class.new { def <<(*); self end }.new
      expect(subject.render(output)).to be_nil
    end
  end
end
