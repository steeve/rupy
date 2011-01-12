require "rupy/python"
require "rupy/conversion"
require 'rupy/macros'
require 'rupy/conversion'
require 'rupy/pyobject'
require "rupy/pymainclass"
require "rupy/rubypyproxy"

module Rupy
    class << self
        def generator_type
            @generator_type ||= lambda do
                code = <<-eof
def rupy_generator(callback):
    while True:
        yield callback()
                eof

                globals = PyObject.new({
                    "__builtins__" => PyMain.builtin.pObject,
                })
                empty_hash = PyObject.new({})
                ptr = Python.PyRun_String(code, Python::PY_FILE_INPUT, globals.pointer, empty_hash.pointer)
                ptr = Python.PyRun_String("rupy_generator", Python::PY_EVAL_INPUT, globals.pointer, empty_hash.pointer)
                if PythonError.error?
                    raise PythonError.handle_error
                end
                RubyPyProxy.new(PyObject.new(ptr))
            end.call
        end

        def generator
            return lambda do |*args|
                fib = Fiber.new do
                    yield *args
                    Python.PyErr_SetNone(Python.PyExc_StopIteration)
                    FFI::Pointer::NULL
                end
                generator_type.__call__(lambda do
                    fib.resume
                end)
            end
        end

        def yield(*args)
            Fiber.yield(*args)
        end
    end
end