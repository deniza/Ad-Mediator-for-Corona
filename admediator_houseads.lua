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

local houseAds = {}
local currentHouseAdIdx = 1

local function adRequestListener(event)

    local available = true
    if event.isError then
        available = false
    end
    
    Runtime:dispatchEvent({name="adMediator_adResponse",available=available,imageUrl=houseAds[currentHouseAdIdx].image,adUrl=houseAds[currentHouseAdIdx].target})

    currentHouseAdIdx = currentHouseAdIdx + 1
    if currentHouseAdIdx > #houseAds then
        currentHouseAdIdx = 1
    end

end

function instance:init(networkParams)

    print("houseads init")

    for _,p in ipairs(networkParams) do
        houseAds[#houseAds+1] = p
        print(p.image,p.target)
    end

end

function instance:requestAd()
    
    network.request(houseAds[currentHouseAdIdx].image,"GET",adRequestListener)
    
end

return instance