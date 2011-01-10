# rupy
Rupy is a fork of Zach Raines's awesome [RubyPython](http://raineszm.bitbucket.org/rubypython/) project.

## Description

Rupy is a gem that make it possible to instanciate a Python VM inside the Ruby VM,
thanks to the Python C API. Allowing you to effectively call Python code (and back)
from Ruby!
The calls and marshaling are done using FFI.

## Why ?

Because I'm in love with both languages and want to be able to take what's best from each.
This is an idea that was in my head for quite some time, and seeing that Zach Raine didn't
develop (well, not much) RubyPython more, I decided to implement what was missing to address
my use cases.

## How to use

### Basic usage

    require "rupy"

    # start the Python VM
    Rupy.start

    cPickle = Rupy.import("cPickle")
    p cPickle.dumps("Testing rupy").rubify

    # stop the Python VM
    Rupy.stop


### Custom Python

    Ruby.start(:python => "/path/to/my/python")


### VirtualEnv

    # Easy
    Rupy.start_from_virtualenv("/path/to/virtualenv")

    # Or verbose
    Rupy.start(:python => "/path/to/virtualenv/bin/python")
    Rupy.activate


### Iterator support

    # Python
    def readfile():
        for line in open("/some/file"):
            yield line

    # Ruby
    readfile.to_enum.each do |line|
        puts line
    end


### Python to Ruby callbacks

    # Python
    def dosomething(callback):
        print callback(5)

    # Ruby
    dosomething(lambda do |value|
        value * 2
    end)

    def mycallback(value)
        return value * 2
    end

    dosomething(method(:mycallback))


### Python-style Generators

    # Python
    def test_generator(callback):
        for i in callback():
            print "Got %d" % i

    # Ruby
    test_generator(Rupy.generator do
        (0..10).each do |i|
            Rupy.yield i
        end
    end)



## What's planned

### Maybe nice imports ? (if I ever manage to get around those !@# Kernel.bindings)

    Py: from mod2.mod1 import sym as mysym
    Rb: py :from "mod2.mod1", :import => "sym", :as => "mysym"
        py :from "mod2.mod1", :import => :sym, :as => :mysym
        py :from [ :mod2, :mod1 ], :import => :sym, :as => :mysym

    Py: import mod1 as mymod
    Rb: py :import "mod1", :as => "mymod"
        py :import :mod1, :as => :mymod

    Py: from mod2.mod1 import *
    Rb: py :from => "mod2.mod1", :import => :*
        pyrequire "mod2/mod1" # ruby style imports


### Python named arguments

    # Python
    def foo(arg1, arg2):
        pass

    # Ruby
    foo(:arg2 => "bar2", :arg1 => "bar1")

    # with Ruby 1.9
    foo(arg2: "bar2", arg1: "bar1")


### Catch Exceptions from Ruby

    # Python
    class MyFirstException(Exception):
        pass

    class MySecondException(MyFirstException):
        pass

    def test():
        raise MySecondException


    # Ruby
    begin
        test
    rescue MyFirstException => e # perhaps we will need to work out name collisions
        puts e.message
    end



## RubyPython

As I mentioned above, most of the code linking the 2 VMs is from Zach Raines's
[RubyPython](http://raineszm.bitbucket.org/rubypython/) gem.

## Requirements
	
* Python >= 2.4, < 3.0
* Ruby >= 1.8.6
* You must be able to build the ffi gem under your environment.

Note: RubyPython has been tested on Mac OS 10.5.x
	
	
## Install

    gem install rupy

## License

(The MIT License)

Copyright (c) 2011 Steeve Morin

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
