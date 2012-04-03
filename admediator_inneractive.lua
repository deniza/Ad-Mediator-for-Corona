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

local adServerUrl = "http://m2m1.inner-active.com/simpleM2M/clientRequestAd"
local protocolVersion = "Sm2m-1.5.3"
local deviceId = system.getInfo("deviceID")
local userAgent = AdMediator.getUserAgentString()
local clientId = "0"
local clientKey = ""
local platformId
local metaTag = AdMediator.viewportMetaTagForPlatform()

local function adRequestListener(event)

    local available = true
    local i,f,statusOK, imageUrl, adUrl
    
    if event.isError then
        available = false
    else
            
        i,f,statusOK = string.find(event.response, '(<tns:Response Error="OK")')
        clientId = event.response:match('<tns:Client Id="(.-)"')
        
        if clientId == nil then
            clientId = "0"
        end
        
        adUrl =  event.response:match('<tns:URL>(.-)</tns:URL>')
        imageUrl =  event.response:match('<tns:Image>(.-)</tns:Image>')
        
        if statusOK == nil or adUrl == nil or imageUrl == nil then
            available = false
        end
        
    end
    
    local htmlContent = ""
    if available then    
        local banner = '<a href="'..adUrl..'"><img src="'..imageUrl..'"/></a>'
        htmlContent = '<html><head>'..metaTag..'</head><body style="margin:0; padding:0;">' .. banner .. '</body></html>'
    end
    
    Runtime:dispatchEvent({name="adMediator_adResponse",available=available,htmlContent=htmlContent})
    
end

function instance:init(networkParams)
    clientKey = networkParams.clientKey
    
    if system.getInfo("platformName") == "Android" then
        platformId = "559"
    else
        platformId = "642"
    end
    
    print("inneractive init:",clientKey)
end

function instance:requestAd()
    
    local headers = {} 
    headers["User-Agent"] = userAgent
    
    local params = {}
    params.headers = headers
    
    local uriParams = "aid=" .. clientKey .. "&v="..protocolVersion.."&po="..platformId.."&w=320&h=480&hid="..deviceId.."&cid=" .. clientId .. "&t=" .. os.time()
    network.request(adServerUrl.."?"..uriParams,"GET",adRequestListener,params)
    
end

return instance