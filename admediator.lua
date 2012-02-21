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

require("json")

AdMediator = {
    clientIPAddress = "",
}

local networks = {}
local weightTable = {}
local networksByPriority = {}
local adRequestDelay = nil
local currentNetworkIdx = nil
local currentImageUrl = nil
local currentAdUrl = nil
local currentBanner = nil
local loadingBeacon = false
local isHidden = false
local enableWebView = false
local webPopupVisible = false
local currentWebPopupContent
local adDisplayGroup = display.newGroup()
local adPosX
local adPosY
local animationEnabled = false
local animationTargetX
local animationTargetY
local animationDuration

local function findClientIPAddress()

    local function ipListener(event)
        if not event.isError and event.response ~= "" then
            AdMediator.clientIPAddress = event.response
        end
    end
    
    network.request("http://whatismyip.org","GET",ipListener)

end


local function cleanPreviousLoadFailStatus()
    for i=1,#networks do
        networks[i].failedToLoad = false
    end
end

local function fetchNextNetworkBasedOnPriority()
    
    if isHidden then
        return
    end
    
    for _,network in pairs(networksByPriority) do
        if not network.failedToLoad then
            currentNetworkIdx = network.idx
            network:requestAd()
            --print("requesting ad:",network.name)
            break
        end        
    end
    
end

local function fetchRandomNetwork()

    if isHidden then
        return
    end
    
    local random = math.floor(math.random()*100) + 1
    for i=1,#weightTable do        
        if random >= weightTable[i].min and random <= weightTable[i].max then
            currentNetworkIdx = i
            break
        end
    end
    
    networks[currentNetworkIdx]:requestAd()    
    --print("requesting ad:",networks[currentNetworkIdx].name)

end

local function displayContentInWebPopup(x,y,width,height,contentHtml)
        
    local filename = "webview.html"
    local path = system.pathForFile( filename, system.TemporaryDirectory )
    local fhandle = io.open(path,"w")
    local meta = "<meta name=\"viewport\" content=\"width=320; user-scalable=0;\"/>"
    local bodyStyle = "<body style=\"margin:0; padding:0;\">"
    fhandle:write("<html><head>"..meta.."</head>"..bodyStyle..contentHtml.."</body></html>")
    io.close(fhandle)
    
    local function webPopupListener( event )            
        if string.find(event.url, "file://", 1, false) == 1 then
            return true
        else
            system.openURL(event.url)
        end
    end
    
    local options = { hasBackground=false, baseUrl=system.TemporaryDirectory, urlRequest=webPopupListener }
    native.showWebPopup( x, y, width, height, filename.."?"..os.time(), options)
    
    webPopupVisible = true
    currentWebPopupContent = contentHtml

end

local function hideCurrentBannerWithAnimation(onCompleteFunc)
    transition.to(adDisplayGroup,{time=animationDuration/2,x=animationTargetX,y=animationTargetY,onComplete=function()
            if currentBanner then
                currentBanner:removeSelf()
                currentBanner = nil
            end
            onCompleteFunc()
        end})
end

local function adImageDownloadListener(event)
    
    if not event.isError then
    
        local function showNewBanner(newBanner)
            if currentBanner then
                currentBanner:removeSelf()
            end
            currentBanner = newBanner
            currentBanner.isVisible = true
            adDisplayGroup:insert(currentBanner)            
        end
            
        if loadingBeacon then
        
            event.target:removeSelf()
            loadingBeacon = false
            
        else
        
            if animationEnabled then
                
                if currentBanner then
                
                    event.target.isVisible = false
                
                    hideCurrentBannerWithAnimation(function()
                            showNewBanner(event.target)
                            transition.to(adDisplayGroup,{time=animationDuration/2,x=adPosX,y=adPosY})
                        end)
                        
                else
                    adDisplayGroup.x = animationTargetX
                    adDisplayGroup.y = animationTargetY
                    showNewBanner(event.target)
                    
                    transition.to(adDisplayGroup,{time=animationDuration/2,x=adPosX,y=adPosY})
                end
                
            else                
                showNewBanner(event.target)
            end
        end
        
        cleanPreviousLoadFailStatus()
        
        --print("image loaded")
    
    else
        --print("image download error!")
    end        
    
end

