require File.dirname(__FILE__) + '/spec_helper.rb'

describe Rupy do
  describe "#import" do
    it "should handle multiple imports" do
      lambda do
        Rupy.import 'cPickle'
        Rupy.import 'urllib'
      end.should_not raise_exception
    end

    it "should propagate Python errors" do
      lambda do
        Rupy.import 'nonExistentModule'
      end.should raise_exception(Rupy::PythonError)
    end

    it "should return a RubyPyModule" do
      Rupy.import('urllib2').should be_a(Rupy::RubyPyModule)
    end
  end
end

describe Rupy, "#session" do
  it "should start interpreter" do
    Rupy.session do
      cPickle = Rupy.import "cPickle"
      cPickle.loads("(dp1\nS'a'\nS'n'\ns(I1\nS'2'\ntp2\nI4\ns.").rubify.should == {"a"=>"n", [1, "2"]=>4}
    end
  end

  it "should stop the interpreter" do
    Rupy.session do
      cPickle = Rupy.import "cPickle"
    end

    Rupy.stop.should be_false
  end
end

describe Rupy, "#run" do
  it "should start interpreter" do
    Rupy.run do
      cPickle = import "cPickle"
      cPickle.loads("(dp1\nS'a'\nS'n'\ns(I1\nS'2'\ntp2\nI4\ns.").rubify.should == {"a"=>"n", [1, "2"]=>4}
    end
  end

  it "should stop the interpreter" do
    Rupy.run do
      cPickle = import "cPickle"
    end

    Rupy.stop.should be_false
  end
end
