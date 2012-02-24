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
local userAgent = AdMediator.getUserAgentString()
local clientId = 0
local clientKey = ""
local metaTag = AdMediator.viewportMetaTagForPlatform()

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
    
    -- disable input meta tags
    local htmlContent = string.gsub(event.response,'<meta name="','<meta name="_disabled_')
    
    local htmlContent = '<html><head>'..metaTag..'</head><body style="margin:0; padding:0;">' .. htmlContent .. '</body></html>'    
    Runtime:dispatchEvent({name="adMediator_adResponse",available=available,htmlContent=htmlContent})

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