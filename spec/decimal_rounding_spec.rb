require_relative 'spec_helper'

RSpec.describe 'Decimal rounding' do
  it 'rounds floating point numbers to four decimal places' do
    expect(PDF::Core.real(1.23456789)).to eq 1.2346
  end

  it 'is able to create a PDF parameter list of rounded decimals' do
    expect(PDF::Core.real_params([1, 2.34567, Math::PI]))
      .to eq '1.0 2.3457 3.1416'
  end
end
