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
local url = require("socket.url")
local instance = {}

local adServerUrl = "http://ws.herewead.com/BannerOpr/GetBanner.aspx"
local testMode
local channelId = nil
local zoneId = nil
local deviceId = system.getInfo("deviceID")
local sessionId = deviceId .. "_" .. os.time()
local userAgent = AdMediator.getUserAgentString()
local metaTag = AdMediator.viewportMetaTagForPlatform()

local function adRequestListener(event)

    local available = true
    local i,f,imageUrl,adUrl
    local htmlContent = ""
    
    if event.isError then
        available = false
    else
    
        i,f,imageUrl = string.find(event.response, "<imageSource>(.+)</imageSource>")
        i,f,adUrl = string.find(event.response, "<clickUrl>(.+)</clickUrl>")
        local i,f,exists = string.find(event.response, "<exists>(.+)</exists>")
    
        if imageUrl == nil or adUrl == nil then
            available = false
        else
            --strip CDATA section
            imageUrl = imageUrl:sub(10,imageUrl:len()-3)
            adUrl = adUrl:sub(10,adUrl:len()-3)
            exists = exists:sub(10,exists:len()-3)
        end
        
        if exists == "0" then
            -- its just beacon
            display.loadRemoteImage(imageUrl, "GET", nil, "admediator_tmp_beacon_"..os.time(), system.TemporaryDirectory)
            
            available = false
            
        end
        
        if available then
            htmlContent = '<html><head>'..metaTag..'</head><body style="margin:0; padding:0;"><a href="'..adUrl..'"><img src="'..imageUrl..'"/></a></body></html>'
        end
        
        Runtime:dispatchEvent({name="adMediator_adResponse",available=available,htmlContent=htmlContent})
            
    end
    
end

function instance:init(networkParams)
    channelId = networkParams.channelId
    zoneId = networkParams.zoneId
    testMode = networkParams.test
    print("herewead init:",channelId,zoneId)
end

function instance:requestAd()
    
    local headers = {}
    headers["User-Agent"] = userAgent
    
    local body = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
    body = body .. "<Parameters>" 
    body = body .. "<CodeVersion>PHP-20100920</CodeVersion>" 
    if testMode then
        body = body .. "<RequestType>TEST</RequestType>"
    else
        body = body .. "<RequestType>LIVE</RequestType>"
    end
    body = body .. "<ResponseType>XML</ResponseType>"
    body = body .. "<ChannelID>"..channelId.."</ChannelID>" 
    body = body .. "<ZoneID>"..zoneId.."</ZoneID>" 
    body = body .. "<UserIP>"..AdMediator.clientIPAddress.."</UserIP>" 
    body = body .. "<Url><![CDATA[http://he2apps.com]]></Url>" 
    body = body .. "<ReferrerUrl><![CDATA[http://he2apps.com]]></ReferrerUrl>" 
    body = body .. "<SessionID>"..sessionId.."</SessionID>" 
    body = body .. "<UserAgent><![CDATA["..userAgent.."]]></UserAgent>" 
    body = body .. "<Random>"..os.time().."</Random>" 
    body = body .. "<UserID>"..deviceId.."</UserID>" 
    body = body .. "<Headers><![CDATA[".."Client-IP="..AdMediator.clientIPAddress.." |".."]]></Headers>" 
    body = body .. "</Parameters>"
    
    local params = {}
    params.body = body
    params.headers = headers
    
    network.request(adServerUrl,"POST",adRequestListener, params)
    
end

return instance