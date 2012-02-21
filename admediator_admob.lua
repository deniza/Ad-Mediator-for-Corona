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
--local url = require("socket.url")
local instance = {}

local adServerUrl = "http://googleads.g.doubleclick.net"
local admobTestPublisherId = "a14e8f77524dde8"
local publisherId = ""
local platform = system.getInfo("model")
local submodel = system.getInfo("architectureInfo")
local testMode
local appIdentifier
local userAgentIOS = "Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_2 like Mac OS X; en) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8F190 Safari/6533.18.5"
local userAgentAndroid = "Mozilla/5.0 (Linux; U; Android 2.2; en-us; Nexus One Build/FRF91) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1"
local userAgent
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

    if event.isError then
        available = false
    end
    
    if string.find(event.response, "<html>", 1, false) ~= 1 then
        available = false
    end
    
    Runtime:dispatchEvent({name="adMediator_adResponse",available=available,htmlContent=event.response})

end

function instance:init(networkParams)
    publisherId = networkParams.publisherId
    testMode = networkParams.test
    appIdentifier = networkParams.appIdentifier or "com.yourcompany.yourapp"
    
    platform = urlencode(platform)
    submodel = urlencode(submodel)
    
    if system.getInfo("platformName") == "Android" then
        userAgent = userAgentIOS
    else
        userAgent = userAgentAndroid
    end
    
    print("admob init:",publisherId)
end

function instance:requestAd()
    
    local headers = {} 
    headers["User-Agent"] = userAgent
    
    local params = {}
    params.headers = headers
    
    local requestUri = adServerUrl

    if testMode then
        publisherId = admobTestPublisherId
    end    
        
    requestUri = requestUri .. "/mads/gma?u_audio=1&hl=tr&preqs=1&app_name="..appIdentifier.."&u_h=480&cap_bs=1&u_so=p&u_w=320&ptime=60&js=afma-sdk-i-v5.0.5&slotname="..publisherId.."&platform="..platform.."&submodel="..submodel.."&u_sd=2&format=320x50_mb&output=html&region=mobile_app&u_tz=-120&ex=1&client_sdk=1&askip=1&caps=SdkAdmobApiForAds&jsv=3"
    if testMode then
        requestUri = requestUri .. "&adtest=on"
    end
    
    network.request(requestUri,"GET",adRequestListener,params)
    
end

return instance