require File.dirname(__FILE__) + '/spec_helper.rb'

include TestConstants

describe "Rupy Basics" do
  it "should work with cPickle" do
    cPickle = Rupy.import("cPickle")
    string = cPickle.dumps("Testing rupy")
    string.should_not be_a_kind_of String
    string.rubify.should be_a_kind_of String
  end


  it "should handle import nested modules" do
    # from email.mime import text (NOTE: case sensitive)
    email_mime_text = Rupy.import "email.mime.Text"
    email_mime_text.rubify
  end


end
