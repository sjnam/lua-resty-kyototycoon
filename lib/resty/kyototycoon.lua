-- Copyright (C) 2014 Donald Nam, Kakao Corp.


local bit = require "bit"
local tcp = ngx.socket.tcp
local strbyte = string.byte
local strchar = string.char
local band = bit.band
local bor = bit.bor
local lshift = bit.lshift
local rshift = bit.rshift
local tohex = bit.tohex
local concat = table.concat
local setmetatable = setmetatable
local error = error


local ok, new_tab = pcall(require, "table.new")
if not ok then
   new_tab = function (narr, nrec) return {} end
end


local _M = { _VERSION = '0.11' }


-- constants

local INTERNAL_SERVER_ERROR = 0xBF
local OP_REPLICATION = 0xB1
local OP_PLAY_SCRIPT = 0xB4
local OP_SET_BULK = 0xB8
local OP_REMOVE_BULK = 0xB9
local OP_GET_BULK = 0xBA


local mt = { __index = _M }


local function _get_byte(data, i)
   local a, b = strbyte(data, i)
   return a, i + 1
end


local function _get_byte2(data, i)
   local a, b = strbyte(data, i, i + 1)
   return bor(lshift(a, 8), b), i + 2
end


local function _get_byte4(data, i)
   local a, b, c, d = strbyte(data, i, i + 3)
   return bor(lshift(a, 24), lshift(b, 16), lshift(c, 8), d), i + 4
end


local function _get_byte8(data, i)
   local a, b, c, d, e, f, g, h = strbyte(data, i, i + 7)

   local lo = bor(h, lshift(g, 8), lshift(f, 16), lshift(e, 24))
   local hi = bor(d, lshift(c, 8), lshift(b, 16), lshift(a, 24))
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
   return strchar(band(rshift(n, 56), 0xff),
                  band(rshift(n, 48), 0xff),
                  band(rshift(n, 40), 0xff),
                  band(rshift(n, 32), 0xff),
                  band(rshift(n, 24), 0xff),
                  band(rshift(n, 16), 0xff),
                  band(rshift(n, 8), 0xff),
                  band(n, 0xff))
end


local function _dump(data)
   local len = #data
   local bytes = new_tab(len, 0)
   for i = 1, len do
      bytes[i] = strbyte(data, i)
   end
   return concat(bytes, " ")
end


local function _dumphex(data)
   local len = #data
   local bytes = new_tab(len, 0)
   for i = 1, len do
      bytes[i] = tohex(strbyte(data, i), 2)
   end
   return concat(bytes, " ")
end


local function _send_packet(self, magic, flag, req)
   local sock = self.sock
   local packet = _set_byte(magic) .. _set_byte4(flag) .. req
   return sock:send(packet)
end


function _M.replication(self, ts, sid)
   return "not implemented", nil
end


