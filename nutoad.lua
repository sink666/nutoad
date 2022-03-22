result = {}
for i = 1, 30000 do
   result[i] = 0
end

function increment_a_at_i(str_foo)
   print(str_foo)
   print("foo")
end

function decrement_a_at_i(str_bar)
   print(str_bar)
   print("bar")
end

function barf_from_a_at_i(str_gronk)
   print(str_gronk)
   print("gronk")
end

builtin_dictionary = {
   {id = "+", func = increment_a_at_i},
   {id = "-", func = decrement_a_at_i},
   {id = ".", func = barf_from_a_at_i},
}

for i=1, #builtin_dictionary do
   print(builtin_dictionary[i].id)
   builtin_dictionary[i].func("buzz")
end

