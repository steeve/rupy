# -*- encoding: utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/lib/rupy/version')

Gem::Specification.new do |s|
  s.name = 'rupy'
  s.version = Rupy::VERSION::STRING

  s.authors = ["Steeve Morin"]
  s.cert_chain = ["/Users/rainesz/.gem/gem-public_cert.pem"]
  s.description = 'Python inside Ruby, the unholly alliance!'
  s.email = ["siwuzzz+rupy@gmail.com"]
  s.extra_rdoc_files = ["License.txt", "Manifest.txt", "PostInstall.txt", "History.markdown"]
  s.files = File.read("Manifest.txt").split(/\r?\n\r?/) 
  s.homepage = 'http://github.com/siwu/rupy/'
  s.has_rdoc = 'yard'
  s.post_install_message = File.read("PostInstall.txt")
  
  s.rdoc_options = ["--markup", "markdown", "--title", "RubyPython Documentation", "--quiet"]
  s.require_paths = ["lib"]
  s.requirements = ["Python, ~>2.4"]
  s.rubyforge_project = 'rupy'
  s.rubygems_version = '1.3.7'
  s.signing_key = '/Users/rainesz/.gem/gem-private_key.pem'
  s.summary = 'A bridge between ruby and python'

  s.add_dependency('ffi', [">= 0.6.3"])
  s.add_dependency('blankslate', [">= 2.1.2.3"])
end

