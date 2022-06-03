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
      ["+"] = "inc",   ["-"] = "dec",   ["["] = "loopl", ["]"] = "loopr",
      ["<"] = "movel", [">"] = "mover", ["."] = "barf",  [","] = "read",
      ["#"] = "dumpm", ["@"] = "dumpw",
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
            if open_sdef then
               next_is_id = true
               open_sdef = false
               tokens[i] = "sopn"
            else
               tokens[i] = "sdef"
            end
         elseif next_is_id then
            words[extract[i]] = { t = "scall", name = extract[i] }
            tokens[i] = { t = "sid", name = extract[i] }
            next_is_id = false
         else
            tokens[i] = "scls"
            in_sdef = false
         end
      else
         tokens[i] = "com"
      end
   end

   tokens[#extract + 1] = "eof"

   return tokens
end

function parse (tokens)
   local tuples = {}
   local targets = {}

   --lets get the jump targets
   local stackp = 1
   local stack = {}

   for i = 1, #tokens do
      targets[i] = 0
      if tokens[i] == "loopl" then
         stack[stackp] = i
         stackp = stackp + 1
      end
      if tokens[i] == "loopr" then
         if stackp == 0 then 
            error("unmatched ']'")
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

   --build the ir as tuples of operations and address values
   for i = 1, #tokens do
      local n = i + 1
      if tokens[i] == "inc" then
         tuples[i] = { op = "inc", naddr = n }
      elseif tokens[i] == "dec" then
         tuples[i] = { op = "dec", naddr = n }
      elseif tokens[i] == "loopl" then
         tuples[i] = { op = "loopl", jaddr = targets[i], naddr = n }
      elseif tokens[i] == "loopr" then
         tuples[i] = { op = "loopr", jaddr = targets[i], naddr = n }
      elseif tokens[i] == "eof" then
         tuples[i] = { op = "eof", naddr = nil }
      else
         tuples[i] = { op = "nop", naddr = n }
      end
   end

   return tuples
end

function quit (input)
   local tokens = scan(input)
   local ir = parse(tokens)

   for i = 1, #tokens do
      if type(tokens[i]) == "table" then
         local t = string.format("%s %s", tokens[i].t, tokens[i].name)
         print(t)
      else
         print(tokens[i])
      end
   end

   for i = 1, #ir do
      local t = string.format("%2d: %5s %5s %5s",
                              i, ir[i].op, ir[i].naddr, ir[i].jaddr)
      print(t)
   end
   -- interpret(commands, targets, state)
   -- print("bye")
end

-- the recommended size of a brainfuck array
array = {}
for i = 1, 30000 do
   array[i] = 0
end

-- our input
-- input = "@:ab+++;@ a#[-] :b+++;@ a#@"
-- input = "apple +- :a+++; +-a++"
input = "apple [+-] apple++++"

-- let's go
quit(input)
