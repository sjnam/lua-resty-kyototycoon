Name
====

lua-resty-kyototycoon - Lua Kyototycoon client driver for ngx_lua based on the cosocket API


Description
===========
Kyototycoon's binary protocol: http://fallabs.com/kyototycoon/spex.html#protocol


Example
=======
```` lua
lua_package_path  "/usr/local/openresty/lualib/?.lua;;";
lua_package_cpath "/usr/local/openresty/lualib/?.so;;";

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
        local num, err = ktc:set{dbidx=0, key="aaa", value="AAA", xt=600}
        if not num then
           ngx.say("fail to set data: ", err)
           return
        end
        ngx.say("# of stored= ", num)

        -- get
        local tab, err = ktc:get{dbidx=0, key="aaa"}
        if not tab then
           ngx.say("fail to get data: ", err)
           return
        end
        ngx.say(tab.dbidx.." "..tab.xt.." "..tab.key.." "..tab.value)

        -- play_script
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
        num, err = ktc:remove{dbidx=0, key="aaa"}
        if not num then
           ngx.say("fail to remove data: ", err)
           return
        end

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

remove_bulk
---

get_bulk
---



Authors
=======

Donald Nam <jsunam@gmail.com>, Kakao Corp.
