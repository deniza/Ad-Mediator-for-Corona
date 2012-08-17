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

local interstitialAdState_notvisible = 0
local interstitialAdState_requested = 1
local interstitialAdState_displaying = 2

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

local currentAdType = nil        --banner ads
local adTypeInterstitial = 2
local adTypeAlert = 10
local interstitialAdsCallbackFunction = nil
local interstitialAdsPosX = 0
local interstitialAdsPosY = 0
local interstitialAdState = interstitialAdState_notvisible

local function urlencode(str)
  if (str) then
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w ])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")
  end
  return str    
end

local function displayContentInWebPopup(x,y,contentWidth,contentHeight,contentHtml)
    
    local filename = "webview_tapit.html"
    local path = system.pathForFile( filename, system.TemporaryDirectory )
    local fhandle = io.open(path,"w")
    
    local newX = x
    local newY = y
    local newWidth = contentWidth
    local newHeight = contentHeight
    local scale = 1/display.contentScaleY
    
    if platform == AdMediator.PLATFORM_ANDROID then

        -- Max scale for android is 2 (enforced above just in case), so adjust web popup if over 2. 
        if scale > 2 then
            scale = scale/2
            newWidth = (contentWidth/scale) + 1
            newHeight = (contentHeight/scale) + 2
            newX = x + (contentWidth - newWidth)/2
            newY = y + (contentHeight - newHeight)/2
        end
            
    end
 
    fhandle:write(contentHtml)
    io.close(fhandle)
    
    local function webPopupListener( event )

        if string.find(event.url, "file://", 1, false) == 1 then
            return true
        else

            if interstitialAdsCallbackFunction then
                interstitialAdsCallbackFunction("adclicked")
            end

            timer.performWithDelay(10,function()
                system.openURL(event.url)
                native.cancelWebPopup()
            end)
            
        end
    end    
    
    -- fix scaling issues for ipad 3rd generation
    if 1/display.contentScaleY > 4 then
        newWidth = newWidth * 2
        newHeight = newHeight * 2
    end
    
    --cancel any opened web views first
    native.cancelWebPopup()

    local options = { hasBackground=false, baseUrl=system.TemporaryDirectory, urlRequest=webPopupListener } 
    native.showWebPopup( newX, newY, newWidth, newHeight, filename.."?"..os.time(), options)        
        
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
    local interstitialDisplayed = false

    print("response:",event.response)

    if event.isError or event.response == "" then        
        available = false
    else

        local responseAsJson = json.decode(event.response)

        if responseAsJson.error then
            available = false

            if interstitialAdState == interstitialAdState_requested then
                if interstitialAdsCallbackFunction then
                    interstitialAdsCallbackFunction("notavailable")
                    interstitialAdsCallbackFunction = nil
                end

                interstitialAdState = interstitialAdState_notvisible

            end

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

                    local currentAdHeight = tonumber(responseAsJson.adHeight)
                    
                    responseAsJson.html = string.gsub(responseAsJson.html,'target=','target_disabled=')
                    htmlContent = '<html><head>'..metaTag..'</head><body style="margin:0; padding:0; text-align:center">'..responseAsJson.html..'</body></html>'

                    if currentAdHeight >= 53 then

                        displayContentInWebPopup(interstitialAdsPosX,interstitialAdsPosX,tonumber(responseAsJson.adWidth),currentAdHeight,htmlContent)

                        interstitialDisplayed = true
                        interstitialAdState = interstitialAdState_displaying

                        if interstitialAdsCallbackFunction then
                            interstitialAdsCallbackFunction("displaying")
                        end

                    end

                end

            else
                print("unsupported ad type received", responseAsJson.type)
                available = false
            end
        end
    end
    
    if not interstitialDisplayed then
        Runtime:dispatchEvent({name="adMediator_adResponse",available=available,htmlContent=htmlContent})
    end

end

function instance:requestAlertAds()
    
    local prevAdType = currentAdType
    currentAdType = adTypeAlert

    self:requestAd()

    currentAdType = prevAdType

end

function instance:requestInterstitialAds(x,y,callbackFunction)
    
    interstitialAdsCallbackFunction = callbackFunction
    interstitialAdsPosX = x
    interstitialAdsPosY = y
    interstitialAdState = interstitialAdState_requested

    local prevAdType = currentAdType

    currentAdType = adTypeInterstitial
    self:requestAd()

    currentAdType = prevAdType

end

function instance:closeInterstitialAds()
    
    interstitialAdState = interstitialAdState_notvisible
    interstitialAdsCallbackFunction = nil

    native.cancelWebPopup()

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
        mode = operationMode,
    }

    if currentAdType == adTypeAlert or currentAdType == adTypeInterstitial then
        reqParams["adtype"] = currentAdType
    end

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