require 'rupy'

# A quick way to activate legacy mode for your project. Requiring
# 'rupy/legacy' automatically activates legacy_mode as described in the
# documentation for {RubyPython}. If you wish to run your project in legacy
# mode you can require 'rupy/legacy' instead of 'rupy'
# 
# @example Default Behavior
#   irb(main):001:0> require 'rupy'
#   => true
#   irb(main):002:0> RubyPython.start
#   => true
#   irb(main):003:0> RubyPython::PyMain.float(42).is_a? RubyPython::RubyPyProxy
#   => true
#   irb(main):004:0> RubyPython.stop
#   => true
#  
# @example Legacy Mode
#   irb(main):001:0> require 'rupy/legacy'
#   => true
#   irb(main):002:0> RubyPython.start
#   => true
#   irb(main):003:0> RubyPython::PyMain.float(42).is_a? Float
#   => true
#   irb(main):004:0> RubyPython.stop
#   => true
module Rupy::LegacyMode
  class << self
    def setup_legacy
      Rupy.legacy_mode = true
    end

    def teardown_legacy
      Rupy.legacy_mode = false
    end
  end
end

Rupy::LegacyMode.setup_legacy
