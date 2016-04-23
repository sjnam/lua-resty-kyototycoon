-- Copyright (C) 2014-2016 Soojin Nam, Kakao Corp.

-- lots of code is borrowed from lua-resty-mysql


local bit = require "bit"
local tcp = ngx.socket.tcp
local strbyte = string.byte
local strchar = string.char
local band = bit.band
local bor = bit.bor
local lshift = bit.lshift
local rshift = bit.rshift
local concat = table.concat
local insert = table.insert
local tostring = tostring
local setmetatable = setmetatable
local error = error
local ipairs = ipairs


local _M = { _VERSION = '0.21' }


-- constants

local INTERNAL_SERVER_ERROR = 0xBF
local OP_REPLICATION = 0xB1
local OP_PLAY_SCRIPT = 0xB4
local OP_SET_BULK = 0xB8
local OP_REMOVE_BULK = 0xB9
local OP_GET_BULK = 0xBA


local mt = { __index = _M }


-- Every numeric value are expressed in big-endian order.

local function _get_byte(data, i)
   local a = strbyte(data, i)
   return a, i + 1
end


local function _get_byte2(data, i)
   local b, a = strbyte(data, i, i + 1)
   return bor(a, lshift(b, 8)), i + 2
end


local function _get_byte4(data, i)
   local d, c, b, a = strbyte(data, i, i + 3)
   return bor(a, lshift(b, 8), lshift(c, 16), lshift(d, 24)), i + 4
end


local function _get_byte8(data, i)
    local h, g, f, e, d, c, b, a = strbyte(data, i, i + 7)
    local lo = bor(a, lshift(b, 8), lshift(c, 16), lshift(d, 24))
    local hi = bor(e, lshift(f, 8), lshift(g, 16), lshift(h, 24))
    return lo + hi * 4294967296, i + 8
end


local function _set_byte(n)
   return strchar(band(n, 0xff))
end


local function _set_byte2(n)
   return strchar(band(rshift(n, 8), 0xff), band(n, 0xff)) 
end


local function _set_byte4(n)
   return strchar(band(rshift(n, 24), 0xff),
                  band(rshift(n, 16), 0xff),
                  band(rshift(n, 8), 0xff),
                  band(n, 0xff))
end


local function _set_byte8(n)
   local hn = n * 4294967296
   return strchar(band(rshift(hn, 24), 0xff),
                  band(rshift(hn, 16), 0xff),
                  band(rshift(hn, 8), 0xff),
                  band(hn, 0xff),
                  band(rshift(n, 24), 0xff),
                  band(rshift(n, 16), 0xff),
                  band(rshift(n, 8), 0xff),
                  band(n, 0xff))
end


local function _send_request(self, magic, flags, req)
   local sock = self.sock
   local request = _set_byte(magic) .. _set_byte4(flags) .. req
   return sock:send(request)
end


function _M.replication(self, ts, sid)
   return "not implemented", nil
end


