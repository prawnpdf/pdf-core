# frozen_string_literal: true

require 'rake'
require 'rspec/core/rake_task'

task default: %i[spec rubocop]

desc 'Run all rspec files'
RSpec::Core::RakeTask.new('spec') do |c|
  c.rspec_opts = '-t ~unresolved'
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new

require 'rubygems/package_task'
spec = Gem::Specification.load 'pdf-core.gemspec'
Gem::PackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

task :checksum do
  require 'digest/sha2'
  built_gem_path = "pkg/pdf-core-#{spec.version}.gem"
  gem_file_name = File.basename(built_gem_path)
  checksum = Digest::SHA512.new.hexdigest(File.read(built_gem_path))
  checksum_path = "checksums/#{gem_file_name}.sha512"
  File.write(checksum_path, checksum)
end
