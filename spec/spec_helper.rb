# frozen_string_literal: true

puts "PDF::Core specs: Running on Ruby Version: #{RUBY_VERSION}"

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start
end

require_relative '../lib/pdf/core'

require 'rspec'
require 'pdf/reader'
require 'pdf/inspector'

RSpec.configure do |config|
  config.disable_monkey_patching!
end

RSpec::Matchers.define :have_parseable_xobjects do
  match do |actual|
    expect { PDF::Inspector::XObject.analyze(actual.render) }.not_to raise_error
    true
  end
  failure_message_for_should do |actual|
    "expected that #{actual}'s XObjects could be successfully parsed"
  end
end
