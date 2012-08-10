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

local requestParams
local requestType
local requestUrl
local rawResponse
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

        if rawResponse then
            htmlContent = event.response 
        else
            htmlContent = '<html><head>'..metaTag..'</head><body style="margin:0; padding:0;">'..event.response..'</body></html>'
        end
    end
    
    Runtime:dispatchEvent({name="adMediator_adResponse",available=available,htmlContent=htmlContent})

end

function instance:init(networkParams)

    requestUrl = networkParams.requestUrl
    requestType = networkParams.requestType or "GET"
    requestParams = networkParams.requestParams or {}
    rawResponse = networkParams.rawResponse or false

    print("customHtml init:",requestServer)

end

function instance:requestAd()

    if requestType == "POST" then

        local headers = {} 
        headers["Content-Type"] = "application/x-www-form-urlencoded"
        headers["Accept"] = "text/html"
        
        local params = {}
        params.headers = headers
        
        params.body = ""

        for key,value in pairs(requestParams) do
            params.body = params.body .. key .. "=" .. value .. "&"
        end

        network.request(requestUrl,"POST",adRequestListener,params)
        
    else

        -- GET request

        local requestUri = requestUrl .. "?"

        for key,value in pairs(requestParams) do
            requestUri = requestUri .. key .. "=" .. urlencode(value) .. "&"
        end

        network.request(requestUri,"GET",adRequestListener)

    end
    
end

return instance