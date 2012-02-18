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

local widget = require("widget")
require("admediator")

local function initGui()

    local showButton = widget.newButton{
        label = "show",
        left = 50,
        top = 200,
        width = 100, height = 40,
        onRelease = function() AdMediator.show() end
    }
    local hideButton = widget.newButton{
        label = "hide",
        left = 170,
        top = 200,
        width = 100, height = 40,
        onRelease = function() AdMediator.hide() end
    }
 
end

local function remote_configuration()

    -- If you choose to use remote configuration, all you have to do is to call
    -- AdMediator.initFromUrl(configURL)
    -- Please see included ad configuation file (admediator-init.config) for further configuration parameters

    AdMediator.initFromUrl("http://yourserver/admediator-init.config?"..os.time())

end

local function local_configuration()

    -- init function takes three arguments; adposition_x, adposition_y and ad_request_delay_in_seconds
    AdMediator.init(0,0,60)
    
    -- optionally, you can use a nice banner slide animation when changing banners
    -- targetx and targety are coordinates used when hiding current banner.
    -- You probably set them to offscreen values.
    -- Duration is animation duration in miliseconds.
    AdMediator.useAnimation(0,-50,1500)
    
    -- after initializing the module, we should add some ad networks and configure them.
    -- AdMediator comes with inmobi, inneractive, herewead and houseads. You can add
    -- new networks if you wish.
    
    -- There are 4 parameters common for all networks; name, weight, enabled and backfillpriority
    -- name should be the file name of the ad network plugin script file without lua extension
    -- It can be one of "admediator_inmobi", "admediator_inneractive" or "admediator_houseads"
    -- weight denotes network selection priority as fill percentage. It can be betwwen 0 and 100.
    -- The rule is; all network weight values shoud sum up to 100. A network with weight equals to zero
    -- will never be selected for ad serving. If you have 2 networks, and you give first network a weight
    -- of 40 and second one a weight of 60, that means first network have a 40% chance to serve an ad, while
    -- second network has a chance of 60%
    -- backfillpriority is used to select next available network if there are no ads served from currently selected
    -- ad provider. AdMediator always selects the next network with lowest backfillpriority
    -- enabled is an optional parameter with a default value true. You can easily disable ad network by setting it to false.
    -- networkParams is an ad plugin specific configuration block. If you plan to implement your own network
    -- plugins, you should use this block to get extended parameters.
    
    -- Below we configure inmobi, inneractive and herewead networks with respective weight values.
    -- A final houseads network is configured with a weight of 0 and highest priority value.
    -- That means; this network will never be selected for ad serving, but if there are no ads from
    -- each of 3 providers, AdMediator will use this last plugin to fetch our house ads.
    
    -- clientKey is you application specific token from inmobi
    -- if you want to server demo (test) ads, set test parameter to true and use the
    -- demo token 4028cba631d63df10131e1d4650600cd
    AdMediator.addNetwork(
        {
            name="admediator_inmobi",
            weight=34,
            backfillpriority=1,
            networkParams = {
                clientKey="4028cba631d63df10131e1d4650600cd",
                test=true,
            },
        }
    )
    
    AdMediator.addNetwork(
        {
            name="admediator_inneractive",    
            weight=33,
            backfillpriority=2,
            networkParams = {
                clientKey="YOUR_APPLICATION_TOKEN_FROM_INNERACTIVE",
            },            
        }
    )
    
    -- herewead network uses additional channelId and zoneId parameters.
    -- You should get them from herewead after registiring your application.
    AdMediator.addNetwork(
        {
            name="admediator_herewead",
            weight=33,
            backfillpriority=3,
            networkParams = {
                channelId="YOUR_CHANNEL_ID_FROM_HEREWEAD",
                zoneId="0",
                test=true,
            },            
        }
    )
    
    -- you can configure houseads plugin by using an array of (banner_image, target_url) data 
    AdMediator.addNetwork(
        {
            name="admediator_houseads",
            weight=0,
            backfillpriority=4,
            networkParams = {
                {image="http://he2apps.com/okey/adsv2/chatkapi.png",target="http://bit.ly/housead_target1"},
                {image="http://he2apps.com/okey/adsv2/komikreplikler.jpg",target="http://bit.ly/housead_target2"},
                {image="http://he2apps.com/okey/adsv2/2resim5fark.jpg",target="http://bit.ly/housead_target3"},
            },            
        }
    )
    
    -- finally, start serving ads
    AdMediator.start()       
    
end

display.setStatusBar( display.HiddenStatusBar )

initGui()

-- You can configure AdMediator either manually or by using a remote configuration URI
--
--
-- For this sample application we use manual configuration
local_configuration()
--remote_configuration()
