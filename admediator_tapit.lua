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
local udid_hashed = ""   --not used
local testMode
local testZoneId = 3644
local enableAlertAds
local operationMode = ""
local swapAlertButtons
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

local function showAdAlert(message, clickUrl, callToAction, declineString)

    local function alertHandler(event)
        if event.action == "clicked" then
            
            local calltoActionIndex = 2
            if swapAlertButtons then
                calltoActionIndex = 1
            end

            if event.index == calltoActionIndex then
                system.openURL(clickUrl)
            else
                --just close alert window automatically
            end
        end
    end

    local buttons = { declineString, callToAction }
    if swapAlertButtons then
        buttons = { callToAction, declineString }
    end

    local alert = native.showAlert( "", message, buttons, alertHandler )

end

local function adRequestListener(event)

    local available = true
    local htmlContent = ""

    print("response:",event.response)

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
            acceptedAdTypes["alert"] = true

            if acceptedAdTypes[responseAsJson.type] == true then
                
                if responseAsJson.type == "alert" then
                
                    if enableAlertAds then

                        local clickUrl = responseAsJson.clickurl
                        local title = responseAsJson.adtitle
                        local callToAction = responseAsJson.calltoaction
                        local declineString = responseAsJson.declinestring

                        showAdAlert(title, clickUrl, callToAction, declineString)
                    else

                        print("alert ad received, but its disabled")
                        available = false    

                    end

                else

                    responseAsJson.html = string.gsub(responseAsJson.html,'target=','target_disabled=')
                    htmlContent = '<html><head>'..metaTag..'</head><body style="margin:0; padding:0; text-align:center">'..responseAsJson.html..'</body></html>'

                end

            else
                print("unsupported ad type received", responseAsJson.type)
                available = false
            end
        end
    end
    
    Runtime:dispatchEvent({name="adMediator_adResponse",available=available,htmlContent=htmlContent})

end

function instance:requestAlertAds()
    
    local prevOperationMode = operationMode
    operationMode = "test"

    self:requestAd()

    opeationMode = prevOperationMode

end

function instance:init(networkParams)

    zoneId = networkParams.zoneId
    testMode = networkParams.test
    enableAlertAds = networkParams.enableAlertAds or true
    swapAlertButtons = networkParams.swapButtons or false

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
        udid = udid_hashed,
        format = "json",
        carrier = "unknown",
        connection_speed = 1,
        plugin = "corona-" .. pluginProtocolVersion,
        mode = operationMode
    }

    if platform == AdMediator.PLATFORM_ANDROID then
        reqParams["sdk"] = "android-v1.7.1"
    else
        reqParams["client"] = "iOS-SDK"
        reqParams["version"] = "2.0.0"
    end


    local requestUri = "http://r.tapit.com/adrequest.php?"

    for key,value in pairs(reqParams) do
        requestUri = requestUri .. key .. "=" .. value .. "&"
    end

    network.request(requestUri,"GET",adRequestListener)
    
end

return instance