# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PDF::Core do
  example_group 'Decimal rounding' do
    it 'rounds floating point numbers to four decimal places' do
      expect(described_class.real(1.23456789)).to eq '1.23457'
    end

    it 'is able to create a PDF parameter list of rounded decimals' do
      expect(described_class.real_params([1, 2.345678, Math::PI]))
        .to eq '1.0 2.34568 3.14159'
    end
  end
end
