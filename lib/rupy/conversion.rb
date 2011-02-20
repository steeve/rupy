require 'rupy/python'
require 'rupy/macros'

# This modules encapsulates the work of converting between native Ruby and
# Python types. Unsupported conversions raise {UnsupportedConversion}.
module Rupy::Conversion
  # Raised when Rupy does not know how to convert an object from Python to
  # Ruby or vice versa.
  class UnsupportedConversion < Exception; end

  # Convert a Ruby string to a Python string.
  def self.rtopString(rString)
    Rupy::Python.PyString_FromString(rString)
  end

  # Convert a Ruby Array to Python List
  def self.rtopArrayToList(rArray)
    size = rArray.length
    pList = Rupy::Python.PyList_New size
    rArray.each_with_index do |el, i|
      Rupy::Python.PyList_SetItem pList, i, rtopObject(el)
    end
    pList
  end

  # Convert a Ruby Array to Python Tuple
  def self.rtopArrayToTuple(rArray)
    pList = rtopArrayToList(rArray)
    pTuple = Rupy::Python.PySequence_Tuple(pList)
    Rupy::Python.Py_DecRef(pList)
    pTuple
  end

  # Convert a Ruby Hash to a Python Dictionary
  def self.rtopHash(rHash)
    pDict = Rupy::Python.PyDict_New
    rHash.each do |k,v|
      Rupy::Python.PyDict_SetItem pDict, rtopObject(k, key=true), rtopObject(v)
    end
    pDict
  end

  # Convert a Ruby Fixnum to a Python Int
  def self.rtopFixnum(rNum)
    Rupy::Python.PyInt_FromLong(rNum)
  end

  # Convert a Ruby Big Number to a Pythong Long
  def self.rtopBigNum(rNum)
    Rupy::Python.PyLong_FromLong(rNum)
  end

  # Convert a Ruby float to a Python float.
  def self.rtopFloat(rNum)
    Rupy::Python.PyFloat_FromDouble(rNum)
  end

  # Convert a Ruby false to a Python False.
  def self.rtopFalse
    Rupy::Macros.Py_RETURN_FALSE
  end

  # Convert a Ruby true to a Python True.
  def self.rtopTrue
    Rupy::Macros.Py_RETURN_TRUE
  end

  # Convert a Ruby nil to a Python None.
  def self.rtopNone
    Rupy::Macros.Py_RETURN_NONE
  end

  # Convert a Ruby Symbol to a Python String
  def self.rtopSymbol(rSymbol)
    Rupy::Python.PyString_FromString rSymbol.to_s
  end

  # If possible converts a ruby type to an equivalent python native type.
  # @param rObj a native ruby type
  # @param [Boolean] is_key whether this object will be used as a key in a
  #                  python dict.
  # @return [FFI::Pointer] a to a C PyObject\*
  # @raise [UnsupportedConversion]
  def self.rtopObject(rObj, is_key = false)
    case rObj
    when String
      rtopString rObj
    when Array
      # If this object is going to be used as a hash key we should make it
      # a tuple instead of a list
      if is_key
        rtopArrayToTuple rObj
      else
        rtopArrayToList rObj
      end
    when Hash
      rtopHash rObj
    when Fixnum
      rtopFixnum rObj
    when Bignum
      rtopBignum rObj
    when Float
      rtopFloat rObj
    when true
      rtopTrue
    when false
      rtopFalse
    when Symbol
      rtopSymbol rObj
    when Proc, Method
      if Rupy.legacy_mode
        raise UnsupportedConversion.new("Python to Ruby callbacks not suppported in legacy mode")
      end
      rtopFunction rObj
    when Method
      rtopFunction rObj
    when nil
      rtopNone
    when Rupy::PyObject
      rObj.pointer
    else
      raise UnsupportedConversion.new("Unsupported type for RTOP conversion.")
    end
  end

  # Convert a Python String to a Ruby String
  def self.ptorString(pString)
    Rupy::Python.PyString_AsString(pString)
  end

  # Convert a Python List to a Ruby Array.
  def self.ptorList(pList)
    rb_array = []
    list_size = Rupy::Python.PyList_Size(pList)

    list_size.times do |i|
      element = Rupy::Python.PyList_GetItem(pList, i)
      Rupy::Python.Py_IncRef element
      rObject = ptorObject(element)
      rb_array.push rObject
    end

    rb_array
  end

  # Convert a Python Int to a Ruby Fixnum
  def self.ptorInt(pNum)
    Rupy::Python.PyInt_AsLong pNum
  end

  # Convert a Python Long to a Ruby Fixnum
  def self.ptorLong(pNum)
    Rupy::Python.PyLong_AsLong(pNum)
    # TODO Overflow Checking
  end

  # Convert a Python Float to a Ruby Float
  def self.ptorFloat(pNum)
    Rupy::Python.PyFloat_AsDouble(pNum)
  end

  # Convert a Python Tuple to a Ruby Array
  def self.ptorTuple(pTuple)
    pList = Rupy::Python.PySequence_List pTuple
    rArray = ptorList pList
    Rupy::Python.Py_DecRef pList
    rArray
  end

  # Convert a Python Dictionary to a Ruby Hash
  def self.ptorDict(pDict)
    rb_hash = {}

    pos = FFI::MemoryPointer.new :ssize_t
    pos.write_int 0
    key = FFI::MemoryPointer.new :pointer
    val = FFI::MemoryPointer.new :pointer

    while Rupy::Python.PyDict_Next(pDict, pos, key, val) != 0
      pKey = key.read_pointer
      pVal = val.read_pointer
      rKey = ptorObject(pKey)
      rVal = ptorObject(pVal)
      rb_hash[rKey] = rVal
    end

    rb_hash
  end

  # Convert a Ruby Proc to a Python Function.
  def self.rtopFunction(rObj)
    proc = FFI::Function.new(:pointer, [:pointer, :pointer]) do |p_self, p_args|
      retval = rObj.call(*ptorTuple(p_args))
      pObject = retval.is_a?(Rupy::RubyPyProxy) ? retval.pObject : Rupy::PyObject.new(retval)

      # make sure the refcount is >1 when pObject is destroyed
      pObject.xIncref
      pObject.pointer
    end

    defn = Rupy::Python::PyMethodDef.new
    defn[:ml_name] = FFI::MemoryPointer.from_string("Rupy::Proc::%s" % rObj.object_id)
    defn[:ml_meth] = proc
    defn[:ml_flags] = Rupy::Python::METH_VARARGS
    defn[:ml_doc] = nil

    return Rupy::Python.PyCFunction_New(defn, nil)
  end

  # Converts a pointer to a Python object into a native ruby type, if
  # possible. Otherwise raises an error.
  # @param [FFI::Pointer] pObj a pointer to a Python object
  # @return a native ruby object.
  # @raise {UnsupportedConversion}
  def self.ptorObject(pObj)
    if Rupy::Macros.PyObject_TypeCheck(pObj, Rupy::Python.PyString_Type.to_ptr) != 0
      ptorString pObj
    elsif Rupy::Macros.PyObject_TypeCheck(pObj, Rupy::Python.PyList_Type.to_ptr) != 0
      ptorList pObj
    elsif Rupy::Macros.PyObject_TypeCheck(pObj, Rupy::Python.PyInt_Type.to_ptr) != 0
      ptorInt pObj
    elsif Rupy::Macros.PyObject_TypeCheck(pObj, Rupy::Python.PyLong_Type.to_ptr) != 0
      ptorLong pObj
    elsif Rupy::Macros.PyObject_TypeCheck(pObj, Rupy::Python.PyFloat_Type.to_ptr) != 0
      ptorFloat pObj
    elsif Rupy::Macros.PyObject_TypeCheck(pObj, Rupy::Python.PyTuple_Type.to_ptr) != 0
      ptorTuple pObj
    elsif Rupy::Macros.PyObject_TypeCheck(pObj, Rupy::Python.PyDict_Type.to_ptr) != 0
      ptorDict pObj
    elsif pObj == Rupy::Macros.Py_True
      true
    elsif pObj == Rupy::Macros.Py_False
      false
    elsif pObj == Rupy::Macros.Py_None
      nil
    else
      pObj
    end
  end
end
