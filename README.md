Name
====

lua-resty-kyototycoon - Lua Kyototycoon client driver for ngx_lua based on the cosocket API


Description
===========
A note on KT's binary protocol: http://fallabs.com/kyototycoon/spex.html#protocol


Example
=======
```` lua
lua_package_path  "/usr/local/openresty/lualib/?.lua;;";
lua_package_cpath "/usr/local/openresty/lualib/?.so;;";

location /test_remove {
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

        local dbtab = { 0, 0, 0 }
        local ktab = { "aa", "bb", "cc" }
        local num, err = ktc:remove_bulk(dbtab, ktab)
        if not num then
           ngx.say("fail to remove bulk: ", err)
           return
        end

        ngx.say("# of removed= ", num)
    ';
}

location /test_get {
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

        local dbtab = {0, 0, 0 }
        local tab = { "aa", "bb", "cc" }
        local results, err = ktc:get_bulk(dbtab, tab)
        if not results then
           ngx.say("fail to set foo: ", err)
           return
        end

        for i, v in ipairs(results) do
           ngx.say(v.dbidx, v.xt, v.key, v.value)
        end
    ';
}

location /test_playscript {
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

        local ktab = { "key" }
        local vtab = { "aa" }
        local values, err = ktc:play_script("get", ktab, vtab)

        if not values then
           ngx.say("fail to play script: ", err)
           return
        end

        for i, v in ipairs(values) do
           ngx.say(v.key, v.value)
        end
    ';
}

location /test_set {
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

        local dbtab = { 0, 0, 0 }
        local ktab = { "aa", "bb", "cc" }
        local vtab = { "AA", "BB", "CC" }
        local num, err = ktc:set_bulk(dbtab, ktab, vtab)
        if not num then
           ngx.say("fail to set foo: ", err)
           return
        end

        ngx.say("# of stored= ", num)

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

Soojin Nam <jsunam@gmail.com>, Kakao Corp.
