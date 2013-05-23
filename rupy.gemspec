# -*- encoding: utf-8 -*-
# require File.expand_path(File.dirname(__FILE__) + '/lib/rupy/version')

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'rupy/version'


Gem::Specification.new do |s|
    s.name = 'rupy'
    s.version = Rupy::VERSION

    s.authors = ["Steeve Morin"]
    s.description = 'Python inside Ruby, the unholly alliance!'
    s.email = ["siwuzzz+rupy@gmail.com"]
    s.extra_rdoc_files = ["License.rdoc", "PostInstall.txt", "History.rdoc"]

    # s.files = ["lib", "spec"].map do |dir|
    #     `find #{dir}`.split(/\r?\n\r?/)
    # end.flatten
    # s.files += [ "README.rdoc", "License.rdoc", "Rakefile" ]
    s.files = Dir['lib/**/*'] + Dir['bin/**/*'] + ['README.rdoc', 'License.rdoc', 'PostInstall.txt']

    s.homepage = 'http://github.com/siwu/rupy/'
    s.has_rdoc = 'yard'
    s.post_install_message = File.read("PostInstall.txt")

    s.rdoc_options = ["--markup", "markdown", "--title", "Rupy Documentation", "--quiet"]
    s.require_paths = ["lib"]
    s.requirements = ["Python, ~>2.4"]
    s.rubyforge_project = 'rupy'
    s.rubygems_version = '1.3.7'
    s.summary = 'Python inside Ruby, the unholly alliance!'

    s.add_dependency('ffi', [">= 0.6.3"])
    s.add_dependency('blankslate', [">= 2.1.2.3"])
end

