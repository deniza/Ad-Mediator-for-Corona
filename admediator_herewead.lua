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

local socket = require("socket")
local clientIP = ""

local adServerUrl = "http://ws.herewead.com/BannerOpr/GetBanner.aspx"
local useXmlResponse = true
local testMode
local channelId = nil
local zoneId = nil
local deviceId = system.getInfo("deviceID")
local sessionId = deviceId .. "_" .. os.time()
local userAgentString = "Mozilla/5.0 (iPhone; CPU iPhone OS 5_0_1 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A405 Safari/7534.48.3"

local function findClientIPAddress()

    local function ipListener(event)
        if not event.isError and event.response ~= "" then
            clientIP = event.response
        end
    end
    
    network.request("http://whatismyip.org","GET",ipListener)

end

local function adRequestListener(event)

    local available = true
    local i,f,imageUrl,adUrl
    
    if event.isError then
        available = false
    else
    
        if useXmlResponse then
    
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
            
            local beacon = false
            if exists == "0" then
                beacon = true
            end
            
            Runtime:dispatchEvent({name="adMediator_adResponse",available=available,imageUrl=imageUrl,adUrl=adUrl,beacon=beacon})
        
        else
        
            Runtime:dispatchEvent({name="adMediator_adResponse",available=available,htmlContent=event.response})
        
        end
        
    end
    
end

function instance:init(networkParams)
    channelId = networkParams.channelId
    zoneId = networkParams.zoneId
    testMode = networkParams.test
    useXmlResponse = not networkParams.useXHTMLBanners
    print("herewead init:",channelId,zoneId)
end

function instance:requestAd()
    
    local headers = {}    
    
    local responseType = "XHTML"
    if useXmlResponse then
        responseType = "XML"
    end
            
    local body = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
    body = body .. "<Parameters>" 
    body = body .. "<CodeVersion>PHP-20100920</CodeVersion>" 
    if testMode then
        body = body .. "<RequestType>TEST</RequestType>"
    else
        body = body .. "<RequestType>LIVE</RequestType>"
    end
    body = body .. "<ResponseType>"..responseType.."</ResponseType>"
    body = body .. "<ChannelID>"..channelId.."</ChannelID>" 
    body = body .. "<ZoneID>"..zoneId.."</ZoneID>" 
    body = body .. "<UserIP>"..clientIP.."</UserIP>" 
    body = body .. "<Url><![CDATA[http://he2apps.com]]></Url>" 
    body = body .. "<ReferrerUrl><![CDATA[http://he2apps.com]]></ReferrerUrl>" 
    body = body .. "<SessionID>"..sessionId.."</SessionID>" 
    body = body .. "<UserAgent><![CDATA["..userAgentString.."]]></UserAgent>" 
    body = body .. "<Random>"..os.time().."</Random>" 
    body = body .. "<UserID>"..deviceId.."</UserID>" 
    body = body .. "<Headers><![CDATA[".."Client-IP="..clientIP.." |".."]]></Headers>" 
    body = body .. "</Parameters>"
    
    local params = {}
    params.body = body
    params.headers = headers
    
    network.request(adServerUrl,"POST",adRequestListener, params)
    
end

findClientIPAddress()

return instance