local function adResponseCallback(event)
    
    local webPopupOpened = false
    
    if event.available then
        
        currentImageUrl = event.imageUrl
        currentAdUrl = event.adUrl
        
        if event.beacon then
            loadingBeacon = true
        else
            loadingBeacon = false
        end
        
        if event.htmlContent then
            
            if animationEnabled and currentBanner then            
                hideCurrentBannerWithAnimation(function()
                        displayContentInWebPopup(adPosX, adPosY, 320, 50, event.htmlContent)
                    end)
            else
                displayContentInWebPopup(adPosX, adPosY, 320, 50, event.htmlContent)                
            end
            
            networks[currentNetworkIdx].usesWebPopup = true
            
        else
        
            if enableWebView then
            
                local meta = "<meta name=\"viewport\" content=\"width=320; user-scalable=0;\"/>"
                local bodyStyle = "<body style=\"margin:0; padding:0;\">"
                local contentHtml = "<html><head>"..meta.."</head>"..bodyStyle.."<a href='"..currentAdUrl.."'><img src='"..currentImageUrl.."'/></a></body></html>"
                
                if animationEnabled and currentBanner then        
                    hideCurrentBannerWithAnimation(function()
                            displayContentInWebPopup(adPosX, adPosY, 320, 50, contentHtml)
                        end)
                else
                    displayContentInWebPopup(adPosX, adPosY, 320, 50, contentHtml)                    
                end
                
                networks[currentNetworkIdx].usesWebPopup = true
            
            else
                
                if webPopupVisible then
                    native.cancelWebPopup()
                    webPopupVisible = false
                end
                
                display.loadRemoteImage(currentImageUrl, "GET", adImageDownloadListener, "admediator_tmp_adimage_"..os.time(), system.TemporaryDirectory)
                
                networks[currentNetworkIdx].usesWebPopup = false
                
            end
            
        end
        
    else
    
        --print("network failed:",networks[currentNetworkIdx].name)
        networks[currentNetworkIdx].failedToLoad = true
        
        fetchNextNetworkBasedOnPriority()
    end
    
end

function AdMediator.init(posx,posy,adReqDelay)

    adRequestDelay = adReqDelay
    adDisplayGroup:addEventListener("tap",function() system.openURL(currentAdUrl) return true end)        
    
    AdMediator.setPosition(posx,posy)
    
    Runtime:addEventListener("adMediator_adResponse",adResponseCallback)

end

function AdMediator.initFromUrl(initUrl)

    local function initRequestListener(event)
    
        if event.isError then
            print("AdMediator error! mediator can not load configuration from url:" .. initUrl)
            return
        end
        
        local config = json.decode(event.response)
        
        if config.animation.enabled then
            animationEnabled = true
            animationTargetX = config.animation.targetx
            animationTargetY = config.animation.targety
            animationDuration = config.animation.duration
        end
        
        config.x = config.x or adPosX or 0
        config.y = config.y or adPosY or 0
        
        AdMediator.init(config.x,config.y,config.adDelay)
        AdMediator.useWebView(config.useWebView)
        
        if config.xscale and config.yscale then
            AdMediator.setScale(config.xscale, config.yscale)
        end
        
        for _,networkDef in ipairs(config.networks) do
            AdMediator.addNetwork( networkDef )
        end
        
        AdMediator.start()
    
    end
    
    network.request(initUrl, "GET", initRequestListener)

end

function AdMediator.show()
    isHidden = false
    adDisplayGroup.isVisible = true
    adDisplayGroup:toFront()
    
    if networks[currentNetworkIdx].usesWebPopup then
        displayContentInWebPopup(adPosX, adPosY, 320, 50, currentWebPopupContent)
    end    
    
end

function AdMediator.hide()
    isHidden = true
    adDisplayGroup.isVisible = false
    if webPopupVisible then
        native.cancelWebPopup()
        webPopupVisible = false
    end
end

function AdMediator.useAnimation(targetx,targety,duration)

    animationEnabled = true
    animationTargetX = targetx
    animationTargetY = targety
    animationDuration = duration

end

function AdMediator.setScale(scalex,scaley)
    adDisplayGroup:scale(scalex,scaley)
end

function AdMediator.useWebView(useFlag)
    enableWebView = useFlag
end

function AdMediator.setPosition(x,y)
    adPosX = x
    adPosY = y
    adDisplayGroup.x = adPosX
    adDisplayGroup.y = adPosY    
end

function AdMediator.addNetwork(params)

    if params.enabled == nil then
        params.enabled = true
    elseif params.enabled == false then
        return
    end
    
    local networkObject = require(params.name)
    networks[#networks+1] = networkObject
    networkObject.priority = params.backfillpriority
    networkObject.weight = params.weight
    networkObject.name = params.name
    networkObject.idx = #networks    
    
    networkObject:init(params.networkParams)
    
    print("addNetwork:",params.name,params.weight,params.backfillpriority)
    
end

function AdMediator.start()

    local totalWeight = 0    
    for _,network in ipairs(networks) do
        networksByPriority[#networksByPriority+1] = network
        totalWeight = totalWeight + network.weight
    end    
    table.sort(networksByPriority, function(a,b) return a.priority<b.priority end)
    
    if totalWeight < 100 then
        local delta = 100 - totalWeight
        local added = 0
        for _,network in ipairs(networks) do
            local toadd = math.floor(delta * network.weight/totalWeight)
            added = added + toadd 
            network.weight = network.weight + toadd
        end
        networks[1].weight = networks[1].weight + delta - added 
    end
    
    local currentMaxWeight = 0
    for _,network in ipairs(networks) do
        local weightRecord = {min=currentMaxWeight+1,max=currentMaxWeight+network.weight}
        currentMaxWeight = currentMaxWeight + network.weight
        weightTable[#weightTable+1] = weightRecord
        
        print("weight",_,network.weight)
    end
    
    fetchRandomNetwork()
    timer.performWithDelay( adRequestDelay * 1000, fetchRandomNetwork, 0 )

end

findClientIPAddress()