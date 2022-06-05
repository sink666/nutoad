function set_contains (set, key)
   return set[key] ~= nil
end

nutoad_operators = {
   symbols = ["+", "-", "<", ">", ".", ",", "#", "@"],
   tokens  = ["inc", "dec", "movl", "movr", "barf", "read", "dumpm", "dumpw"]
}

nutoad_structures = {
   ["loop"] = { symbols = ["[", "]"], tokens = ["loopl", "loopr"] }
   ["defn"] = { symbols = [":", ";"], tokens = ["dopen", "dclos"] }
}

function scan (input)
   local current_def = ""

   local extract = {}
   local tokens = {}

   -- get each character and shove it into a table
   for i = 1, #input do
      extract[i] = input:sub(i, i)
   end

   for i = 1, #extract do
      if in_sdef then
         if extract[i] ~= ";" and not next_is_id then
            tokens[i] = { t="sdef", name = current_def, op = words[extract[i]]}
         elseif next_is_id then
            words[extract[i]] = { t="scall", name = current_def }
            tokens[i] = { t="sid", name = current_def }
            next_is_id = false
         else
            tokens[i] = { t="scls", name = current_def }
            in_sdef = false
         end
      else
         if set_contains(words, extract[i]) then
            tokens[i] = words[extract[i]]
         elseif extract[i] == ":" then
            in_sdef = true
            next_is_id = true
            current_def = extract[i + 1]
            tokens[i] = { t="sopn", name = current_def }
         else
            tokens[i] = "com"
         end
      end
   end

   tokens[#extract + 1] = "eof"

   return tokens
end

function make_tuples (tokens, targets)
   local tuples = {}
   local basic = { "inc", "dec", "movel", "mover",
                   "barf", "read", "dumpm", "dumpw" }

   for i = 1, #tokens do
      local n = i + 1
      if set_contains(basic, tokens[i]) then
         tuples[i] = { op = tokens[i], naddr = n }
      elseif 



   -- for i = 1, #tokens do
   --    local n = i + 1
   --    if tokens[i] == "inc" then
   --       tuples[i] = { op = "inc", naddr = n }
   --    elseif tokens[i] == "dec" then
   --       tuples[i] = { op = "dec", naddr = n }
   --    elseif tokens[i] == "loopl" then
   --       tuples[i] = { op = "loopl", jaddr = targets[i], naddr = n }
   --    elseif tokens[i] == "loopr" then
   --       tuples[i] = { op = "loopr", jaddr = targets[i], naddr = n }
   --    elseif tokens[i] == "movel" then
   --       tuples[i] = { op = "movel", naddr = n }
   --    elseif tokens[i] == "mover" then
   --       tuples[i] = { op = "mover", naddr = n }
   --    elseif tokens[i] == "barf" then
   --       tuples[i] = { op = "barf", naddr = n }
   --    elseif tokens[i] == "read" then
   --       tuples[i] = { op = "read", naddr = n }
   --    elseif tokens[i] == "dumpm" then
   --       tuples[i] = { op = "dumpm", naddr = n }
   --    elseif tokens[i] == "dumpw" then
   --       tuples[i] = { op = "dumpw", naddr = n }
   --    elseif tokens[i] == "scall" then
   --       tuples[i] = { op = tokens[i].name, naddr = n }
   --    elseif tokens[i] == "eof" then
   --       tuples[i] = { op = "eof", naddr = nil }
   --    elseif tokens[i] == "com" then
   --       tuples[i] = { op = "nop", naddr = n }
   --    end
   -- end

   return tuples
end

function make_targets (tokens)
   local targets = {}

   local stackp = 1
   local stack = {}

   for i = 1, #tokens do
      targets[i] = 0
      if type(tokens[i]) == "table" and stackp > 1 then
         if tokens[i].t == "sopn" then
            error("words may not be defined within loops.")
         end
      end
      if tokens[i] == "loopl" then
         stack[stackp] = i
         stackp = stackp + 1
      end
      if tokens[i] == "loopr" then
         stackp = stackp - 1
         if stackp == 0 then
            error("unmatched ']'")
         end
         targets[i] = stack[stackp]
         targets[stack[stackp]] = i
      end
   end

   if stackp > 1 then
      error("unmatched '['")
   end

   return targets
end

function make_dict (tokens)
   local dict = {}

   for i = 1, #tokens do
      if type(tokens[i]) == "table" then
         local tn = tokens[i].name
         if dict[tn] == nil then
            dict[tn] = {}
         end
      end
   end

   return dict
end

function parse (tokens)
   local targets = make_targets(tokens)
   local dictionary = make_dict(tokens)
   local tuples = make_tuples(tokens, targets)

   return tuples, dictionary
end

function quit (input)
   local tokens = scan(input)
   local ir, dict = parse(tokens)

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

   print(unpack(dict))
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
-- input = "apple [+-] apple++++"
-- input = "+-[+-]<>><.,@#  :a+++;a"
-- input = " :a+++; a"
input = ":a+++; [+-a]"
-- input = "+++++[-]"

-- let's go
quit(input)
