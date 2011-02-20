require File.dirname(__FILE__) + '/spec_helper.rb'

include TestConstants

describe "Rupy Basics" do
  it "should work with cPickle" do
    cPickle = Rupy.import("cPickle")
    string = cPickle.dumps("Testing rupy")
    string.should_not be_a_kind_of String
    string.rubify.should be_a_kind_of String
  end
end
