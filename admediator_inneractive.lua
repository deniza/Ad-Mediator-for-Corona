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

local adServerUrl = "http://wv.inner-active.mobi/simpleM2M/clientRequestWVBannerOnly"
local protocolVersion = "2.0.1-iOS-S-1.0.9"
local deviceId = system.getInfo("deviceID")
local userAgent = "Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_2 like Mac OS X; en) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8F190 Safari/6533.18.5"
local clientId = 0
local clientKey = ""

local function adRequestListener(event)

    local available = true
    local i,f,statusOK
    
    if event.isError then
        available = false
    else
            
        i,f,statusOK = string.find(event.response, '(<meta name="inneractive.error" content="OK")')
        clientId = event.response:match('<meta name="inneractive.cid" content="(.-)"')
        
        if statusOK == nil then
            available = false
        end
        
    end
    
    Runtime:dispatchEvent({name="adMediator_adResponse",available=available,htmlContent=event.response})

end

function instance:init(networkParams)
    clientKey = networkParams.clientKey
    print("inneractive init:",clientKey)
end

function instance:requestAd()
    
    local headers = {} 
    headers["User-Agent"] = userAgent
    
    local params = {}
    params.headers = headers
    
    local uriParams = "aid=" .. clientKey .. "&v="..protocolVersion.."&po=642&w=320&h=480&hid="..deviceId.."&cid=" .. clientId .. "&t=" .. os.time()    
    network.request(adServerUrl.."?"..uriParams,"GET",adRequestListener,params)
    
end

return instance