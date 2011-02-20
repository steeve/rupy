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

describe Rupy, '#reload_library', :slow => true do
  it 'leaves Rupy in a stable state' do
    lambda do 
      Rupy.instance_eval { reload_library }
      Rupy.run {}
    end.should_not raise_exception
  end
end

describe Rupy, '.configure', :slow => true do
  it 'allows python executable to be specified', :unless => `which python2.6`.empty? do
    Rupy.configure :python_exe => 'python2.6'
    Rupy.run do
      sys = Rupy.import 'sys'
      sys.version.rubify.to_f.should == 2.6
    end
  end

  after(:all) do
    Rupy.clear_options
    Rupy.instance_eval { reload_library }
  end
end
