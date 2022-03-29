-- we pass around a table with these variables beacuse tables are passed by
-- reference in lua.
state = {
   array = {},
   targets = {},
   codep = 1,
   arrayp = 1,
}

-- the recommended size of a brainfuck array
for i = 1, 30000 do
   state.array[i] = 0
end

function increment_at_point (s)
   s.array[s.arrayp] = s.array[s.arrayp] + 1
end

function decrement_at_point (s)
   s.array[s.arrayp] = s.array[s.arrayp] - 1
end

function pointer_move_left (s)
   s.arrayp = s.arrayp - 1
end

function pointer_move_right (s)
   s.arrayp = s.arrayp + 1
end

-- the looping construct in brainfuck has intentional fallthrough on the closing
-- bracket when it is reached and the loop is complete
function loop_left_bracket (s)
   -- if the current address is zero, jump to the target
   -- stored at targets[i]
   if s.array[s.arrayp] == 0 then
      s.codep = s.targets[s.codep]
   end
end

function loop_right_bracket (s)
   -- if the current address is not zero, jump to the target
   -- stored at targets[i]
   if s.array[s.arrayp] ~= 0 then
      s.codep = s.targets[s.codep]
   end
end

--string.char
function barf_from_array (s)
   io.write(string.char(s.array[s.arrayp]))
end

function read_stdin (s)
   --read a character from input
   local temp = io.stdin:read(1)
   if temp == nil then
      --if it's nil (eof) we return
      return
   else
      temp = string.byte(temp)
   end
   s.array[s.arrayp] = temp
end

function dump_array_state (s)
   print("::state::")
   local buffer = {}
   for i = 1, 10 do
      buffer[i] = s.array[i]
   end
   print("pointer location: ", s.arrayp)
   print(unpack(buffer))
end

-- extract the commands
-- in lua you can't just index into a string like in C
-- so we return a substring at the position (i, i) in the string
function extract_commands (input)
   local extract = {}

   for i = 1, #input do
      extract[i] = input:sub(i, i)
   end

   return extract
end

function match_brackets (commands)
   local stack = {}
   local stackp = 1
   local targets = {}

   for i=1, #commands do
      targets[i] = 0
      if commands[i] == "[" then
         stack[stackp] = i
         stackp = stackp + 1
      end
      if commands[i] == "]" then
         if stackp == 0 then
            error("Unmatched ']'")
         else
            stackp = stackp - 1
            targets[i] = stack[stackp]
            targets[stack[stackp]] = i
         end
      end
   end

   if stackp > 1 then
      error("unmatched '['")
   end

   return targets
end

-- threading idea; just check the type of a function in the dictionary
-- if it's a string we know for sure it's brainfuck. otherwise it's a builtin
builtin_dictionary = {
   ["#"] = { func = dump_array_state   },
   ["+"] = { func = increment_at_point },
   ["-"] = { func = decrement_at_point },
   ["["] = { func = loop_left_bracket  },
   ["]"] = { func = loop_right_bracket },
   ["<"] = { func = pointer_move_left  },
   [">"] = { func = pointer_move_right },
   ["."] = { func = barf_from_array    },
   [","] = { func = read_stdin         },
}

function dict_contains (key)
   return builtin_dictionary[key] ~= nil
end

input = "[]++++++++++[>>+>+>++++++[<<+<+++>>>-]<<<<-]\"A*$\";?@![#>>+<<]>[>>]<<<<[>++<[-]]>.>."

function interpret (input, s)
   commands = extract_commands(input)
   s.targets = match_brackets(commands)

   while s.codep < #commands + 1 do
      local current = commands[s.codep]
      if dict_contains(current) then
         builtin_dictionary[current].func(s)
      end
      s.codep = s.codep + 1
   end
end

-- let's go
interpret(input, state)
