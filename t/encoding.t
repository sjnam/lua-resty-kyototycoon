# vim:set ft= ts=4 sw=4 et:

use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(2);

plan tests => repeat_each() * (3 * blocks());

my $pwd = cwd();

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?.lua;;";
};

$ENV{TEST_NGINX_RESOLVER} = '8.8.8.8';
$ENV{TEST_NGINX_KT_PORT} ||= 1978;

#no_long_string();

log_level('notice');

run_tests();

__DATA__

=== TEST 1: value contains "\t"
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local cjson = require "cjson"
            local kyototycoon = require "resty.kyototycoon"
            local kt = kyototycoon:new()

            kt:set_timeout(1000) -- 1 sec

            local ok, err = kt:connect("127.0.0.1", $TEST_NGINX_KT_PORT)
            if not ok then
               ngx.say("failed to connect to kt: ", err)
               return
            end

            local ok, err = kt:set("kyoto", "\ttycoon")
            if not ok then
               ngx.say("failed to set: ", err)
               return
            end

            ngx.say("set kyoto ok")

            local res, err = kt:get("kyoto")
            if err then
               ngx.say("failed to get kyoto ", err)
               return
            end

            if not res then
               ngx.say("kyoto not found.")
               return
            else
               ngx.say("kyoto: ", res)
            end

            kt:close()
        ';
}
--- request
    GET /t
--- response_body eval
"set kyoto ok
kyoto: \ttycoon
"
--- no_error_log
[error]

