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

local adServerUrl = "http://ad.madvertise.de/site/"
local testClientToken = "TestTokn"
local clientToken = ""
local testMode
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
    local i,f,imageUrl,adUrl
    local htmlContent = ""

    if event.isError or event.response == "" then
        available = false
    else    
        htmlContent = '<html><head>'..metaTag..'</head><body style="margin:0; padding:0;">'..event.response..'</body></html>'                        
    end
    
    Runtime:dispatchEvent({name="adMediator_adResponse",available=available,htmlContent=htmlContent})

end

function instance:init(networkParams)

    clientToken = networkParams.clientToken
    testMode = networkParams.test

    userAgentEncoded = urlencode(AdMediator.getUserAgentString())

    print("madvertise init:",clientToken)

end

function instance:requestAd()

    local adserver = adServerUrl
    local activeClientToken = clientToken
    
    if testMode then
        activeClientToken = testClientToken
    end
    
    local headers = {} 
    headers["Content-Type"] = "application/x-www-form-urlencoded"
    headers["Accept"] = "text/html"
    
    local params = {}
    params.headers = headers
    
    params.body = "ua="..userAgentEncoded
    network.request(adserver..activeClientToken,"POST",adRequestListener,params)
    
end

return instance