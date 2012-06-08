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
local urlmodule = require("socket.url")
local instance = {}

local adServerUrl = "http://googleads.g.doubleclick.net"
local admobTestPublisherId = "a14e8f77524dde8"
local publisherId = ""
local platform = system.getInfo("model")
local submodel = system.getInfo("architectureInfo")
local deviceType = AdMediator.getPlatform()
local testMode
local appIdentifier
local userAgent = AdMediator.getUserAgentString()
local deviceId = system.getInfo("deviceID")
local preqs = 0
local askip = 0
local ptime = 1
local starttime
local prevClickUrl
local prevOpenUrl
local jsVersion = "afma-sdk-i-v5.0.5"
local language = "en"
local adFormat = "320x50_mb"
--local adFormat = "728x90_as"
--local adFormat = "468x60_as"


local function urlencode(str)
  if (str) then
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w ])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")
  end
  return str	
end

local function decodeUrlEncodedString(str)
    return string.gsub(str, "%%(%x%x)", function (h) return string.char(tonumber(h, 16)) end)    
end

local function parse_query_string(query)
	local parsed = {}
	local pos = 0

	query = string.gsub(query, "&amp;", "&")
	query = string.gsub(query, "&lt;", "<")
	query = string.gsub(query, "&gt;", ">")

	local function ginsert(qstr)
		local first, last = string.find(qstr, "=")
		if first then
			parsed[string.sub(qstr, 0, first-1)] = string.sub(qstr, first+1)
		end
	end

	while true do
		local first, last = string.find(query, "&", pos)
		if first then
			ginsert(string.sub(query, pos, first-1));
			pos = last+1
		else
			ginsert(string.sub(query, pos));
			break;
		end
	end
	return parsed
end

local function webPopupListener( event )            
        
    if string.find(event.url, "file://",1,true) then        
        return true
        
    elseif string.find(event.url, "gmsg://",1,true) then
        
        local parsedUrl = urlmodule.parse(event.url)
        local params = parse_query_string(parsedUrl.query)            
        local link = decodeUrlEncodedString(params.u)
                    
        if parsedUrl.path == "/click" then
            
            if prevClickUrl ~= link then
                network.request(link,"GET")
                prevClickUrl = link
            end
            
        elseif parsedUrl.path == "/open" then

            if prevOpenUrl ~= link then
            
                timer.performWithDelay(10,function()                
                    system.openURL(link)
                    native.cancelWebPopup()
                end)
                
                prevOpenUrl = link
            end
            
        end            
        
        return true
        
    elseif string.find(event.url, "http://",1,true) or string.find(event.url, "https://",1,true) or string.find(event.url, "tel:",1,true) or string.find(event.url, "mailto:",1,true) then
    
        local parsedUrl = urlmodule.parse(event.url)
        if parsedUrl.host == "googleads.g.doubleclick.net" or parsedUrl.host == "www.googleadservices.com" then
            return true
        end
    
        timer.performWithDelay(10,function()
           system.openURL(event.url)
            native.cancelWebPopup()
        end)
        return true
    else
    
        print("unknown protocol scheme", event.url)
        return true
    
    end
end    


local function adRequestListener(event)

    local available = true
    local htmlContent = ""

    if event.isError or not string.find(event.response, "<html>", 1, true) then
        available = false
    end
    
    if available then
    
        -- disable current viewport meta tag if any
        htmlContent = string.gsub(event.response,'<meta name="viewport','<meta name="viewport_disabled')
        
        -- insert ours
        local metaTag = AdMediator.viewportMetaTagForPlatform() .. "<meta charset='utf-8'>"
        htmlContent = string.gsub(htmlContent,'<head>','<head>'..metaTag)
        
    end
    
    Runtime:dispatchEvent({name="adMediator_adResponse",available=available,htmlContent=htmlContent})

end

function instance:init(networkParams)
    publisherId = networkParams.publisherId
    testMode = networkParams.test
    appIdentifier = networkParams.appIdentifier or "com.yourcompany.yourapp"
    
    platform = urlencode(platform)
    submodel = urlencode(submodel)
    
    if deviceType == AdMediator.PLATFORM_ANDROID then
        jsVersion = "afma-sdk-a-v4.3.1"
    end
    
    print("admob init:",publisherId)
end

function instance:customWebPopupListener()
    return webPopupListener
end

function instance:requestAd()
    
    prevClickUrl = nil
    prevOpenUrl = nil
    
    local headers = {} 
    headers["User-Agent"] = userAgent
    
    local params = {}
    params.headers = headers
    
    local requestUri = adServerUrl

    if testMode then
        publisherId = admobTestPublisherId
    end    
     
    local now = os.time()
    preqs = preqs + 1
    if preqs == 1 then
        starttime = now
    end    
    
    askip = askip + 1
    if askip > 4 then
        askip = 0
    end
        
    local prl_net = ""
    if preqs > 1 then
        prl_net = "&prl="..math.random(500,600).."&net=wi"
        ptime = (now-starttime) * 1000
    end
            
    requestUri = requestUri .. "/mads/gma?u_audio=1&hl="..language.."&preqs="..preqs.."&app_name="..appIdentifier.."&u_h=480&cap_bs=1&u_so=p&u_w=320&ptime="..ptime.."&js="..jsVersion.."&slotname="..publisherId.."&platform="..platform.."&submodel="..submodel.."&u_sd=2&format="..adFormat.."&output=html&region=mobile_app&u_tz=-120&ex=1&client_sdk=1&askip="..askip.."&caps=SdkAdmobApiForAds&jsv=3"..prl_net
    if testMode then
        requestUri = requestUri .. "&adtest=on"
    end
    
    network.request(requestUri,"GET",adRequestListener,params)
    
end

return instance