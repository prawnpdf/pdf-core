# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'pdf-core'
  spec.version = '0.9.0'
  spec.platform = Gem::Platform::RUBY
  spec.summary = 'PDF::Core is used by Prawn to render PDF documents'
  spec.files =
    Dir.glob('lib/**/**/*') +
    %w[COPYING GPLv2 GPLv3 LICENSE] +
    %w[Gemfile Rakefile] +
    ['pdf-core.gemspec']
  spec.require_path = 'lib'
  spec.required_ruby_version = '>= 2.6'
  spec.required_rubygems_version = '>= 1.3.6'

  signing_key = File.expand_path('~/.gem/gem-private_key.pem')
  if File.exist?(signing_key)
    spec.cert_chain = ['certs/pointlessone.pem']
    if $PROGRAM_NAME.end_with?('gem')
      spec.signing_key = signing_key
    end
  else
    warn 'WARNING: Signing key is missing. The gem is not signed and its authenticity can not be verified.'
  end

  spec.authors = [
    'Gregory Brown', 'Brad Ediger', 'Daniel Nelson', 'Jonathan Greenberg',
    'James Healy',
  ]
  spec.email = [
    'gregory.t.brown@gmail.com', 'brad@bradediger.com', 'dnelson@bluejade.com',
    'greenberg@entryway.net', 'jimmy@deefa.com',
  ]
  spec.licenses = %w[PRAWN GPL-2.0 GPL-3.0]
  spec.add_development_dependency('pdf-inspector', '~> 1.1.0')
  spec.add_development_dependency('pdf-reader', '~>1.2')
  spec.add_development_dependency('prawn-dev', '~> 0.4.0')
  spec.homepage = 'http://prawnpdf.org'
  spec.description = 'PDF::Core is used by Prawn to render PDF documents'
end
