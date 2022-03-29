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
function loop_left_bracket (s, targets)
   -- if the current address is zero, jump to the target
   -- stored at targets[i]
   if s.array[s.arrayp] == 0 then
      return targets[s.codep]
   end
end

function loop_right_bracket (s, targets)
   -- if the current address is not zero, jump to the target
   -- stored at targets[i]
   if s.array[s.arrayp] ~= 0 then
      return targets[s.codep]
   end
end

function barf_from_array (s)
   io.write(string.char(s.array[s.arrayp]))
end

function read_stdin (s)
   --read a character from input
   local temp = io.stdin:read(1)
   if temp == nil then
      --if it's nil (eof) we return
      return nil
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

function begin_new_word (s)
   s.interpret = false
end

function end_new_word (s)
   s.interpret = true
end

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
function dict_contains (s, key)
   return s.dictionary[key] ~= nil
end

-- we pass around a table with these variables beacuse tables are passed by
-- reference in lua.
state = {
   array = {},
   targets = {},
   codep = 1,
   arrayp = 1,
   dictionary = {
      ["#"] = { func = dump_array_state  , immediate = false },
      ["+"] = { func = increment_at_point, immediate = false },
      ["-"] = { func = decrement_at_point, immediate = false },
      ["["] = { func = loop_left_bracket , immediate = false },
      ["]"] = { func = loop_right_bracket, immediate = false },
      ["<"] = { func = pointer_move_left , immediate = false },
      [">"] = { func = pointer_move_right, immediate = false },
      ["."] = { func = barf_from_array   , immediate = false },
      [","] = { func = read_stdin        , immediate = false },
      [":"] = { func = begin_new_word    , immediate = false },
      [";"] = { func = end_new_word      , immediate = true  },
   },
   interpret = true,
   newdefkey = "",
}

-- the recommended size of a brainfuck array
for i = 1, 30000 do
   state.array[i] = 0
end

-- a word in toadskin is defined by:
--  beginning a colon definition
--  giving the word a single character idenfitifer
--  writing the body of a word
--  closing the definition with a semicolon
-- a new word can't contain a definition
-- input = "this should be ignored +++++#:A[-]>;A#+++++# and this too"
-- input = "+++++#:A[-]>;A#+++++A#+++++[-]#"
-- input = "+++++#:A[-]>;A#+++++#[-]#"
-- input = ":A[-]>; +++++#A#+++++#[-]#"

function quit(input, state)
   local commands = extract_commands(input)
   local targets = match_brackets(commands)

   interpret(commands, targets, state)
   print("bye")
end

function interpret (input, targets, s)
   local codep = 1
   -- local commands = extract_commands(input)
   -- local targets = targets
   print(unpack(input))

   while codep < #input + 1 do
      local current = input[codep]
      -- are we interpreting?
      if s.interpret then
         if dict_contains(s, current) then
            if type(s.dictionary[current].func) == "function" then
               local temp = s.dictionary[current].func(s, targets)
               if temp then
                  codep = temp
               end
            else
               local tempc = extract_commands(s.dictionary[current].func)
               local tempt = match_brackets(s.dictionary[current].func)
               interpret(tempc, tempt, s)
            end
         else
            --ignore it
         end
      else
         if dict_contains(s, current) then
            if s.dictionary[current].immediate then
               s.dictionary[current].func(s)
            else
               local temp = s.dictionary[s.newdefkey].func
               temp = temp .. current
               s.dictionary[s.newdefkey].func = temp
            end
         else
            s.newdefkey = current
            s.dictionary[s.newdefkey] = { func = "", immediate = false }
         end
      end
         
      codep = codep + 1
      s.codep = codep
   end
end

-- function add()

-- end

-- let's go
-- interpret(input, state)

quit(input, state)
