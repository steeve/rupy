require "rupy/config"
require "rupy/blankobject"

# This module provides the direct user interface for the Rupy extension.
#
# Rupy interfaces to the Python C API via the {Python} module using the Ruby
# FFI gem. However, the end user should only worry about dealing with the
# methods made avaiable via the Rupy module.
#
# Usage
# -----
# It is important to remember that the Python Interpreter must be started
# before the bridge is functional.  This will start the embedded
# interpreter. If this approach is used, the user should remember to call
# Rupy.stop when they are finished with Python.
#
# @example
#     Rupy.start
#     cPickle = Rupy.import "cPickle"
#     puts cPickle.dumps("Rupy is awesome!").rubify
#     Rupy.stop
#
# Legacy Mode vs Normal Mode
# ---------------------------
# By default Rupy always returns a proxy class which refers method calls to
# the wrapped Python object. If you instead would like Rupy to aggressively
# attempt conversion of return values, as it did in Rupy 0.2.x, then you
# should set {Rupy.legacy_mode} to true. In this case Rupy will attempt to
# convert any return value from Python to a native Ruby type, and only
# return a proxy if conversion is not possible. For further examples see
# {Rupy.legacy_mode}.
module Rupy
  class << self
    # Determines whether Rupy is operating in Normal Mode or Legacy Mode. If
    # legacy_mode is true, Rupy switches into a mode compatible with
    # versions < 0.3.0. All Python objects returned by method invocations
    # are automatically converted to natve Ruby Types if Rupy knows how to
    # do this. Only if no such conversion is known are the objects wrapped
    # in proxy objects.  Otherwise Rupy automatically wraps all returned
    # objects as an instance of {RubyPyProxy} or one of its subclasses.
    #
    # @return [Boolean]
    #
    # @example Normal Mode
    #     Rupy.start
    #     string = Rupy.import 'string'
    #
    #     # Here ascii_letters is a proxy object
    #     ascii_letters = string.ascii_letters
    #
    #     # Use the rubify method to convert it to a native type.
    #     puts ascii_letters.rubify
    #     Rupy.stop
    #
    # @example Legacy Mode
    #     Rupy.legacy_mode = true
    #     Rupy.start
    #     string = Rupy.import 'string'
    #
    #     # Here ascii_letters is a native ruby string
    #     ascii_letters = string.ascii_letters
    #
    #     # No explicit conversion is neccessary
    #     puts ascii_letters
    #     Rupy.stop
    attr_accessor :legacy_mode

    def req_all
      require 'rupy/core_ext/string'
      require 'rupy/python'
      require 'rupy/pythonerror'
      require 'rupy/pyobject'
      require 'rupy/rubypyproxy'
      require 'rupy/pymainclass'
      require 'rupy/pygenerator'
    end
    private :req_all

    # Starts up the Python interpreter. This method **must** be run before
    # using any Python code. The only alternatives are use of the {session}
    # and {run} methods.
    #
    # @param options[Hash]  Provides interpreter start options. Principally
    #                       used for providing an alternative Python
    #                       interpreter to start.
    # @return [Boolean] returns true if the interpreter was started here
    #                   and false otherwise
    #
    # @example
    #     Rupy.start
    #     sys = Rupy.import 'sys'
    #     p sys.version # => "2.6.6"
    #     Rupy.stop
    #
    # @example
    #     Rupy.start(:python => 'python2.7')
    #     sys = Rupy.import 'sys'
    #     p sys.version # => "2.7.1"
    #     Rupy.stop
    #
    # @note
    # In the current version of Rupy, it is not possible to change python
    # interpreters in a single Ruby session. This may change in a future
    # version.
    def start(options = {})
      OPTIONS.merge!(options)
      req_all
      return false if Python.Py_IsInitialized != 0
      Python.Py_Initialize
      true
    end

    # Stops the Python interpreter if it is running. Returns true if the
    # intepreter is stopped by this invocation. All wrapped Python objects
    # should be considered invalid after invocation of this method.
    #
    # @return [Boolean] returns true if the interpreter was stopped here
    #                   and false otherwise
    def stop
      req_all

      if Python.Py_IsInitialized != 0
        PyMain.main = nil
        PyMain.builtin = nil
        Rupy::Operators.send :class_variable_set, '@@operator', nil
        Python.Py_Finalize
        Rupy::PyObject::AutoPyPointer.current_pointers.clear
        return true
      end
      false
    end

    # Import a Python module into the interpreter and return a proxy object
    # for it. This is the preferred way to gain access to Python object.
    #
    # @param [String] mod_name the name of the module to import
    #
    # @return [RubyPyModule] a proxy object wrapping the requested module
    def import(mod_name)
      req_all
      pModule = Python.PyImport_ImportModule mod_name
      raise PythonError.handle_error if PythonError.error?
      pymod = PyObject.new pModule
      RubyPyModule.new(pymod)
    end

    # Execute the given block, starting the Python interperter before its
    # execution and stopping the interpreter after its execution. The last
    # expression of the block is returned; be careful that this is not a
    # Python object as it will become invalid when the interpreter is
    # stopped.
    #
    # @param options[Hash]  Provides interpreter start options. Principally
    #                       used for providing an alternative Python
    #                       interpreter to start.
    # @param [Block] block  The code to be executed while the interpreter is
    #                       running
    #
    # @return the result of evaluating the given block
    def session(options = {})
      start(options)
      result = yield
      stop
      result
    end

    # The same as {session} except that the block is executed within the
    # scope of the Rupy module.
    #
    # @param options[Hash]  Provides interpreter start options. Principally
    #                       used for providing an alternative Python
    #                       interpreter to start.
    # @param [Block] block  The code to be executed while the interpreter is
    #                       running
    #
    # @return the result of evaluating the given block
    def run(options = {}, &block)
      start(options)
      result = module_eval(&block)
      stop
      result
    end

    def activate
      imp = import("imp")
      imp.load_source("activate_this", File.join(File.dirname(OPTIONS[:python]), "activate_this.py"))
    end
    private :activate

    # Starts up the Python interpreter. This method **must** be run before
    # using any Python code. The only alternatives are use of the {session}
    # and {run} methods.
    #
    # @param virtualenv[String] Provides the root path to the virtualenv-
    #                           installed Python.
    # @return [Boolean] returns true if the interpreter was started here
    #                   and false otherwise
    #
    # @example
    #     Rupy.start_from_virtualenv('/path/to/virtualenv')
    #     sys = Rupy.import 'sys'
    #     p sys.version # => "2.7.1"
    #     Rupy.stop
    #
    # @note
    # In the current version of Rupy, it is not possible to change python
    # interpreters in a single Ruby session. This may change in a future
    # version.
    def start_from_virtualenv(virtualenv)
      result = start(:python => File.join(virtualenv, "bin", "python"))
      activate
      result
    end
  end
end
