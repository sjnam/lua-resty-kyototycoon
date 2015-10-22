
kt = __kyototycoon__
db = kt.db

-- define constants
local alfsConst      = { ABUSE="abuse", LIMIT="limit",
			 HOURLY="hourly", DAILY="daily", MINUTELY="minutely", 
			 WEEKLY="weekly", MONTHLY="monthly", FROMNOW = "fromnow", 
			 OK="OK", ERROR="ERROR" }

-- alfs status code
local alfsStatus     = { success=0, errlogic=1, errsys=2 }
local CHECK_ONLY     = 0
local CHECK_AND_SET  = 1
local CLEAR          = 2
local DECREASE       = 3

-- alfs structure
local alfs = { storyPost={ daily={} },
	       storyScrap={ daily={} },
               talkChat={ minutely={} },
	       inviteTalkChat={ monthly={} },
	       inviteTalkChat2={ daily={} },
	       inviteTalkChat3={ daily={}, monthly={} },
	       inviteTalkChat32={ daily={}, monthly={} },
	       emoticonPromotion={ fromnow={} },
	       launcherPromotion={ fromnow={} },
	       retryQuiz={ daily={} }, 
	       linkTalkChat3={ daily={} }
}

alfs.storyPost.daily.mode       = alfsConst.LIMIT
alfs.storyPost.daily.args       = { "accountId", "clientId", "url" }
alfs.storyPost.daily.prefix     = "[SACUD]"
alfs.storyPost.daily.limitCnt   = 10 
alfs.storyPost.daily.limitType  = alfsConst.DAILY

alfs.storyScrap.daily.mode       = alfsConst.LIMIT
alfs.storyScrap.daily.args       = { "accountId", "clientId", "url" }
alfs.storyScrap.daily.prefix	 = "[SSCUD]"
alfs.storyScrap.daily.limitCnt   = 10
alfs.storyScrap.daily.limitType  = alfsConst.DAILY

alfs.talkChat.minutely.mode       = alfsConst.LIMIT
alfs.talkChat.minutely.args       = { "accountId", "clientId", "url" }
alfs.talkChat.minutely.prefix     = "[TACUM]"
alfs.talkChat.minutely.limitCnt   = 100
alfs.talkChat.minutely.limitType  = alfsConst.MINUTELY

alfs.inviteTalkChat.monthly.mode       = alfsConst.LIMIT
alfs.inviteTalkChat.monthly.args       = { "accountId", "clientId", "url" }
alfs.inviteTalkChat.monthly.prefix     = "[ITACUM]"
alfs.inviteTalkChat.monthly.limitCnt   = 1
alfs.inviteTalkChat.monthly.limitType  = alfsConst.MONTHLY

alfs.inviteTalkChat2.daily.mode       = alfsConst.LIMIT
alfs.inviteTalkChat2.daily.args       = { "accountId", "clientId", "url" }
alfs.inviteTalkChat2.daily.prefix     = "[IT2ACUM]"
alfs.inviteTalkChat2.daily.limitCnt   = 30
alfs.inviteTalkChat2.daily.limitType  = alfsConst.DAILY

alfs.inviteTalkChat3.daily.mode       = alfsConst.LIMIT
alfs.inviteTalkChat3.daily.args       = { "accountId", "clientId", "url" }
alfs.inviteTalkChat3.daily.prefix     = "[IT3ACUM-1]"
alfs.inviteTalkChat3.daily.limitCnt   = 3
alfs.inviteTalkChat3.daily.limitType  = alfsConst.DAILY

alfs.inviteTalkChat3.monthly.mode       = alfsConst.LIMIT
alfs.inviteTalkChat3.monthly.args       = { "accountId", "clientId", "url" }
alfs.inviteTalkChat3.monthly.prefix     = "[IT3ACUM-2]"
alfs.inviteTalkChat3.monthly.limitCnt   = 10
alfs.inviteTalkChat3.monthly.limitType  = alfsConst.MONTHLY

alfs.inviteTalkChat32.daily.mode       = alfsConst.LIMIT
alfs.inviteTalkChat32.daily.args       = { "accountId", "clientId", "url" }
alfs.inviteTalkChat32.daily.prefix     = "[ITC3ACUD]"
alfs.inviteTalkChat32.daily.limitCnt   = 6
alfs.inviteTalkChat32.daily.limitType  = alfsConst.DAILY

alfs.inviteTalkChat32.monthly.mode       = alfsConst.LIMIT
alfs.inviteTalkChat32.monthly.args       = { "accountId", "clientId", "url" }
alfs.inviteTalkChat32.monthly.prefix     = "[ITC32ACUM]"
alfs.inviteTalkChat32.monthly.limitCnt   = 20
alfs.inviteTalkChat32.monthly.limitType  = alfsConst.MONTHLY

