require File.dirname(__FILE__) + '/spec_helper.rb'

describe Rupy::RubyPyClass do
  include RubyPythonStartStop

  describe "#new" do
    it "should return a RubyPyInstance" do
      urllib2 = Rupy.import 'urllib2'
      urllib2.Request.new('google.com').should be_a(Rupy::RubyPyInstance)
    end
  end

end
