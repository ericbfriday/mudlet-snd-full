# WinkleWinkle-Search-And-Destroy-Triple-Pack-Up-To-Date
All credit goes to WinkleWinkle

ww help in game to list this help :

SEARCH AND DESTROY USAGE:

===== SHOW THIS HELP ===============>
>   search help
        - shows only this help
>   ww help
        - all winklewinkle(tm) plugins show help
  
===== HUNT TRICK ===============>
>   ht citizen       
        - will hunt all citizens upwards from 1.citizen
>   ht 3 citizen     
        - will hunt all citizens starting at 3.citizen
>   ht abort         
        - will abort a currently running hunt trick script
>   ht
        - Typing just this will hunt for the last mob you performed "ht" or 
  "qw" for


>   ht find 
  - try and hunt the last mob you "couldn't hunt for some reason" to
  confirm if it is in your current room or not
  
===== AUTO HUNT ================>
>   ah citizen       
        - will auto-hunt and move towards a mob until mob is found, you get 
  in a fight, or you abort the auto-hunt
>   ah 3.citizen     
        - will auto-hunt 3.citizen
>   ah abort         
        - will abort a currently running auto hunt script

===== AWESOME KILL=================>
>   ak  - Typing just this will attack the last mob you performed "ht" or "qw" 
        for.  No more typos in scans!

NOTE:  If you want a custom kill action.. make an alias that will trigger on 
        k *
       This will receive the ak's kill command

Quick Scan
===== QUICK SCAN ===============>
>   qs               
        - Typing just this will scan for the last mob you performed "ht" or 
  "qw" for

===== QUICK WHERE ==============>
>   qw lich          
        - This will return a room name and a speedwalk hyperlink to the room
  the lich is in (may have multiple rooms in list)
>   qw               
        - Typing just this will "where" for the last mob you performed "ht" or 
  "qw" for
  




MAPPER EXTENDER USAGE:

===== SHOW THIS HELP =============>
>    extender help
        - shows only this help
>    ww help
        - all winklewinkle(tm) plugins show help

===== RUNNING ====================>
>   xrunto [areaname]
        - Runs you via mapper goto/walkto to the first room you discovered in that area
  
>   xrt [areaname]
        - Same as "xrunto"

>   xset mark
        - Sets the current room you are in to be the "first" room of that area 

>   xset speed
        - Toggles the use of mapper goto/walkto for all movement commands
  
>   xset speed <walk|run>
        - changes the use of mapper goto/walkto for all movement commands

>   xmapper move <roomid>  
        - uses set movement speed to move to the specified room id

>   xmapper move <roomid> <walk|run>
        - uses a temporary movement speed to move to the specified room id
  
===== SEARCHING ==================>
>   xm [roomname] 
        - Lists and numbers rooms that match the [roomname] exactly, and then partial matches in the current area
  
>   xmall [roomname]
        - Lists and numbers rooms that match the [roomname] exactly, and then partial matches in all areas
  
===== ROOMS ======================>
>   go [index]
        - Will run you with mapper goto/walkto to the first room in a numbered room list
  
>   go
        - The same as typing "go 1"
  
>   nx
        - Will run you to the next numbered room, "go" then "nx" would be the same as typing "go 1" then "go 2"
  
===== CAMPAIGNS ==================>
>   xcp 
        - Lists all active campaign mobs in a numbered list (see xcp [index])
  
>   xcp [index]
        - Area CP runs you to the area of that CP item and does a Quick-Where on your mob. Type "go [index]" after this to go to the first known room found (if any)
        - Room CP lists all known rooms that exactly match your CP room name. Type "go [index]" to run to the right room (if any).

===== NOTES ======================>
>   roomnote
        - Lists all mapper notes for the current room (if any).
  
>   roomnote area
        - Lists all mapper notes for the current area (if any). Useful for mazes

===== SETTINGS ======================>
>   xset pk
        - Toggles the display of PK flag in room searches

>   xset vidblain
        - Toggles a hack that will allow you to speedwalk to vidblain areas if you do not have a portal to use
  
> xset reset gui
  - Will reset the X, Y and Z position of the Extender GUI

===== TO CREATE A CEXIT / MAP A PORTAL ==========>

http://code.google.com/p/aardwolf-scriptalicious/wiki/MapperHelp