alfs.emoticonPromotion.fromnow.mode       = alfsConst.LIMIT
alfs.emoticonPromotion.fromnow.args       = { "accountId", "clientId", "url" }
alfs.emoticonPromotion.fromnow.prefix     = "[EPACUF]"
alfs.emoticonPromotion.fromnow.limitCnt   = 1
alfs.emoticonPromotion.fromnow.limitType  = alfsConst.FROMNOW
alfs.emoticonPromotion.fromnow.limitTerm  = 1296000 -- 60*60*24*15 (15days)

alfs.launcherPromotion.fromnow.mode       = alfsConst.LIMIT
alfs.launcherPromotion.fromnow.args       = { "accountId", "url" }
alfs.launcherPromotion.fromnow.prefix     = "[LPAUF]"
alfs.launcherPromotion.fromnow.limitCnt   = 1
alfs.launcherPromotion.fromnow.limitType  = alfsConst.FROMNOW
alfs.launcherPromotion.fromnow.limitTerm  = 3456000 -- 60*60*24*40 (40days)

alfs.retryQuiz.daily.mode       = alfsConst.LIMIT
alfs.retryQuiz.daily.args       = { "accountId" }
alfs.retryQuiz.daily.prefix     = "[RAD]"
alfs.retryQuiz.daily.limitCnt   = 2 
alfs.retryQuiz.daily.limitType  = alfsConst.DAILY

alfs.linkTalkChat3.daily.mode       = alfsConst.LIMIT
alfs.linkTalkChat3.daily.args       = { "accountId", "clientId", "url" }
alfs.linkTalkChat3.daily.prefix     = "[LTC3ACUD]"
alfs.linkTalkChat3.daily.limitCnt   = 10
alfs.linkTalkChat3.daily.limitType  = alfsConst.DAILY


-- APIs
function checkAndSet(inmap, outmap)
   return __xalfs(inmap, outmap, CHECK_AND_SET)
end

function checkOnly(inmap, outmap)
   return __xalfs(inmap, outmap, CHECK_ONLY)
end

function clear(inmap, outmap)
   return __xalfs(inmap, outmap, CLEAR)
end

function decrease(inmap, outmap)
   return __xalfs(inmap, outmap, DECREASE)
end

function get(inmap, outmap)
   local psvc = inmap._svc
   if not psvc then
      kt.log("error", "parameter \"_svc\" can not be null")
      return kt.RVEINVALID
   end
   local svc = alfs[psvc]
   for tkey, tbl in pairs(svc) do
      local key = __getKey(tbl, inmap, nil)
      local value, xt = db:get(key)
      if value then
	 outmap[key] = value.." "..xt
      else
	 local err = db:error()
	 if err:code() == kt.Error.NOREC then
	    return kt.RVELOGIC
	 end
	 return kt.RVEINTERNAL
      end
   end
   return kt.RVSUCCESS
end

function list(inmap, outmap)
   local cur = db:cursor()
   cur:jump()
   while true do
      local key, value, xt = cur:get(true)
      if not key then break end
      outmap[key] = value.." "..xt
   end
   return kt.RVSUCCESS
end


-- check leap year
function __leapYear(year)
   return year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)
end

-- get days in month
function __daysInMonth(month, year)
   return month == 2 and __leapYear(year) and 29
      or ("\31\28\31\30\31\30\31\31\30\31\30\31"):byte(month)
end

-- trim a char
function __trimChar(s, c)
   return (string.gsub(s, "(.-)"..c.."*$", "%1"))
end

-- get expire time
function __getXt(tbl)
   local t1, t2
   if tbl.mode == alfsConst.LIMIT then
      t1 = os.time()
      d = os.date("*t")
      if tbl.limitType == alfsConst.DAILY 
	 or tbl.limitType == alfsConst.WEEKLY 
	 or tbl.limitType == alfsConst.MONTHLY then
         t2 = os.time{year=d.year, month=d.month, 
                      day=d.day, hour=23, min=59, sec=59}
      elseif tbl.limitType == alfsConst.HOURLY then
         t2 = os.time{year=d.year, month=d.month, 
                      day=d.day, hour=d.hour, min=59, sec=59}
      elseif tbl.limitType == alfsConst.MINUTELY then
         t2 = os.time{year=d.year, month=d.month, 
                      day=d.day, hour=d.hour, min=d.min, sec=59}
      elseif tbl.limitType == alfsConst.FROMNOW then
	 return tbl.limitTerm
      end
      if tbl.limitType == alfsConst.MONTHLY then
	 return os.difftime(t2, t1) + (__daysInMonth(d.month,d.year)-d.wday)*60*60*24
      elseif tbl.limitType == alfsConst.WEEKLY then
	 return os.difftime(t2, t1) + (7-d.wday)*60*60*24
      else
	 return os.difftime(t2, t1)
      end
   end
   return tbl.xt
