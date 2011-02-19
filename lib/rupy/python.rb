require 'ffi'
require 'rupy/config'

module Rupy
  # This module provides access to the Python C API functions via the Ruby
  # ffi gem. Documentation for these functions may be found
  # [here](http://docs.python.org/c-api/). Likewise the FFI gem
  # documentation may be found [here](http://rdoc.info/projects/ffi/ffi).
  module Python
    extend FFI::Library

    # The class is a little bit of a hack to extract the address of global
    # structs. If someone knows a better way please let me know.
    class DummyStruct < FFI::Struct
      layout :dummy_var, :int
    end

    METH_VARARGS = 0x0001
    PY_FILE_INPUT = 257
    PY_EVAL_INPUT = 258

    class PythonExec
      def initialize(python_executable)
        @python = python_executable
        if @python.nil?
          @python = %x(python -c "import sys; print sys.executable").chomp
        end

        @version = run_command 'import sys; print "%d.%d" % sys.version_info[:2]'
        @realname = "#{@python}#{@version}"
        @sys_prefix = run_command 'import sys; print sys.prefix'
        @library = find_python_lib
        @ffi = load_ffi
        self.freeze
      end

      def find_python_lib
        # By default, the library name will be something like
        # libpython2.6.so, but that won't always work.
        libbase = "#{FFI::Platform::LIBPREFIX}#{@realname}"
        libext = FFI::Platform::LIBSUFFIX
        libname = "#{libbase}.#{libext}"

        # We may need to look in multiple locations for Python, so let's
        # build this as an array.
        locations = [ File.join(@sys_prefix, "lib", libname) ]

        if FFI::Platform.mac?
          # On the Mac, let's add a special case that has even a different
          # libname. This may not be fully useful on future versions of OS
          # X, but it should work on 10.5 and 10.6. Even if it doesn't, the
          # next step will (/usr/lib/libpython<version>.dylib is a symlink
          # to the correct location).
          locations << File.join(@sys_prefix, "Python")
          # Let's also look in the location that was originally set in this
          # library:
          File.join(@sys_prefix, "lib", "#{@realname}", "config", libname)
        end

        if FFI::Platform.unix?
          # On Unixes, let's look in some standard alternative places, too.
          # Just in case.
          locations << File.join("/opt/local/lib", libname)
          locations << File.join("/opt/lib", libname)
          locations << File.join("/usr/local/lib", libname)
          locations << File.join("/usr/lib", libname)
        end

        # Let's add alternative extensions; again, just in case.
        locations.dup.each do |location|
          path = File.dirname(location)
          base = File.basename(location, libext)
          locations << File.join(path, "#{base}.so")    # Standard Unix
          locations << File.join(path, "#{base}.dylib") # Mac OS X
          locations << File.join(path, "#{base}.dll")   # Windows
          locations << File.join(path, "#{base}.a")     # Non-DLL
        end

        # Remove redundant locations
        locations.uniq!

        library = nil

        locations.each do |location|
          if File.exists? location
            library = location
            break
          end
        end

        library
      end
      private :find_python_lib

      def load_ffi
        dyld_flags = FFI::DynamicLibrary::RTLD_LAZY |
          FFI::DynamicLibrary::RTLD_GLOBAL
        [ FFI::DynamicLibrary.open(self.library, dyld_flags) ]
      end
      private :load_ffi

      # The python executable to use.
      attr_reader :python
      # The realname of the python executable (with version).
      attr_reader :realname
      # The sys.prefix for Python.
      attr_reader :sys_prefix
      # The Python library.
      attr_reader :library
      # The FFI library interface
      attr_reader :ffi

      def run_command(command)
        %x(#{@python} -c '#{command}').chomp
      end

      def to_s
        @realname
      end
    end

    PYTHON = PythonExec.new(OPTIONS[:python])
    PYTHON_LIB = PYTHON.library
    @ffi_libs = PYTHON.ffi

    # Function methods
    attach_function :PyCFunction_New, [:pointer, :pointer], :pointer
    attach_function :PyRun_String, [:string, :int, :pointer, :pointer], :pointer
    attach_function :PyRun_SimpleString, [:string], :pointer
    attach_function :Py_CompileString, [:string, :string, :int], :pointer
    attach_function :PyEval_EvalCode, [:pointer, :pointer, :pointer], :pointer
    attach_function :PyErr_SetString, [:pointer, :string], :void

    # Python interpreter startup and shutdown
    attach_function :Py_IsInitialized, [], :int
    attach_function :Py_Initialize, [], :void
    attach_function :Py_Finalize, [], :void

    # Module methods
    attach_function :PyImport_ImportModule, [:string], :pointer

    # Object Methods
    attach_function :PyObject_HasAttrString, [:pointer, :string], :int
    attach_function :PyObject_GetAttrString, [:pointer, :string], :pointer
    attach_function :PyObject_SetAttrString, [:pointer, :string, :pointer], :int
    attach_function :PyObject_Dir, [:pointer], :pointer

    attach_function :PyObject_Compare, [:pointer, :pointer], :int

    attach_function :PyObject_CallObject, [:pointer, :pointer], :pointer
    attach_function :PyCallable_Check, [:pointer], :int

    ### Python To Ruby Conversion
    # String Methods
    attach_function :PyString_AsString, [:pointer], :string
    attach_function :PyString_FromString, [:string], :pointer

    # List Methods
    attach_function :PyList_GetItem, [:pointer, :int], :pointer
    attach_function :PyList_Size, [:pointer], :int
    attach_function :PyList_New, [:int], :pointer
    attach_function :PyList_SetItem, [:pointer, :int, :pointer], :void

    # Integer Methods
    attach_function :PyInt_AsLong, [:pointer], :long
    attach_function :PyInt_FromLong, [:long], :pointer

    attach_function :PyLong_AsLong, [:pointer], :long
    attach_function :PyLong_FromLong, [:pointer], :long

    # Float Methods
    attach_function :PyFloat_AsDouble, [:pointer], :double
    attach_function :PyFloat_FromDouble, [:double], :pointer

    # Tuple Methods
    attach_function :PySequence_List, [:pointer], :pointer
    attach_function :PySequence_Tuple, [:pointer], :pointer
    attach_function :PyTuple_Pack, [:int, :varargs], :pointer

    # Dict/Hash Methods
    attach_function :PyDict_Next, [:pointer, :pointer, :pointer, :pointer], :int
    attach_function :PyDict_New, [], :pointer
    attach_function :PyDict_SetItem, [:pointer, :pointer, :pointer], :int
    attach_function :PyDict_Contains, [:pointer, :pointer], :int
    attach_function :PyDict_GetItem, [:pointer, :pointer], :pointer

    # Error Methods
    attach_variable :PyExc_Exception, DummyStruct.by_ref
    attach_variable :PyExc_StopIteration, DummyStruct.by_ref
    attach_function :PyErr_SetNone, [:pointer], :void
    attach_function :PyErr_Fetch, [:pointer, :pointer, :pointer], :void
    attach_function :PyErr_Occurred, [], :pointer
    attach_function :PyErr_Clear, [], :void

    # Reference Counting
    attach_function :Py_IncRef, [:pointer], :void
    attach_function :Py_DecRef, [:pointer], :void

    # Type Objects
    # attach_variable :PyBaseObject_Type, DummyStruct.by_value # built-in 'object' 
    # attach_variable :PyBaseString_Type, DummyStruct.by_value
    # attach_variable :PyBool_Type, DummyStruct.by_value
    # attach_variable :PyBuffer_Type, DummyStruct.by_value
    # attach_variable :PyByteArrayIter_Type, DummyStruct.by_value
    # attach_variable :PyByteArray_Type, DummyStruct.by_value
    attach_variable :PyCFunction_Type, DummyStruct.by_value
    # attach_variable :PyCObject_Type, DummyStruct.by_value
    # attach_variable :PyCallIter_Type, DummyStruct.by_value
    # attach_variable :PyCapsule_Type, DummyStruct.by_value
    # attach_variable :PyCell_Type, DummyStruct.by_value
    # attach_variable :PyClassMethod_Type, DummyStruct.by_value
    attach_variable :PyClass_Type, DummyStruct.by_value
    # attach_variable :PyCode_Type, DummyStruct.by_value
    # attach_variable :PyComplex_Type, DummyStruct.by_value
    # attach_variable :PyDictItems_Type, DummyStruct.by_value
    # attach_variable :PyDictIterItem_Type, DummyStruct.by_value
    # attach_variable :PyDictIterKey_Type, DummyStruct.by_value
    # attach_variable :PyDictIterValue_Type, DummyStruct.by_value
    # attach_variable :PyDictKeys_Type, DummyStruct.by_value
    # attach_variable :PyDictProxy_Type, DummyStruct.by_value
    # attach_variable :PyDictValues_Type, DummyStruct.by_value
    attach_variable :PyDict_Type, DummyStruct.by_value
    # attach_variable :PyEllipsis_Type, DummyStruct.by_value
    # attach_variable :PyEnum_Type, DummyStruct.by_value
    # attach_variable :PyFile_Type, DummyStruct.by_value
    attach_variable :PyFloat_Type, DummyStruct.by_value
    # attach_variable :PyFrame_Type, DummyStruct.by_value
    # attach_variable :PyFrozenSet_Type, DummyStruct.by_value
    attach_variable :PyFunction_Type, DummyStruct.by_value
    # attach_variable :PyGen_Type, DummyStruct.by_value
    # attach_variable :PyGetSetDescr_Type, DummyStruct.by_value
    # attach_variable :PyInstance_Type, DummyStruct.by_value
    attach_variable :PyInt_Type, DummyStruct.by_value
    attach_variable :PyList_Type, DummyStruct.by_value
    attach_variable :PyLong_Type, DummyStruct.by_value
    # attach_variable :PyMemberDescr_Type, DummyStruct.by_value
    # attach_variable :PyMemoryView_Type, DummyStruct.by_value
    attach_variable :PyMethod_Type, DummyStruct.by_value
    # attach_variable :PyModule_Type, DummyStruct.by_value
    # attach_variable :PyNullImporter_Type, DummyStruct.by_value
    # attach_variable :PyProperty_Type, DummyStruct.by_value
    # attach_variable :PyRange_Type, DummyStruct.by_value
    # attach_variable :PyReversed_Type, DummyStruct.by_value
    # attach_variable :PySTEntry_Type, DummyStruct.by_value
    # attach_variable :PySeqIter_Type, DummyStruct.by_value
    # attach_variable :PySet_Type, DummyStruct.by_value
    # attach_variable :PySlice_Type, DummyStruct.by_value
    # attach_variable :PyStaticMethod_Type, DummyStruct.by_value
    attach_variable :PyString_Type, DummyStruct.by_value
    # attach_variable :PySuper_Type, DummyStruct.by_value # built-in 'super' 
    # attach_variable :PyTraceBack_Type, DummyStruct.by_value
    attach_variable :PyTuple_Type, DummyStruct.by_value
    attach_variable :PyType_Type, DummyStruct.by_value
    # attach_variable :PyUnicode_Type, DummyStruct.by_value
    # attach_variable :PyWrapperDescr_Type, DummyStruct.by_value

    attach_variable :Py_TrueStruct, :_Py_TrueStruct, DummyStruct.by_value
    attach_variable :Py_ZeroStruct, :_Py_ZeroStruct, DummyStruct.by_value
    attach_variable :Py_NoneStruct, :_Py_NoneStruct, DummyStruct.by_value

    # This is an implementation of the basic structure of a Python
    # PyObject struct. The C struct is actually much larger, but since we
    # only access the first two data members via FFI and always deal with
    # struct pointers there is no need to mess around with the rest of the
    # object.
    class PyObjectStruct < FFI::Struct
      layout :ob_refcnt, :ssize_t,
        :ob_type, :pointer
    end

    class PyMethodDef < FFI::Struct
      layout :ml_name, :pointer, :ml_meth, :pointer, :ml_flags, :int,
        :ml_doc, :pointer
    end
  end
end
