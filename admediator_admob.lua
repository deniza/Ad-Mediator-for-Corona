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
local userAgent = AdMediator.getUserAgentString()
local deviceId = system.getInfo("deviceID")
local preqs = 0
local askip = 0
local ptime = 1
local starttime

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
    
    local metaTag = AdMediator.viewportMetaTagForPlatform()
    local htmlContent = string.gsub(event.response,'<meta name="viewport" content="(.+)"/>',metaTag)
    
    -- in case of a missing viewport meta tag, we insert ours anyway
    local htmlContent = string.gsub(htmlContent,'<head>','<head>'..metaTag)
    
    Runtime:dispatchEvent({name="adMediator_adResponse",available=available,htmlContent=htmlContent})

end

function instance:init(networkParams)
    publisherId = networkParams.publisherId
    testMode = networkParams.test
    appIdentifier = networkParams.appIdentifier or "com.yourcompany.yourapp"
    
    platform = urlencode(platform)
    submodel = urlencode(submodel)
    
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
     
    local now = os.time()
    preqs = preqs + 1
    if preqs == 1 then
        starttime = now
    end    
    
    askip = askip + 1
    if askip > 4 then
        askip = 0
    end
        
    local prl_net = ""
    if preqs > 1 then
        prl_net = "&prl="..math.random(500,600).."&net=wi"
        ptime = (now-starttime) * 1000
    end
        
    requestUri = requestUri .. "/mads/gma?u_audio=1&hl=en&preqs="..preqs.."&app_name="..appIdentifier.."&u_h=480&cap_bs=1&u_so=p&u_w=320&ptime="..ptime.."&js=afma-sdk-i-v5.0.5&slotname="..publisherId.."&platform="..platform.."&submodel="..submodel.."&u_sd=2&format=320x50_mb&output=html&region=mobile_app&u_tz=-120&ex=1&client_sdk=1&askip="..askip.."&caps=SdkAdmobApiForAds&jsv=3"..prl_net
    if testMode then
        requestUri = requestUri .. "&adtest=on"
    end
    
    network.request(requestUri,"GET",adRequestListener,params)
    
end

return instance