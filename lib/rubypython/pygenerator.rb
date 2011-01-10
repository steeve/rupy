require "rubypython/python"
require "rubypython/conversion"
require 'rubypython/macros'
require 'rubypython/conversion'
require 'rubypython/pyobject'
require "rubypython/pymainclass"
require "rubypython/rubypyproxy"

module RubyPython
    class << self
        def eval(code)
            globals = PyObject.new({
                "__builtins__" => PyMain.builtin.pObject,
            })
            empty_hash = PyObject.new({})
            ptr = Python.PyRun_String(code, Python::PY_FILE_INPUT, globals.pointer, empty_hash.pointer)
        end
        
        def generator_type
            @generator_type ||= lambda do
                code = <<-eof
class RupyIterator(object):
    def __init__(self, callback):
        self.callback = callback

    def __iter__(self):
        return self

    def next(self):
        return self.callback()
                eof

                globals = PyObject.new({
                    "__builtins__" => PyMain.builtin.pObject,
                })
                empty_hash = PyObject.new({})
                ptr = Python.PyRun_String(code, Python::PY_FILE_INPUT, globals.pointer, empty_hash.pointer)
                ptr = Python.PyRun_String("RupyIterator", Python::PY_EVAL_INPUT, globals.pointer, empty_hash.pointer)
                if PythonError.error?
                    raise PythonError.handle_error
                end
                RubyPyClass.new(PyObject.new(ptr))
            end.call
        end

        def generator
            fib = Fiber.new do
                yield
                Python.PyErr_SetNone(Python.PyExc_StopIteration)
                FFI::Pointer::NULL
            end
            return lambda { generator_type.new(lambda { fib.resume }).pObject.pointer }
        end
    end
end