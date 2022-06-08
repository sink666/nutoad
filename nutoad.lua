-- scanner and parser section
function set_contains (set, key)
   return set[key] ~= nil
end

function val_in_set (set, value)
   for k, v in pairs(set) do
      if v == value then
         return true
      end
   end

   return false
end

nutoad_syntax = {
   ["+"] = "add",    ["-"] = "sub",    ["<"] = "move_l", [">"] = "move_r",
   ["."] = "barf",   [","] = "read",   ["#"] = "dump_m", ["@"] = "dump_w",
   ["["] = "loop_l", ["]"] = "loop_r", [":"] = "open_d", [";"] = "clos_d",
}

function scan (input)
   -- get each character and shove it into a table
   local extract = {}
   for i = 1, #input do
      extract[i] = input:sub(i, i)
   end

   --tokenize
   local tokens = {}
   for i = 1, #extract do
      local token
      if set_contains(nutoad_syntax, extract[i]) then
         token = { t_type= "builtin", value = nutoad_syntax[extract[i]] }
      else
         token = { t_type = "context", value = extract[i] }
      end
      tokens[i] = token
   end

   return tokens
end

function make_tuple (token, argx, argy)
   local tuple_prototypes = {
      ["barf"]   = { op = "io"  , x = "b" , y = nil  },
      ["read"]   = { op = "io"  , x = "r" , y = nil  },
      ["add"]    = { op = "math", x =  1  , y = nil  },
      ["sub"]    = { op = "math", x = -1  , y = nil  },
      ["loop_l"] = { op = "loop", x = "l" , y = 0    },
      ["loop_r"] = { op = "loop", x = "r" , y = 0    },
      ["move_l"] = { op = "move", x = -1  , y = nil  },
      ["move_r"] = { op = "move", x =  1  , y = nil  },
      ["dump_m"] = { op = "dump", x = "m" , y = nil  },
      ["dump_w"] = { op = "dump", x = "w" , y = nil  },
      ["open_d"] = { op = "def" , x = argx, y = argy },
      ["call"  ] = { op = "call", x = argx, y = argy },
   }

   if set_contains(tuple_prototypes, token) then
      return tuple_prototypes[token]
   else
      return { op = "noop", x = argx, y = argy }
   end
end

function parse (tokens)
   local ir = {}
   local ir_p = 1
   local words = {}
   local cd_p = 1
   local tuple = {}
   local add_tuple = false
   -- +1 to count '[', -1 to count a ']'. ~= 1 at the end == syntax error
   local scope = 0
   -- keep a stack of 'distances' between opening and closing braces
   local targetstack = {}

   for i = 1, #tokens do
      local c_token = tokens[i].value

      if scope > 0 then
         if targetstack[scope] == nil then
            targetstack[scope] = 0
         end

         for i=1, scope do
            targetstack[i] = targetstack[i] + 1
         end
      end

      if c_token == "loop_l" then
         scope = scope + 1
      elseif c_token == "loop_r" then
         scope = scope - 1
      end

      if val_in_set(nutoad_syntax, c_token) then -- operator?
         if c_token ~= "open_d" and c_token ~= "clos_d" then
            -- add this to the def if we're defining something and have an id
            if tuple.op ~= nil and tuple.x ~= "" then 
               tuple.y[cd_p] = make_tuple(c_token)
               cd_p = cd_p + 1
            elseif tuple.x == "" then -- maybe its malformed
               error("word def has no identifier")
            else -- otherwise this must be a new tuple
               tuple = make_tuple(c_token)
               add_tuple = true
            end
         elseif c_token == "open_d" then
            if scope > 1 then
               error("you may not open word definitions inside loops")
            end
            if tuple.op ~= nil then
               error("you may not nest word definitions.")
            end
            tuple = make_tuple(c_token, "", {})
         elseif c_token == "clos_d" then
            if tuple.op == nil then
               error("misplaced call to ';' without preceding ':'")
            end
            cd_p = 1
            add_tuple = true
         end
      elseif set_contains(words, c_token) then -- user word?
         if tuple.op ~= nil and c_token == tuple.x then
            error("words may not be recursive.")
         else
            tuple = make_tuple("call", c_token)
            add_tuple = true
         end
      else -- word identifier? comment in word def? comment at top level?
         if tuple.x == "" then
            tuple.x = c_token
            words[c_token] = "lol"
         end

         if tuple.op ~= nil and tuple.x ~= c_token then
            tuple.y[cd_p] = make_tuple(c_token, c_token)
            cd_p = cd_p + 1
         end
         
         if tuple.op == nil then
            tuple = make_tuple("noop")
            add_tuple = true
         end
      end

      if add_tuple then
         ir[ir_p] = tuple
         ir_p = ir_p + 1
         tuple = {}
         add_tuple = false
      end
   end

   if scope ~= 0 then
      error("unbalanced loop expression; '[' or ']'")
   end

   -- now shove the targets where they need to go in the ir
   for i=1, #ir do
      if ir[i].x == "l" then
         scope = scope + 1
         ir[i].y = targetstack[scope]
      elseif ir[i].x == "r" then
         ir[i].y = -targetstack[scope]
         scope = scope - 1
      end
   end
   
   for i=1, #targetstack do
      print(string.format("pos: %s; val: %d", i, targetstack[i]))
   end

   return ir
end

-- words and interpreter section
words = {}
array = {}
arrayp = 1 -- currently addressed array address
codep = 1 -- currently addressed instruction

-- recommended array size
for i = 1, 30000 do
   array[i] = 0
end

function words.dump (which)
   local buffer = {}
   if which == "m" then
      for i = 1, 10 do
         buffer[i] = array[i]
      end
      print(string.format("::state:: pointer loc: %d", arrayp))
      print(unpack(buffer))
   else
      print("::words::")
      for k,_ in pairs(words) do
         print(string.format("id: %s", k))
      end
   end
end

function words.math (amount)
   local test = array[arrayp] + amount
   if test == 255 then
      array[arrayp] = 0
   elseif test < 0 then
      array[arrayp] = 255
   else
      array[arrayp] = test
   end
end

function words.move (dir)
   arrayp = arrayp + dir
end

function words.noop ()
   print("noop fired")
end

function words.loop (side, target)
   if side == "l" then
      if array[arrayp] == 0 then
         -- print(codep + target)
         codep = codep + target
      end
   elseif side == "r" then
      if array[arrayp] ~= 0 then
         -- print(codep + target)
         codep = codep + target
      end
   end
end

function words.io (in_out)
   
end

function words.def (id, ir)

end

function words.call (id)

end

function begin_interpret (ir)
   -- ir structure is ir[i](.op|.x|.y)
   while codep < #ir + 1 do
      local op = ir[codep].op
      local argx = ir[codep].x
      local argy = ir[codep].y
      words[op](argx, argy) -- this does the word
      codep = codep + 1
   end
end

function quit (input)
   local tokens = scan(input)
   local ir = parse(tokens)
   begin_interpret(ir)
end

-- our input
-- input = "@:ab+++;@ a#[-] :b+++;@ a#@"
-- input = "apple +- :a+++; +-a++"
-- input = "apple [+-] apple++++"
-- input = "+-[+-]<>><.,@#  :a+++m; a"
-- input = " :+; a :b---; abc"
-- input = "+++++[-]"
-- input = "+-[]<>.,@#"
-- input = "+++++ :a+++++; a"
-- input = "@#+>+>+>+>+>+#++#  #>+#[]"
-- input = " [+++[>>>[-]+]]+"
input = "+++++#[-]#"

-- finally, run
quit(input)
