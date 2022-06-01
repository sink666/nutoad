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

function dump_words (s)
   print("words:")
   -- local n
   local words = {}
   for k,_ in pairs(s.dictionary) do
      -- n = n + 1
      words[#words + 1] = k
   end
   print(unpack(words))

end

function begin_new_word (s)
   s.interpret = false
   s.defident = true
end

function end_new_word (s)
   s.interpret = true
end

-- we pass around a table beacuse tables are passed by reference in lua.
state = {
   array = {},
   codep = 1,
   arrayp = 1,
   interpret = true,
   newdefkey = "",
   defident = false,
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

function set_contains (set, key)
   return set[key] ~= nil
end

function scan (input)
   local in_sdef = false
   local next_is_id = false
   local open_sdef = false

   local extract = {}
   local tokens = {}
   local words = {
      ["+"] = "inc",
      ["-"] = "dec",
      ["["] = "loopl",
      ["]"] = "loopr",
      ["<"] = "movel",
      [">"] = "mover",
      ["."] = "barf",
      [","] = "read",
      ["#"] = "dumpm",
      ["@"] = "dumpw",
   }

   -- get each character and shove it into a table
   for i = 1, #input do
      extract[i] = input:sub(i, i)
   end

   for i = 1, #extract do
      if extract[i] == ":" then
         in_sdef = true
         open_sdef = true
      end

      if set_contains(words, extract[i]) and not in_sdef then
         tokens[i] = words[extract[i]]
      elseif in_sdef then
         if extract[i] ~= ";" and not next_is_id then
            tokens[i] = "sdef"
         elseif next_is_id then
            words[extract[i]] = "scall"
            tokens[i] = "sid"
            next_is_id = false
         else
            tokens[i] = "sdef"
            in_sdef = false
         end
      else
         tokens[i] = "com"
      end
      
      if open_sdef then
         next_is_id = true
         open_sdef = false
      end
   end

   return tokens
   
end

function quit (input, state)
   local tokens = scan(input)
   print(unpack(tokens))
   -- interpret(commands, targets, state)
   print("bye")
end

-- the recommended size of a brainfuck array
for i = 1, 30000 do
   state.array[i] = 0
end

-- our input
-- input = "@:ab+++;@ a#[-] :b+++;@ a#@"
input = "apple +- :a+++; +-a++"

-- let's go
quit(input, state)
