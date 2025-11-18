-- Test basic Mudlet functions
function testMudletFunctions()
    cecho("<cyan>Testing Mudlet function availability...")
    
    -- Test basic functions
    if type(raiseEvent) == "function" then
        cecho("<green>✓ raiseEvent available")
    else
        cecho("<red>✗ raiseEvent NOT available")
    end
    
    if type(registerAnonymousEventHandler) == "function" then
        cecho("<green>✓ registerAnonymousEventHandler available")
    else
        cecho("<red>✗ registerAnonymousEventHandler NOT available")
    end
    
    if type(setAreaUserData) == "function" then
        cecho("<green>✓ setAreaUserData available")
    else
        cecho("<red>✗ setAreaUserData NOT available")
    end
    
    if type(getAllAreaUserData) == "function" then
        cecho("<green>✓ getAllAreaUserData available")
    else
        cecho("<red>✗ getAllAreaUserData NOT available")
    end
    
    if type(getRoomArea) == "function" then
        cecho("<green>✓ getRoomArea available")
    else
        cecho("<red>✗ getRoomArea NOT available")
    end
    
    if type(getRoomAreaName) == "function" then
        cecho("<green>✓ getRoomAreaName available")
    else
        cecho("<red>✗ getRoomAreaName NOT available")
    end
    
    if type(getAreaTable) == "function" then
        cecho("<green>✓ getAreaTable available")
    else
        cecho("<red>✗ getAreaTable NOT available")
    end
    
    if type(mmp) == "table" and mmp.findRoute then
        cecho("<green>✓ mmp.findRoute available")
    else
        cecho("<red>✗ mmp.findRoute NOT available")
    end
    
    if type(walkTo) == "function" then
        cecho("<green>✓ walkTo available")
    else
        cecho("<red>✗ walkTo NOT available")
    end
    
    if type(cecho) == "function" then
        cecho("<green>✓ cecho available")
    else
        cecho("<red>✗ cecho NOT available")
    end
end

-- Run test
testMudletFunctions()