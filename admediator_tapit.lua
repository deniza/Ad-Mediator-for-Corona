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
local json = require("json")
local crypto = require("crypto")

local instance = {}

local platform = AdMediator.getPlatform()
local pluginProtocolVersion = "1.0"
local zoneId
local testMode
local testZoneId = 3644
local operationMode = nil
local userAgentEncoded
local metaTag = AdMediator.viewportMetaTagForPlatform()

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
    local htmlContent = ""

    --print("response:",event.response)

    if event.isError or event.response == "" then        
        available = false
    else

        local responseAsJson = json.decode(event.response)

        if responseAsJson.error then
            available = false
        else
            
            local acceptedAdTypes = {}
            acceptedAdTypes["banner"] = true
            acceptedAdTypes["html"] = true
            acceptedAdTypes["text"] = true
            acceptedAdTypes["alert"] = false

            if acceptedAdTypes[responseAsJson.type] == true then
                
                responseAsJson.html = string.gsub(responseAsJson.html,'target=','target_disabled=')
                htmlContent = '<html><head>'..metaTag..'</head><body style="margin:0; padding:0; text-align:center">'..responseAsJson.html..'</body></html>'

            else
                print("unsupported ad type received", responseAsJson.type)
                available = false
            end
        end
    end
    
    Runtime:dispatchEvent({name="adMediator_adResponse",available=available,htmlContent=htmlContent})

end

function instance:init(networkParams)

    zoneId = networkParams.zoneId
    testMode = networkParams.test

    if testMode then
        operationMode = "test"
    end

    userAgentEncoded = urlencode(AdMediator.getUserAgentString())

    print("tapit init:",zone)

end

function instance:requestAd()

    local activeZoneId = zoneId
    
    if testMode then
        activeZoneId = testZoneId
    end
    
    local reqParams = {
        zone = activeZoneId,
        ua = userAgentEncoded,
        format = "json",
        connection_speed = 1,
        plugin = "corona-" .. pluginProtocolVersion,
    }

    if operationMode then
        reqParams["mode"] = operationMode
    end

    local requestUri = "http://r.tapit.com/adrequest.php?"

    for key,value in pairs(reqParams) do
        requestUri = requestUri .. key .. "=" .. value .. "&"
    end

    network.request(requestUri,"GET",adRequestListener)
    
end

return instance