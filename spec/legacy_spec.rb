require File.dirname(__FILE__) + '/spec_helper.rb'

include TestConstants

describe 'Rupy Legacy Mode Module' do
  before :all do
    require 'rupy/legacy'
  end

  after :all do
    Rupy::LegacyMode.teardown_legacy
  end

  describe "when required" do
    it "should enable legacy mode" do
      Rupy.legacy_mode.should == true
    end
  end
end
