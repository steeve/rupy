# -*- ruby -*-
# -*- encoding: utf-8 -*-

require 'rubygems'
require 'hoe'

Hoe.plugin :doofus
Hoe.plugin :gemspec
Hoe.plugin :git

Hoe.spec 'rupy' do
  developer('Steeve Morin', 'swiuzzz+rupy@gmail.com')
  developer('Austin Ziegler', 'austin@rubyforge.org')

  self.history_file = 'History.rdoc'
  self.readme_file = 'README.rdoc'
  self.extra_rdoc_files = FileList["*.rdoc"].to_a

  self.extra_deps << ['ffi', '~> 1.0']
  self.extra_deps << ['blankslate', '>= 2.1.2.3']

  self.spec_extras[:requirements]  = [ "Python, ~> 2.4" ]
end

# vim: syntax=ruby
