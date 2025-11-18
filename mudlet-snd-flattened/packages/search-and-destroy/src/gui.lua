-- Main GUI container
SnD.GUI = SnD.GUI or {}

function SnD.GUI.init()
    -- Main window (dockable, resizable)
    SnD.GUI.main = Geyser.UserWindow:new({
        name = "SND_Main",
        title = "Search and Destroy",
        x = "70%", y = "30%",
        width = "30%", height = "40%"
    })
    
    -- Vertical layout container
    SnD.GUI.layout = Geyser.VBox:new({
        name = "SND_Layout",
        x = 0, y = 0,
        width = "100%", height = "100%"
    }, SnD.GUI.main)
    
    -- Title label
    SnD.GUI.title = Geyser.Label:new({
        name = "SND_Title",
        text = "<center><b>Search and Destroy</b></center>",
        color = "blue",
        fontSize = 12
    }, SnD.GUI.layout)
    
    -- Campaign list container
    SnD.GUI.campaignContainer = Geyser.Container:new({
        name = "SND_CampaignContainer",
        x = 0, y = 0,
        width = "100%", height = "70%"
    }, SnD.GUI.layout)
    
    -- Button panel
    SnD.GUI.buttonPanel = Geyser.HBox:new({
        name = "SND_ButtonPanel",
        x = 0, y = "70%",
        width = "100%", height = "30%"
    }, SnD.GUI.layout)
    
    cecho("<green>GUI initialized<reset>")
end