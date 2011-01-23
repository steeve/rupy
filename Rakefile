require 'rake'
require 'rspec/core/rake_task'
require 'yard'

desc "Run all examples"
RSpec::Core::RakeTask.new('spec') do |t|
  t.rspec_opts = %w(-c -f d)
  t.pattern = 'spec/**/*_spec.rb'
end

desc "Run all examples with RCov"
RSpec::Core::RakeTask.new('spec:rcov') do |t|
  t.rspec_opts = %w(-c -f progress)
  t.pattern = 'spec/**/*_spec.rb'
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec']
end

YARD::Rake::YardocTask.new do |t|
  t.options = [ '--markup','markdown', '--title', 'Rupy Documentation' ]
end

Dir['tasks/**/*.rake'].each { |rake| load rake }
