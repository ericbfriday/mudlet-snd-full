-- Global namespace for Search and Destroy
SnD = SnD or {}
SnD.version = "1.0.0"
SnD.config = SnD.config or {}
SnD.state = SnD.state or {}

-- Mudlet function compatibility layer
if not raiseEvent then
    function raiseEvent(eventName, data)
        if raiseEvent then
            raiseEvent("SND." .. eventName, data)
        else
            print("[Mock] raiseEvent:", eventName, data)
        end
    end
end

if not registerAnonymousEventHandler then
    function registerAnonymousEventHandler(event, handler)
        if registerAnonymousEventHandler then
            registerAnonymousEventHandler(event, handler)
        else
            print("[Mock] registerAnonymousEventHandler:", event)
        end
    end
end

if not setAreaUserData then
    function setAreaUserData(areaID, key, value)
        if setAreaUserData then
            setAreaUserData(areaID, key, value)
        else
            print("[Mock] setAreaUserData:", areaID, key, value)
        end
    end
end

if not getAllAreaUserData then
    function getAllAreaUserData(areaID)
        if getAllAreaUserData then
            getAllAreaUserData(areaID)
        else
            print("[Mock] getAllAreaUserData:", areaID)
            return {}
        end
    end
end

if not getRoomArea then
    function getRoomArea(roomID)
        if getRoomArea then
            getRoomArea(roomID)
        else
            print("[Mock] getRoomArea:", roomID)
            return 1
        end
    end
end

if not getRoomAreaName then
    function getRoomAreaName(areaID)
        if getRoomAreaName then
            getRoomAreaName(areaID)
        else
            print("[Mock] getRoomAreaName:", areaID)
            return "Mock Area"
        end
    end
end

if not getAreaTable then
    function getAreaTable()
        if getAreaTable then
            getAreaTable()
        else
            print("[Mock] getAreaTable")
            return {}
        end
    end
end

if not cecho then
    function cecho(text)
        if cecho then
            cecho(text)
        else
            print("[Mock] cecho:", text)
        end
    end
end

if not walkTo then
    function walkTo(path)
        if walkTo then
            walkTo(path)
        else
            print("[Mock] walkTo:", path)
        end
    end
end

if not mmp then
    mmp = {
        findRoute = function(from, to)
            print("[Mock] mmp.findRoute:", from, to)
            return {}
        end
    }
end

if not gmcp then
    gmcp = {
        room = {
            info = {
                num = 12345,
                name = "Mock Room",
                zone = "Mock Area"
            }
        },
        comm = {
            quest = {
                targets = {}
            }
        }
    }
end

if not send then
    function send(command)
        if send then
            send(command)
        else
            print("[Mock] send:", command)
        end
    end
end

if not tempTimer then
    function tempTimer(delay, callback)
        if tempTimer then
            tempTimer(delay, callback)
        else
            print("[Mock] tempTimer:", delay, callback)
        end
    end
end

if not tempRegexTrigger then
    function tempRegexTrigger(pattern, callback)
        if tempRegexTrigger then
            tempRegexTrigger(pattern, callback)
        else
            print("[Mock] tempRegexTrigger:", pattern, callback)
        end
    end
end

-- Geyser compatibility layer
if not Geyser then
    Geyser = {
        UserWindow = function(params)
            print("[Mock] Geyser.UserWindow:", params)
            return {
                new = function(self, params)
                    return {
                        name = params.name or "MockWindow",
                        show = function() print("[Mock] Window show") end,
                        hide = function() print("[Mock] Window hide") end,
                        isVisible = function() return true end
                    }
                end
            }
        end,
        VBox = function(params)
            print("[Mock] Geyser.VBox:", params)
            return {
                new = function(self, params)
                    return {
                        name = params.name or "MockVBox",
                        show = function() print("[Mock] VBox show") end,
                        hide = function() print("[Mock] VBox hide") end,
                        isVisible = function() return true end
                    }
                end
            }
        end,
        Label = function(params)
            print("[Mock] Geyser.Label:", params)
            return {
                new = function(self, params)
                    return {
                        name = params.name or "MockLabel",
                        text = params.text or "Mock Text",
                        show = function() print("[Mock] Label show") end,
                        hide = function() print("[Mock] Label hide") end,
                        isVisible = function() return true end,
                        setToolTip = function() print("[Mock] Set tooltip") end,
                        setClickFunction = function() print("[Mock] Set click function") end
                    }
                end
            }
        end,
        Container = function(params)
            print("[Mock] Geyser.Container:", params)
            return {
                new = function(self, params)
                    return {
                        name = params.name or "MockContainer",
                        show = function() print("[Mock] Container show") end,
                        hide = function() print("[Mock] Container hide") end,
                        isVisible = function() return true end
                    }
                end
            }
        end,
        HBox = function(params)
            print("[Mock] Geyser.HBox:", params)
            return {
                new = function(self, params)
                    return {
                        name = params.name or "MockHBox",
                        show = function() print("[Mock] HBox show") end,
                        hide = function() print("[Mock] HBox hide") end,
                        isVisible = function() return true end
                    }
                end
            }
        end
    }
end

-- Event system for decoupled communication
function SnD.raiseEvent(eventName, data)
    if raiseEvent then
        raiseEvent("SND." .. eventName, data)
    else
        print("[Mock] raiseEvent:", eventName, data)
    end
end

function SnD.registerHandler(eventName, handler)
    if registerAnonymousEventHandler then
        registerAnonymousEventHandler("SND." .. eventName, handler)
    else
        print("[Mock] registerAnonymousEventHandler:", eventName)
    end
end