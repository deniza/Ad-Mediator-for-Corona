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
local clientId = 0
local clientKey = ""

local function adRequestListener(event)

    local available = true
    local i,f,imageUrl,adUrl,statusOK
    
    if event.isError then
        available = false
    else
            
        i,f,statusOK = string.find(event.response, "(Error=\"OK\")")
        i,f,imageUrl = string.find(event.response, "<tns:Image>(.+)</tns:Image>")
        i,f,adUrl = string.find(event.response, "<tns:URL>(.+)</tns:URL>")
        clientId = event.response:match('Client Id="(.-)"')
        
        if adUrl == nil or imageUrl == nil or statusOK == nil then
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
    print("inneractive init:",clientKey)
end

function instance:requestAd()
    
    local params = "aid=" .. clientKey .. "&v="..protocolVersion.."&po=642&w=320&h=480&hid="..deviceId.."&cid=" .. clientId .. "&t=" .. os.time()    
    network.request(adServerUrl.."?"..params,"GET",adRequestListener)
    
end

return instance