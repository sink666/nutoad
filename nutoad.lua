array = {}
input = "+++++>>+++++<+++++>-#"
commands = {}
pointer = 1

-- the recommended size of a brainfuck array
for i = 1, 30000 do
   array[i] = 0
end

function increment_a_at_i (index)
   print("increment fired")
end

function decrement_a_at_i (index)
   print("decrement fired")
end

--string.char
function barf_from_a_at_i (index)

end

function pointer_move_left (pointer)
   print("move left fired")
end

function pointer_move_right (pointer)
   print ("move right fired")
end

function dump_array_state ()
   print("::final state::")
   local buffer = {}
   for i = 1, 10 do
      buffer[i] = array[i]
   end

   print(unpack(buffer))
end

builtin_dictionary = {
   ["#"] = { func = dump_array_state },
   ["+"] = { func = increment_a_at_i },
   ["-"] = { func = decrement_a_at_i },
   ["."] = { func = barf_from_a_at_i },
   ["<"] = { func = pointer_move_left },
   [">"] = { func = pointer_move_right },
}

-- extract the commands
-- in lua you can't just index into a string like in C
-- so we return a substring at the position (i, i) in the string
for i = 1, #input do
   commands[i] = input:sub(i, i)
end

-- for the length of the commands array, address the dictionary by
-- the character i in commands and call its function

for i = 1, #commands do
   builtin_dictionary[commands[i]].func()
end

-- builtin_dictionary[i].func("test")
-- threading idea; just check the type of a function in the dictionary
-- if it's a string we know for sure it's brainfuck. otherwise it's a builtin

-- method for matching [] could be simple
-- in cristofani's simple brainfuck interpreter, there's a 'targets' array which
-- is exactly the same length as the program array.
-- given an opening brace is at index 7 in the program and a closing brace is
-- at index 9, the targets array at index 9 will store a '7' and vice versa
-- the way it uses a stack when reading them in is cute