end

-- escape string
function __escape(str)
   if not str then
      return ""
   end
   local s = string.gsub(str, "\\", "\\\\")
   return string.gsub(s, ":", "\\:")
end

-- get key
function __getKey(tbl, inmap, flag)
   local t = {}
   t[1] = tbl.prefix
   for k=1, #tbl.args do
      t[#t + 1] = flag and __escape(inmap[tbl.args[k]]) or inmap[tbl.args[k]]
   end
   return table.concat(t, ":")
end

-- get returnKey
function __getReturnKey(tbl, name)
   return table.concat(tbl.args,"_").."_"..tbl.limitType.."."..name
end


-- api check_and_set
function __xcheckAndSet(tbl, key)
   local cnt, xt, msg
   local rc = kt.RVSUCCESS
   local function visit(rkey, rvalue, rxt)
      rvalue = tonumber(rvalue)
      if not rvalue then 
         rvalue = 0 
         xt = __getXt(tbl)
      end
      cnt = rvalue + 1
      return cnt, xt
   end
   if not db:accept(key, visit) then
      rc = alfsStatus.errsys
   elseif tbl.limitCnt < 0 then
      rc = alfsStatus.success
      msg = cnt
   elseif cnt > tbl.limitCnt then
      kt.log("error", tbl.errmsg)
      rc = false
      rc = alfsStatus.errlogic
      msg = cnt
      if tbl.mode == alfsConst.ABUSE then
         if not db:set(key, cnt, tbl.addtime) then
            return kt.RVEINTERNAL
         end
      end
   else
      rc = alfsStatus.success
      msg = cnt
   end
   return rc, msg
end

-- api check_only
function __xcheckOnly(tbl, key)
   local msg
   local rc = kt.RVSUCCESS
   local cnt, xt = db:get(key)
   if cnt then
      local available = tbl.limitCnt - cnt
      if tbl.limitCnt < 0 then
         rc = alfsStatus.success
         msg = cnt
      elseif available < 0 then
         kt.log("error", tbl.errmsg)
         rc = false
         rc = alfsStatus.errlogic
         msg = cnt
      else
         rc = alfsStatus.success
         msg = cnt
      end
   else
      msg = "0"
   end
   return rc, msg
end

-- api clear
function __xclear(tbl, key)
   local msg
   local rc = kt.RVSUCCESS
   if not db:remove(key) then
      rc = alfsStatus.success --alfsStatus.errsys
   else
      rc = alfsStatus.success
   end
   return rc, "0"
end

-- api decrease
function __xdecrease(tbl, key)
   local cnt, xt, msg
   local rc = kt.RVSUCCESS
   local function visit(rkey, rvalue, rxt)
      rvalue = tonumber(rvalue)
      if not rvalue then 
         rvalue = 0 
         xt = __getXt(tbl)
      end
      cnt = rvalue - 1
      if cnt < 0 then cnt = 0 end
      return cnt, xt
   end
   if not db:accept(key, visit) then
      rc = alfsStatus.errsys
   else
      rc = alfsStatus.success
      msg = cnt
   end
   return rc, msg
end

-- alfs
function __xalfs(inmap, outmap, proto)
   local psvc = inmap._svc
   local rc = kt.RVSUCCESS
   local cnt, msg
   local rccnt = 0

   if not psvc then
      kt.log("error", "parameter \"_svc\" can not be null")
      return kt.RVEINVALID
   end

   local svc = alfs[psvc]
   for tkey, tbl in pairs(svc) do
      local key = __getKey(tbl, inmap, nil)
      if proto == CHECK_ONLY then
         rc, msg = __xcheckOnly(tbl, key)
      elseif proto == CHECK_AND_SET then
         rc, msg = __xcheckAndSet(tbl, key)
      elseif proto == CLEAR then
         rc, msg = __xclear(tbl, key)
      else
         rc, msg = __xdecrease(tbl, key)
      end
      if rc == alfsStatus.errsys then
	 return kt.RVEINVALID
      end
      if rc == alfsStatus.errlogic then 
	 rccnt = rccnt + 1
      end
      outmap[__getReturnKey(tbl, "limitCnt")] = tbl.limitCnt
      outmap[__getReturnKey(tbl, "trialCnt")] = msg
      kt.log("system", key)
   end
   if rccnt > 0 then
      outmap.status = alfsConst.ERROR
   else
      outmap.status = alfsConst.OK
   end
   return kt.RVSUCCESS
end


-- log the start-up message
if kt.thid == 0 then
   kt.log("system", "KAKAO Alfs has been started!")
end
