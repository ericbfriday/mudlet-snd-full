-- Create control buttons
function SnD.GUI.createButtons()
    -- Toggle GUI button
    SnD.GUI.toggleBtn = Geyser.Label:new({
        name = "SND_Toggle",
        text = "[Hide/Show]",
        color = "cyan",
        clickFunction = SnD.GUI.toggle
    }, SnD.GUI.buttonPanel)
    
    -- Update targets button
    SnD.GUI.updateBtn = Geyser.Label:new({
        name = "SND_Update",
        text = "[Update]",
        color = "green", 
        clickFunction = function()
            send("campaign")
        end
    }, SnD.GUI.buttonPanel)
    
    -- Settings button
    SnD.GUI.settingsBtn = Geyser.Label:new({
        name = "SND_Settings",
        text = "[Settings]",
        color = "yellow",
        clickFunction = SnD.GUI.showSettings
    }, SnD.GUI.buttonPanel)
    
    cecho("<green>Control buttons created<reset>")
end

-- Toggle GUI visibility
function SnD.GUI.toggle()
    if SnD.GUI.main and SnD.GUI.main:isVisible() then
        SnD.GUI.main:hide()
    else
        SnD.GUI.main:show()
    end
end

-- Show settings (placeholder)
function SnD.GUI.showSettings()
    cecho("<yellow>Settings panel not yet implemented<reset>")
end