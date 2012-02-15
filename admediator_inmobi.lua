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
local clientKey = ""
local testMode
local deviceId = system.getInfo("deviceID")

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
    print("inmobi init:",clientKey)
end

function instance:requestAd()
    
    local headers = {} 
    headers["Content-Type"] = "application/x-www-form-urlencoded"
    headers["X-Mkhoj-SiteID"] = clientKey
    
    local params = {}
    params.headers = headers
    params.body = "mk-siteid=" .. clientKey .. "&u-id=" .. deviceId .. "&mk-version=pr-SPEC-ATATA-20090521&h-user-agent=InMobi_Specs_iPhoneApp%3D1.0.2%20(iPhone%3B%20iPhone%20OS%203.1.2%3B%20HW%20iPhone2%2C1)&d-localization=en_US&d-netType=wifi&mk-ad-slot=9"
    
    local server = adServerUrl
    if testMode then
        server = adServerUrl_test
    end
    
    network.request(server,"POST",adRequestListener,params)
    
end

return instance