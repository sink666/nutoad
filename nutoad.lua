array = {}
input = "+++++>>+++++<-#"
input_bracetest = "+++++[>+++++[-]<]#"
input3 = "+++++>>-----<<-----#"

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

builtin_dictionary = {
   ["#"] = { func = dump_array_state },
   ["+"] = { func = increment_a_at_i },
   ["-"] = { func = decrement_a_at_i },
   ["."] = { func = barf_from_a_at_i },
   ["<"] = { func = pointer_move_left },
   [">"] = { func = pointer_move_right },
}

-- test1 = extract_commands(input)
commandst2 = extract_commands(input_bracetest)
-- commandst3 = extract_commands(input3)

-- match all the brackets
-- spit into an array the same length of commands
targetstest2 = match_brackets(commandst2)

print(unpack(commandst2))
print(unpack(targetstest2))

-- the currently addressed command
-- p = 1
-- while p < #commandst2 + 1 do
--    builtin_dictionary[commandst2[p]].func()
--    p = p + 1
-- end

-- builtin_dictionary[i].func("test")
-- threading idea; just check the type of a function in the dictionary
-- if it's a string we know for sure it's brainfuck. otherwise it's a builtin

-- method for matching [] could be simple
-- in cristofani's simple brainfuck interpreter, there's a 'targets' array which
-- is exactly the same length as the program array.
-- given an opening brace is at index 7 in the program and a closing brace is
-- at index 9, the targets array at index 9 will store a '7' and vice versa
-- the way it uses a stack when reading them in is cute
