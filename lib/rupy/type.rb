module Rupy
  def self.Type(name)
    mod, match, klass = name.rpartition(".")
    pymod = Rupy.import(mod)
    pyclass = pymod.pObject.getAttr(klass)
    rclass = Class.new(RubyPyProxy) do
      define_method(:initialize) do |*args|
        args = PyObject.convert(*args)
        pTuple = PyObject.buildArgTuple(*args)
        pReturn = pyclass.callObject(pTuple)
        if PythonError.error?
          raise PythonError.handle_error
        end
        @pObject = pReturn
      end
    end
    return rclass
  end
end
