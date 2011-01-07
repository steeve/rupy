def test(var, bind)
    bind.eval("b = 5")
    bind.eval("p local_variables")
    bind.eval("lambda { |x| #{var} = x }").call(42)
end

test(:a, Kernel.binding)
p local_variables

p a
