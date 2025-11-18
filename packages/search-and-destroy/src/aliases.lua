-- snd setstart - Mark current room as area start
permAlias("snd setstart", [[SnD.Mapper.setStartRoom()]])

-- xrunto/xrt - Navigate to area start room  
permAlias("^xrunto (.+)$", [[SnD.Mapper.xrunto(matches[2])]])
permAlias("^xrt (.+)$", [[SnD.Mapper.xrunto(matches[2])]])

-- Campaign command alias
permAlias("^xcp$", [[SnD.Campaign.process("")]])
permAlias("^xcp (.+)$", [[SnD.Campaign.process(matches[2])]])

-- Quick where alias
permAlias("^qw (.*)$", [[SnD.QuickWhere.execute(matches[2])]])

-- Declare permAlias function
if not permAlias then
    function permAlias(pattern, command)
        if permAlias then
            permAlias(pattern, command)
        else
            print("[Mock] permAlias:", pattern, command)
        end
    end
end