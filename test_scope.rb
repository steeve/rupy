require "rubygems"
#$:.unshift File.join(File.dirname(__FILE__), 'lib')
require "ffi"
require "blankslate"
#require "rubypython/config"

require "rubypython"
#require "rubypython/rubypyproxy"



RubyPython.start :python => "/Users/smorin/projects/popeye.old/epg/bin/python"
RubyPython.activate

p RubyPython.import("lxml")

sys = RubyPython.import("sys")
sys.path.append(".")

p sys.methods

mymod = RubyPython.import("mymod")

n = mymod.get_generator.to_enum

n.each_with_index do |i, x|
    p i
    p x
end


RubyPython.stop