function _M.play_script(self, name, keytab, valtab)
   local flags = 0
   local sock = self.sock

   if #keytab ~= #valtab then
      return nil, "parameter error"
   end

   local t = { _set_byte4(#name) }  -- nsiz
   
   t[#t+1] = _set_byte4(#keytab)    -- rnum
   t[#t+1] = name                   -- preocedure name

   for i=1, #keytab do
      local key = keytab[i]
      local val = valtab[i]
      t[#t+1] = _set_byte4(#key)    -- ksiz
      t[#t+1] = _set_byte4(#val)    -- vsiz
      t[#t+1] = key                 -- key
      t[#t+1] = val                 -- value
   end

   local bytes, err = _send_packet(self, OP_PLAY_SCRIPT, flags, concat(t))

   if not bytes then
      return nil, "fail to send packet"
   end
   
   local data, err = sock:receive(5) 
   if not data then
      return nil, "failed to receive packet header: " .. err
   end

   local rv, pos = _get_byte(data, 1)

   if rv == INTERNAL_SERVER_ERROR then
      return nil, "interner server error"
   end

   local num = _get_byte4(data, pos)

   ngx.log(ngx.DEBUG, "hits= ", num)

   -- data
   local vals = {}
   for i=1, num do
      local t = {}
      data, err = sock:receive(8) 

      local ksiz, pos = _get_byte4(data, 1)
      --ngx.log(ngx.DEBUG, "ksiz= ", ksiz)
      
      local vsiz = _get_byte4(data, pos)
      --ngx.log(ngx.DEBUG, "vsiz= ", vsiz)
      
      data, err = sock:receive(ksiz) 
      --ngx.log(ngx.DEBUG, "key= ", data)
      t["key"] = data

      data, err = sock:receive(vsiz) 
      --ngx.log(ngx.DEBUG, "val= ", data)
      t["value"] = data

      vals[#vals+1] = t
   end

   return vals, nil
end


function _M.set_bulk(self, keytab, valtab)
   local flags = 0
   local sock = self.sock

   if #keytab ~= #valtab then
      return nil, "parameter error"
   end

   local t = { _set_byte4(#keytab) }  -- rnum

   for i=1, #keytab do
      local key = keytab[i]
      local val = valtab[i]
      t[#t+1] = _set_byte2(0)         -- dbidx 
      t[#t+1] = _set_byte4(#key)      -- ksiz
      t[#t+1] = _set_byte4(#val)      -- vsiz
      t[#t+1] = _set_byte8(600)       -- xt
      t[#t+1] = key                   -- key
      t[#t+1] = val                   -- value
   end

   local bytes, err = _send_packet(self, OP_SET_BULK, flags, concat(t))

   if not bytes then
      return nil, "fail to send packet"
   end

   local data, err = sock:receive(5) 
   if not data then
      return nil, "failed to receive packet header: " .. err
   end

   local rv, pos = _get_byte(data, 1)

   if rv == INTERNAL_SERVER_ERROR then
      return nil, "interner server error"
   end

   rv = _get_byte4(data, pos)

   --ngx.log(ngx.DEBUG, "# of stored= ", rv)

   return rv, nil
end


function _M.remove_bulk(self, keytab)
   local flags = 0
   local sock = self.sock

   local t = { _set_byte4(#keytab) }  -- rnum

   for i, key in ipairs(keytab) do
      t[#t+1] = _set_byte2(0)         -- dbidx 
      t[#t+1] = _set_byte4(#key)      -- ksiz
      t[#t+1] = key                   -- key
   end

   local bytes, err = _send_packet(self, OP_REMOVE_BULK, flags, concat(t))

   if not bytes then
      return nil, "fail to send packet"
   end

   local data, err = sock:receive(5) 
   if not data then
      return nil, "failed to receive packet header: " .. err
   end

   local rv, pos = _get_byte(data, 1)

   if rv == INTERNAL_SERVER_ERROR then
      return nil, "interner server error"
   end

   rv = _get_byte4(data, pos)

   --ngx.log(ngx.DEBUG, "# of removed= ", rv)

   return rv, nil
end


function _M.get_bulk(self, keytab)
   local flags = 0
   local sock = self.sock

   local t = { _set_byte4(#keytab) }  -- rnum

   for i, key in ipairs(keytab) do
      t[#t+1] = _set_byte2(0)         -- dbidx 
      t[#t+1] = _set_byte4(#key)      -- ksiz
      t[#t+1] = key                   -- key 
   end

   local bytes, err = _send_packet(self, OP_GET_BULK, flags, concat(t))

   if not bytes then
      return nil, "fail to send packet"
   end

   local data, err = sock:receive(5) 
   if not data then
      return nil, "failed to receive packet header: " .. err
   end

   local rv, pos = _get_byte(data, 1)

   if rv == INTERNAL_SERVER_ERROR then
      return nil, "interner server error"
   end

   local num, pos = _get_byte4(data, pos)

   --ngx.log(ngx.DEBUG, "hits= ", num)

   -- data
   local vals = {}

   for i=1,num do
      local t = {}
      data, err = sock:receive(10) 

      rv, pos = _get_byte2(data, 1)
      --ngx.log(ngx.DEBUG, "dbidx= ", rv)
      t["dbidx"] = rv

      local ksiz, pos = _get_byte4(data, pos)
      --ngx.log(ngx.DEBUG, "ksiz= ", ksiz)
      
      local vsiz = _get_byte4(data, pos)
      --ngx.log(ngx.DEBUG, "vsiz= ", vsiz)
      
      data, err = sock:receive(8)
      local xt = _get_byte8(data, 1)
      --ngx.log(ngx.DEBUG, "xt= ", xt)
      t["xt"] = xt

      data, err = sock:receive(ksiz) 
      --ngx.log(ngx.DEBUG, "key= ", data)
      t["key"] = data

      data, err = sock:receive(vsiz) 
      --ngx.log(ngx.DEBUG, "val= ", data)
      t["value"] = data

      vals[#vals+1] = t
   end

   return vals, nil
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
