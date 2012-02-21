------------------------------------------------------------
------------------------------------------------------------
-- Ad Mediator for Corona
--
-- Ad network mediation module for Ansca Corona
-- by Deniz Aydinoglu
--
-- he2apps.com
--
-- GitHub repository and documentation:
-- https://github.com/deniza/Ad-Mediator-for-Corona
------------------------------------------------------------
------------------------------------------------------------

local instance = {}

local adServerUrl = "http://i.w.inmobi.com/showad.asm"
local adServerUrl_test = "http://i.w.sandbox.inmobi.com/showad.asm"
local inmobiTestClientKey = "4028cba631d63df10131e1d4650600cd"
local clientKey = ""
local testMode
local userAgentIOS = "Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_2 like Mac OS X; en) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8F190 Safari/6533.18.5"
local userAgentAndroid = "Mozilla/5.0 (Linux; U; Android 2.2; en-us; Nexus One Build/FRF91) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1"
local userAgent
local inmobiUA_ios = "inmobi_iossdk=3.0.2 (iPhone; iPhone OS 4.2; HW iPhone3,1)"
local inmobiUA_android = "InMobi_AndroidSDK=1.1 (Specs)"
local inmobiUA
local inmobiUAEncoded
local deviceId = system.getInfo("deviceID")

local function urlencode(str)
  if (str) then
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w ])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")
  end
  return str	
end


local function adRequestListener(event)

    local available = true
    local i,f,imageUrl,adUrl

    if event.isError then
        available = false
    else
    
        i,f,imageUrl = string.find(event.response, "<ImageURL>(.+)</ImageURL>")
        i,f,adUrl = string.find(event.response, "<AdURL>(.+)</AdURL>")
        if adUrl == nil or imageUrl == nil then
            available = false
        else
            --replace url encoded &amp; symbols with &
            imageUrl = imageUrl:gsub("&amp;","&")
            adUrl = adUrl:gsub("&amp;","&")
        end
        
    end
    
    Runtime:dispatchEvent({name="adMediator_adResponse",available=available,imageUrl=imageUrl,adUrl=adUrl})

end

function instance:init(networkParams)
    clientKey = networkParams.clientKey
    testMode = networkParams.test

    if system.getInfo("platformName") == "Android" then
        userAgent = userAgentAndroid
        inmobiUA = inmobiUA_android
    else
        userAgent = userAgentIOS
        inmobiUA = inmobiUA_ios
    end
    
    inmobiUAEncoded = urlencode(inmobiUA)
        
    print("inmobi init:",clientKey)
end

function instance:requestAd()

    local adserver = adServerUrl
    local activeClientKey = clientKey
    
    if testMode then
        adserver = adServerUrl_test
        activeClientKey = inmobiTestClientKey
    end
    
    local headers = {} 
    headers["Content-Type"] = "application/x-www-form-urlencoded"
    headers["X-Mkhoj-SiteID"] = activeClientKey
    headers["User-Agent"] = inmobiUA
    headers["X-Inmobi-Phone-Useragent"] = userAgent
    headers["Mk-Banner-Size"] = "9"
    
    local params = {}
    params.headers = headers
    
    local userAgentEncoded = inmobiUAEncoded
    params.body = "mk-siteid=" .. activeClientKey .. "&u-id=" .. deviceId .. "&mk-carrier="..AdMediator.clientIPAddress.."&mk-version=pr-SPEC-ATATA-20090521&h-user-agent="..userAgentEncoded.."&d-localization=en_US&d-netType=wifi&mk-ad-slot=9"
    
    
    network.request(adserver,"POST",adRequestListener,params)
    
end

return instance