function _M.play_script(self, name, tab)
   local flags = flags or 0
   local sock = self.sock

   if not name or not tab or #tab == 0 then
      return nil, "invalid arguments"
   end

   local t = { _set_byte4(#name) }  -- nsiz
   
   insert(t, _set_byte4(#tab))      -- rnum
   insert(t, name)                  -- procedure name

   for _, v in ipairs(tab) do
      local key = v.key or v.KEY
      local value = v.value or v.VALUE
      insert(t, _set_byte4(#key))   -- ksiz
      insert(t, _set_byte4(#value)) -- vsiz
      insert(t, key)                -- key
      insert(t, value)              -- value
   end

   local bytes, err = _send_request(self, OP_PLAY_SCRIPT, flags, concat(t))

   if not bytes then
      return nil, "fail to send packet: " .. err
   end
   
   local data, err = sock:receive(5) 
   if not data then
      return nil, "failed to receive packet: " .. err
   end

   local rv, pos = _get_byte(data, 1)

   if rv == INTERNAL_SERVER_ERROR then
      return nil, "interner server error"
   end

   local num = _get_byte4(data, pos)

   --print("hits= ", num)

   -- data
   local results = {}
   for i=1, num do
      local t = {}
      data, err = sock:receive(8) 

      local ksiz, pos = _get_byte4(data, 1)
      --print("ksiz= ", ksiz)
      
      local vsiz = _get_byte4(data, pos)
      --print("vsiz= ", vsiz)
      
      data, err = sock:receive(ksiz) 
      --print("key= ", data)
      t["key"] = data

      data, err = sock:receive(vsiz) 
      --print("val= ", data)
      t["value"] = data

      results[#results+1] = t
   end

   if #results == 0 then
      return nil, "no record was found"
   else
      return results, nil
   end
end


local function _set_bulk(self, tab)
   local flags = flags or 0
   local sock = self.sock

   if not tab or #tab == 0 then
      return nil, "invalid arguments"
   end

   local t = { _set_byte4(#tab) }    -- rnum

   for _, v in ipairs(tab) do
      local key = v[1]
      local value = v[2]
      if type(value) ~= "string" then
         value = tostring(value)
      end
      local xt = v[3] or 0xffffffff   -- max int ???
      local dbidx = v[4] or 0
      insert(t, _set_byte2(dbidx))    -- dbidx 
      insert(t, _set_byte4(#key))     -- ksiz
      insert(t, _set_byte4(#value))   -- vsiz
      insert(t, _set_byte8(xt))       -- xt
      insert(t, key)                  -- key
      insert(t, value)                -- value
   end

   local bytes, err = _send_request(self, OP_SET_BULK, flags, concat(t))

   if not bytes then
      return nil, "fail to send packet: " .. err
   end

   local data, err = sock:receive(5) 
   if not data then
      return nil, "failed to receive packet: " .. err
   end

   local rv, pos = _get_byte(data, 1)

   if rv == INTERNAL_SERVER_ERROR then
      return nil, "interner server error"
   end

   rv = _get_byte4(data, pos)

   --print("# of stored= ", rv)

   return rv, nil
end


_M.set_bulk = _set_bulk


function _M.set(self, ...)
   return _set_bulk(self, {{...}})
end


local function _remove_bulk(self, tab)
   local flags = flags or 0
   local sock = self.sock

   if not tab or #tab == 0 then
      return nil, "invalid arguemtns"
   end

   local t = { _set_byte4(#tab) }    -- rnum

   for _, v in ipairs(tab) do
      local key = v
      insert(t, _set_byte2(0))        -- dbidx 
      insert(t, _set_byte4(#key))     -- ksiz
      insert(t, key)                  -- key
   end

   local bytes, err = _send_request(self, OP_REMOVE_BULK, flags, concat(t))

   if not bytes then
      return nil, "fail to send packet: " .. err
   end

   local data, err = sock:receive(5) 
   if not data then
      return nil, "failed to receive packet: " .. err
   end

   local rv, pos = _get_byte(data, 1)

   if rv == INTERNAL_SERVER_ERROR then
      return nil, "interner server error"
   end

   rv = _get_byte4(data, pos)

   --print("# of removed= ", rv)

   return rv, nil
end


_M.remove_bulk = _remove_bulk


function _M.remove(self, key)
   return _remove_bulk(self, {key})
end


local function _get_bulk(self, tab)
   local flags = flags or 0
   local sock = self.sock

   if not tab or #tab == 0 then
      return nil, "invalid arguemtns"
   end

   local t = { _set_byte4(#tab) }    -- rnum

   for _, v in ipairs(tab) do
      local key = v
      insert(t, _set_byte2(0))        -- dbidx 
      insert(t, _set_byte4(#key))     -- ksiz
      insert(t, key)                  -- key
   end

   local bytes, err = _send_request(self, OP_GET_BULK, flags, concat(t))

   if not bytes then
      return nil, "fail to send packet: " .. err
   end

   local data, err = sock:receive(5) 
   if not data then
      return nil, "failed to receive packet: " .. err
   end

   local rv, pos = _get_byte(data, 1)

   if rv == INTERNAL_SERVER_ERROR then
      return nil, "interner server error"
   end

   local num, pos = _get_byte4(data, pos)

   --print("hits= ", num)

   -- data
   local results = {}

   for i=1, num do
      local t = {}
      data, err = sock:receive(18) 

      rv, pos = _get_byte2(data, 1)
      --print("dbidx= ", rv)
      t["dbidx"] = rv

      local ksiz, pos = _get_byte4(data, pos)
      --print("ksiz= ", ksiz)
      
      local vsiz, pos = _get_byte4(data, pos)
      --print("vsiz= ", vsiz)
      
      local xt = _get_byte8(data, pos)
      --print("xt= ", xt)
      t["xt"] = xt

      data, err = sock:receive(ksiz) 
      --print("key= ", data)
      t["key"] = data

      data, err = sock:receive(vsiz) 
      --print("val= ", data)
      t["value"] = data

      results[#results+1] = t
   end

   if #results == 0 then
      return nil, "no record was found"
   else
      return results, nil
   end
end


_M.get_bulk = _get_bulk


function _M.get(self, key)
   local res, err = _get_bulk(self, {key})
   if not res then
      return nil, err
   end

   local t = res[1]
   return t.value, nil
end


function _M.new(self)
   local sock, err = tcp()
   if not sock then
      return nil, err
   end
   return setmetatable({ sock = sock }, mt)
end


function _M.set_timeout(self, timeout)
   local sock = self.sock
   if not sock then
      return nil, "not initialized"
   end

   return sock:settimeout(timeout)
end


function _M.connect(self, ...)
   local sock = self.sock
   if not sock then
      return nil, "not initialized"
   end

   return sock:connect(...)
end


function _M.set_keepalive(self, ...)
   local sock = self.sock
   if not sock then
      return nil, "not initialized"
   end

   return sock:setkeepalive(...)
end


function _M.get_reused_times(self)
   local sock = self.sock
   if not sock then
      return nil, "not initialized"
   end

   return sock:getreusedtimes()
end


function _M.close(self)
   local sock = self.sock
   if not sock then
      return nil, "not initialized"
   end

   return sock:close()
end


return _M

