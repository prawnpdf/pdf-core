# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PDF::Core::Text do
  let(:mock) do
    text_mock_class = Class.new do
      include PDF::Core::Text

      attr_reader :text

      def add_content(str)
        @text ||= +''
        @text << str
      end
    end
    text_mock_class.new
  end

  describe 'horizontal_text_scaling' do
    describe 'called without argument' do
      let(:result) { mock.horizontal_text_scaling }

      it 'functions as accessor' do
        expect(result).to eq(100)
      end
    end

    describe 'called with argument' do
      before do
        mock.horizontal_text_scaling(110) do
          mock.add_content('TEST')
        end
      end

      it 'resets horizontal_text_scaling to original value' do
        expect(mock.horizontal_text_scaling).to eq(100)
      end

      it 'outputs correct PDF content' do
        expect(mock.text).to eq("\n110.0 TzTEST\n100.0 Tz")
      end
    end
  end

  describe 'character_spacing' do
    describe 'called without argument' do
      let(:result) { mock.character_spacing }

      it 'functions as accessor' do
        expect(result).to eq(0)
      end
    end

    describe 'called with argument' do
      before do
        mock.character_spacing(10) do
          mock.add_content('TEST')
        end
      end

      it 'resets character_spacing to original value' do
        expect(mock.character_spacing).to eq(0)
      end

      it 'outputs correct PDF content' do
        expect(mock.text).to eq("\n10.0 TcTEST\n0.0 Tc")
      end
    end
  end
end
