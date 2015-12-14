Name
====
lua-resty-kyototycoon - Lua Kyototycoon client driver for ngx_lua based on the cosocket API

Status
======
This library is still experimental and under early development.

Description
===========
Kyototycoon's binary protocol: http://fallabs.com/kyototycoon/spex.html#protocol


Example
=======
```` lua
location /kttest {
    content_by_lua '
      local kt = require "resty.kyototycoon"
      local ktc, err = kt:new()
      if not ktc then
         ngx.say("failed to instantiate ktc: ", err)
         return
      end

      ktc:set_timeout(1000) -- 1 sec

      local ok, err = ktc:connect("127.0.0.1", 1978)
      if not ok then
         ngx.say("failed to connect: ", err)
         return
      end

      -- set
      local num, err = ktc:set_bulk {
        {"aaa", 23, 600},
        {"bbb", "BBB", 100},
        {"ccc", "CCC"}}
      -- local num, err = ktc:set("aaa", 23)
      if not num then
         ngx.say("fail to set data: ", err)
         return
      end
      ngx.say("# of stored= ", num)

      -- get
      local tab, err = ktc:get_bulk{"aaa", "bbb", "ccc"}
      if not tab then
         ngx.say("fail to get data: ", err)
         return
      end
      for i, v in ipairs(tab) do
      ngx.say(v.dbidx, " ", v.xt, " ", v.key, " ", v.value)
      end
      --[[
      local val, err = ktc:get("aaa") -- {key="aaa"}
      if not val then
         ngx.say("fail to get data: ", err)
         return
      end
      ngx.say(val)
      --]]

      -- play_script
      -- http://fallabs.com/kyototycoon/luadoc/
      -- $ ktserver -scr myscript.lua
      local tab = { {key="key", value="aaa"} }
      local results, err = ktc:play_script("get", tab)
      if not results then
         ngx.say("fail to play script: ", err)
         return
      end
      for i, v in ipairs(results) do
      ngx.say(v.key, " ", v.value)
      end

      -- remove
      num, err = ktc:remove_bulk{"aaa", "bbb", "ccc"}
      if not num then
         ngx.say("fail to remove data: ", err)
         return
      end
      -- num, err = ktc:remove("aaa")

      local ok, err = ktc:close()
      if not ok then
         ngx.say("failed to close: ", err)
         return
      end
    ';
}
````


API
===


replication
---

play_script
---

set_bulk
---

set
---

remove_bulk
---

remove
---

get_bulk
---

get
---

Authors
=======

Soojin Nam <jsunam@gmail.com>, Kakao Corp.
