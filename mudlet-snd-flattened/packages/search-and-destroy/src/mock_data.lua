-- Mock Data Framework
SnD.Mock = SnD.Mock or {}

-- Enable mock mode for development
function SnD.Mock.enable()
    _G.gmcp = _G.gmcp or {}
    _G.gmcp.room = _G.gmcp.room or {}
    _G.gmcp.comm = _G.gmcp.comm or {}
    
    -- Override GMCP functions
    function registerAnonymousEventHandler(event, handler)
        if registerAnonymousEventHandler then
            registerAnonymousEventHandler(event, handler)
        else
            print("[Mock] registerAnonymousEventHandler:", event)
        end
    end
    
    function setAreaUserData(areaID, key, value)
        if setAreaUserData then
            setAreaUserData(areaID, key, value)
        else
            print("[Mock] setAreaUserData:", areaID, key, value)
        end
    end
    
    function getAllAreaUserData(areaID)
        if getAllAreaUserData then
            getAllAreaUserData(areaID)
        else
            print("[Mock] getAllAreaUserData:", areaID)
            return {}
        end
    end
    
    function getRoomArea(roomID)
        if getRoomArea then
            getRoomArea(roomID)
        else
            print("[Mock] getRoomArea:", roomID)
            return 1
        end
    end
    
    function getRoomAreaName(areaID)
        if getRoomAreaName then
            getRoomAreaName(areaID)
        else
            print("[Mock] getRoomAreaName:", areaID)
            return "Mock Area"
        end
    end
    
    function getAreaTable()
        if getAreaTable then
            getAreaTable()
        else
            print("[Mock] getAreaTable")
            return {}
        end
    end
    
    if not cecho then
        function cecho(text)
            print("[Mock] cecho:", text)
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
end