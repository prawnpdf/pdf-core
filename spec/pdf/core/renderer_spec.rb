# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PDF::Core::Renderer do
  subject(:renderer) { described_class.new(PDF::Core::DocumentState.new({})) }

  it 'renders document' do
    doc = renderer.render

    expect(doc).to be_a(String)
    expect(doc).to_not be_empty
  end

  it 'renders document header' do
    expect(renderer.render).to start_with('%PDF-')
  end

  it 'renders EOF' do
    expect(renderer.render).to end_with("\n%%EOF\n")
  end

  it 'renders xref marker' do
    expect(renderer.render).to include("\nxref\n")
  end

  it 'renders trailer marker' do
    expect(renderer.render).to include("\ntrailer\n")
  end

  it 'renders startxref marker' do
    expect(renderer.render).to include("\nstartxref\n")
  end

  it 'renders to a file' do
    require 'tempfile'

    Tempfile.open('doc') do |f|
      expect { renderer.render(f) }.to_not raise_error
      expect(f.size).to_not eq(0)
    end
  end

  it 'renders to a StringIO' do
    sio = StringIO.new.binmode

    expect { renderer.render(sio) }.to_not raise_error
    expect(sio.size).to_not eq(0)
  end

  it 'renders to an object that implements #<<' do
    out = double
    allow(out).to receive(:<<)

    expect { renderer.render(out) }.to_not raise_error

    expect(out).to have_received(:<<).with(an_instance_of(String))
  end
end
