function checkvalue(v)
   if v == 256 then
      return 0
   elseif v == -1 then
      return 255
   else
      return v
   end
end

function increment_at_point (s)
   s.array[s.arrayp] = checkvalue(s.array[s.arrayp] + 1)
end

function decrement_at_point (s)
   s.array[s.arrayp] = checkvalue(s.array[s.arrayp] - 1)
end

function pointer_move_left (s)
   s.arrayp = s.arrayp - 1
end

function pointer_move_right (s)
   s.arrayp = s.arrayp + 1
end

function loop_left_bracket (s, targets)
   if s.array[s.arrayp] == 0 then
      return targets[s.codep]
   end
end

function loop_right_bracket (s, targets)
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
   local buffer = {}
   for i = 1, 10 do
      buffer[i] = s.array[i]
   end
   print(string.format("::state:: pointer loc: %d", s.arrayp))
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

function dict_contains (key, s)
   return s.dictionary[key] ~= nil
end

-- we pass around a table beacuse tables are passed by reference in lua.
state = {
   array = {},
   codep = 1,
   arrayp = 1,
   interpret = true,
   newdefkey = "",
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
      ["@"] = { func = dump_words        , immediate = false },
   },
}

-- the recommended size of a brainfuck array
for i = 1, 30000 do
   state.array[i] = 0
end

-- input = "this should be ignored +++++#:A[-]>;A#+++++# and this too"
-- input = "+++++#:A[-]>;A#+++++A#+++++[-]#"
-- input = ":A[-]>;+++++#A#+++++#A#+++++#A#"
-- input = "+++++#:A[-]>;A#+++++#[-]#"
-- input = "++++++#:A[-];A#"
-- input = "+++++#:A[-]:B-;;A#"
input = "#-#"

function quit (input, state)
   local commands = extract_commands(input)
   local targets = match_brackets(commands)

   interpret(commands, targets, state)
   print("bye")
end

function add (current, s)
   if current == ":" then
      local errstr = string.format("in definition %s: \n  nested procedure definitions are invalid.", s.newdefkey)
      error(errstr)
   end
   
   if dict_contains(current, s) then
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

function execute (current, targets, s)
   local func = s.dictionary[current].func
   if type(func) == "function" then
      return func(s, targets)
   else
      local tempc = extract_commands(func)
      local tempt = match_brackets(tempc)
      interpret(tempc, tempt, s)
   end
end

function interpret (input, targets, s)
   local codep = 1

   while codep < #input + 1 do
      local current = input[codep]
      if s.interpret then
         if dict_contains(current, s) then
            local temp = execute(current, targets, s)
            if temp then
               codep = temp
            end
         else
            -- skip whatever we just hit is if its not in the dictionary
         end
      else -- we must be adding a new definition
         add(current, s)
      end
         
      codep = codep + 1
      s.codep = codep
   end
end

-- let's go
quit(input, state)
