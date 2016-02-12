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

new
---
`syntax: ktc, err = kt:new(opts?)`

Creates a kyototycoon object. In case of failures, returns `nil` and a string describing the error.

It accepts an optional `opts` table argument.

connect
-------
`syntax: ok, err = ktc:connect(host, port)`

`syntax: ok, err = ktc:connect("unix:/path/to/unix.sock")`

Attempts to connect to the remote host and port that the kyototycoon server is listening to or a local unix domain socket file listened by the kyototycoon server.

Before actually resolving the host name and connecting to the remote backend, this method will always look up the connection pool for matched idle connections created by previous calls of this method.


replication
---

play_script
---

set_bulk
---

set
---
`syntax: ok, err = ktc:set(key, value, exptime)`

Inserts an entry into kyototycoon unconditionally. If the key already exists, overrides it.

The `exptime` parameter is optional, defaults to `0xffffffff`.


remove_bulk
---

remove
---
`syntax: ok, err = ktc:remove(key)`

Deletes the key from kyototycoon immediately.

The key to be deleted must already exist in kyototycoon.

In case of success, returns `1`. In case of errors, returns `nil` with a string describing the error.


get_bulk
---

get
---
`syntax: value, err = ktc:get(key)`

Get a single entry in the kytotycoon server via a single key.

The key's value will be returned if the entry is found and no error happens.

In case of errors, `nil` values will be turned for decribing the error.

If the entry is not found, then three `nil` values will be returned.


set_timeout
----------
`syntax: ok, err = ktc:set_timeout(time)`

Sets the timeout (in ms) protection for subsequent operations, including the `connect` method.

Returns 1 when successful and nil plus a string describing the error otherwise.

set_keepalive
------------
`syntax: ok, err = ktc:set_keepalive(max_idle_timeout, pool_size)`

Puts the current kyototycoon connection immediately into the ngx_lua cosocket connection pool.

You can specify the max idle timeout (in ms) when the connection is in the pool and the maximal size of the pool every nginx worker process.

In case of success, returns `1`. In case of errors, returns `nil` with a string describing the error.

Only call this method in the place you would have called the `close` method instead. Calling this method will immediately turn the current kyototycoon object into the `closed` state. Any subsequent operations other than `connect()` on the current objet will return the `closed` error.

get_reused_times
----------------
`syntax: times, err = ktc:get_reused_times()`

This method returns the (successfully) reused times for the current connection. In case of error, it returns `nil` and a string describing the error.

If the current connection does not come from the built-in connection pool, then this method always returns `0`, that is, the connection has never been reused (yet). If the connection comes from the connection pool, then the return value is always non-zero. So this method can also be used to determine if the current connection comes from the pool.

close
-----
`syntax: ok, err = ktc:close()`

Closes the current kyototycoon connection and returns the status.

In case of success, returns `1`. In case of errors, returns `nil` with a string describing the error.


Authors
=======

Soojin Nam <jsunam@gmail.com>, Kakao Corp.
