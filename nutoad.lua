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
   ["."] = "barf",   [","] = "scry",   ["#"] = "dump_m", ["@"] = "dump_w",
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
      ["scry"]   = { op = "io"  , x = "s" , y = nil  },
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

function make_targets (ir)
   local list = {}
   local listp = 0

   --handle everything that isnt a def
   for i=1, #ir do
      if ir[i].x == 'l' then
         listp = #list + 1
         list[listp] = { opos = i, cpos = 0, closed = false }
      end
      
      if ir[i].x == 'r' then
         for j = #list, 1, -1 do
            if list[listp].closed then
               listp = listp - 1
            end
         end

         list[listp].closed = true
         list[listp].cpos = i
      end
   end

   for i=1, #list do
      local open  = list[i].opos
      local close = list[i].cpos
      ir[open].y = close
      ir[close].y = open
   end

   --go over it one last time, find the defs, generate their targets
   for i=1, #ir do
      if ir[i].op == "def" then
         local def_ir = ir[i].y
         
         def_ir = make_targets(def_ir)
         ir[i].y = def_ir
      end
   end

   return ir
end

function parse (tokens)
   --first pass, do everything except loop targets
   local ir = {}
   local ir_p = 1
   local words = {}
   local cd_p = 1
   local tuple = {}
   local add_tuple = false

   for i = 1, #tokens do
      local c_token = tokens[i].value

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

   --second pass, get + set the loop targets inc. within definitions
   ir = make_targets(ir)

   return ir
end

-- words and interpreter section
words = {}
array = {}
arrayp = 1 -- currently addressed array address
g_codep = 1 -- currently addressed instruction

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
   local test = arrayp + dir
   if test < 1 then
      arrayp = 30000
   elseif test > 30000 then
      arrayp = 1
   else
      arrayp = arrayp + dir
   end
end

function words.noop ()
   ;
end

function words.loop (side, target)
   if side == "l" then
      if array[arrayp] == 0 then
         return target
      end
   elseif side == "r" then
      if array[arrayp] ~= 0 then
         return target
      end
   end
end

function words.io (in_out)
   if in_out == "b" then -- barf from array
      io.write(string.char(array[arrayp]))
   elseif in_out == "s" then -- scry (read) a character of input
      local temp = io.stdin:read(1)
      if temp == nil then
         -- eof?
         return nil
      else
         temp = string.byte(temp)
      end
      array[arrayp] = temp
   end
end

function words.def (id, ir)
   words[id] = ir
end

function words.call (id)
   local call_ir = words[id]
   begin_interpret(call_ir, true)
end

function begin_interpret (ir, in_call)
   -- ir structure is ir[i](.op|.x|.y)
   -- if we're in a call we just do the loop but with a local codepointer
   if in_call then
      local call_codep = 1
      while call_codep < #ir + 1 do
         local op = ir[call_codep].op
         local argx = ir[call_codep].x
         local argy = ir[call_codep].y
         local ret = words[op](argx, argy)
         if ret ~= nil then
            call_codep = ret
         end
         call_codep = call_codep + 1
      end
   else
      while g_codep < #ir + 1 do
         local op = ir[g_codep].op
         local argx = ir[g_codep].x
         local argy = ir[g_codep].y
         -- print(string.format("%d, %s, %d", codep, op, arrayp))
         local ret = words[op](argx, argy) -- this does the word
         if ret ~= nil then
            g_codep = ret
         end
         g_codep = g_codep + 1
      end
   end
end

function start (input)
   local tokens = scan(input)
   local ir = parse(tokens)
   begin_interpret(ir)
end

-- our input; hello world
-- input = "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++."
-- another input; outputs 'H'
-- input = '[]++++++++++[>>+>+>++++++[<<+<+++>>>-]<<<<-]"A*$"B?C![D>>+<<]>[>>]<<<<[>++<[-]]>.>.'
-- input = ":a[-];+++++#>+++++#a<a#"

start(input)
