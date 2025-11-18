

# **A Technical Blueprint for Porting the "Search and Destroy" Plugin to Mudlet**

## **I. Executive Analysis: Porting the "Search and Destroy" Module**

### **A. Project Definition and Core Objective**

This report provides a comprehensive technical blueprint for porting the "Search and Destroy" (S\&D) plugin for the Aardwolf MUD from its original MUSHclient implementation to the Mudlet client platform. The original plugin is a well-regarded, quality-of-life tool designed to streamline questing, campaigns, and target navigation within Aardwolf.1  
The primary objective of this analysis is twofold:

1. To deconstruct the functional and technical architecture of the original MUSHclient-based S\&D plugin, including its "Mapper Extender" component.3  
2. To provide a complete migration strategy and Product Requirements Document (PRD) framework for developing a new, native Mudlet module that replicates and enhances the original's functionality using the modern Mudlet API.

This document will serve as the foundational technical specification for the new Mudlet module, hereafter referred to as SND.Mudlet.

### **B. The Central Porting Challenge: Architectural Reimplementation**

A critical finding of this analysis is that this project cannot be a simple line-by-line code translation. It must be a complete architectural reimplementation. The MUSHclient and Mudlet platforms are built on fundamentally different design philosophies.

* **MUSHclient (The Original Environment):** The S\&D plugin is a product of its environment. MUSHclient plugins are typically XML-based 2 and often rely on a procedural scripting model. Data persistence is commonly handled via GetVariable and SetVariable functions 6 and a "save state" flag in the plugin's XML 8, which automatically serializes plugin-scoped variables. The UI paradigm, the "Miniwindow," is a simple text-output buffer.9  
* **Mudlet (The Target Environment):** Mudlet is an event-driven, modern client. It is built from the ground up on native Lua scripting, where all variables are native Lua tables and variables.11 It has no GetVariable function.11 Persistence is explicit and developer-controlled via a built-in SQLite database API (db:save()) 12 or file I/O (table.save).13 Its UI is a powerful, object-oriented framework named Geyser 14, and it possesses a rich, integrated Mapper API.15

Porting S\&D is not a matter of converting Send() to send() 16; it is a matter of re-designing the plugin's logic to be "Mudlet-native," embracing an event-driven model over a procedural one.

### **C. Key Insight: Replicating the "Mapper Extender" Logic**

The analysis of S\&D's various versions reveals that its most powerful and essential feature is not its combat aliases, but its tight integration with a "Mapper Extender".4 This extender provides the xrunto command, which solves a core usability problem in Aardwolf: MUD areas do not have a defined "start" room, which makes automated navigation by area name impossible for a generic mapper.  
The MUSHclient S\&D plugin's xrunto feature works by allowing the user to *personally define* a "start" room for an area. The plugin then saves this room ID and reuses it for all future xrunto \[areaname\] commands.2 This is the central logic that must be replicated.  
The MUSHclient plugin achieves this by storing this custom data in its proprietary "save state" file.8 The Mudlet port will achieve this far more elegantly by using the Mudlet mapper's built-in user data functions. The setAreaUserData function 15 allows a script to attach arbitrary key-value data directly to a map area. This is the one-to-one, native replacement for the "Mapper Extender's" core storage mechanism.

### **D. Strategic Recommendation: A Decoupled, Event-Driven Module**

To ensure maintainability, stability, and compatibility with other user scripts, SND.Mudlet must be built on a decoupled, event-driven architecture. The monolithic script structure common in older clients is a liability in the Mudlet environment.  
The new module must be designed as three separate, interoperable systems:

1. **Data Parsing:** A set of triggers responsible *only* for parsing campaign, quest, and where data from the MUD.  
2. **Mapper Logic:** A collection of functions (e.g., SND:xrunto) that interact with the Mudlet Mapper API.  
3. **GUI:** A Geyser-based window that displays data and provides a user interface.

These systems will not call each other directly. Instead, they will communicate using Mudlet's global event engine.13 For example, when a trigger parses a new target, it will not attempt to update the GUI. It will simply raiseEvent("SND.targetUpdated", {mob \= "orc", area \= "Midgaard"}).19 A separate GUI function, registered via registerAnonymousEventHandler 18, will listen for this event and update the Geyser window accordingly. This approach ensures stability and allows other user scripts to "listen in" and integrate with SND.Mudlet's functionality.

## **II. Deconstruction of the Original "Search and Destroy" MUSHclient Plugin**

### **A. Core Functional Breakdown**

Based on an aggregate analysis of the available plugin repositories 2, the S\&D plugin suite provides the following user-facing features:

1. **Target Acquisition and Management:**  
   * Automatically parses and tracks targets for Aardwolf Campaigns, Global Quests (GQs), and standard Quests.  
   * Displays these targets in a dedicated "Miniwindow" GUI, which often includes buttons for common commands.  
2. **Automated Navigation (xrunto):**  
   * This is the plugin's "killer feature," identified as the "Mapper Extender" logic.4  
   * It provides an xrunto \[areaname\] or xrt \[areaname\] command that navigates the user to their *personally chosen 'start' room* for that area.2 This logic is necessary because the default mapper cannot run to an abstract "area" that has no defined starting point.  
3. **Target Finding (quick-where):**  
   * Provides a qw \[mobname\] command.3  
   * This command links the MUD's where command to the MUSH mapper, finding known locations of a mob and providing a speedwalk hyperlink to that room.4  
4. **Combat & Utility Aliases:**  
   * auto-hunt: A toggleable function for automated hunting.3  
   * hunt-trick: A feature for managing combat targets, with "hot-swappable" targets.3  
   * awesome-kill (akill): A command that attacks the last mob targeted or entered.3  
   * quick-scan: Scans for the last mob the user hunted for.3  
5. **Maintenance:**  
   * xhelp: Displays all plugin-specific commands.  
   * snd update: An alias that allows the plugin to self-update.

### **B. Technical Architecture and Dependencies**

1. **Plugin Format:** The S\&D plugin is distributed as an XML file (e.g., Search\_and\_Destroy.xml, WinkleWinkle\_Search\_Destroy\_2.xml).2 This XML file is the standard MUSHclient plugin format, which acts as a container for triggers, aliases, timers, and the script code itself.5  
2. **Scripting Language:** MUSHclient is script-language-agnostic, supporting VBScript, JScript, and Lua, among others.22 While the Aardwolf client package has a powerful Lua-based mapper 26, there is a significant risk that portions of the S\&D plugin logic are written in **VBScript**.27 The presence of VBScript would make direct code translation impossible, as its logic and COM-based interactions 28 are not portable to Mudlet's Lua-only environment.  
3. **Core Dependency: MUSHclient Mapper:** The plugin is *entirely* dependent on the pre-existing Aardwolf MUSHclient mapper package.1 The S\&D plugin is an *enhancement* to this mapper, not a replacement for it.  
4. **Logic Augmentation: The "Mapper Extender":** The "Mapper Extender" component 4 is a logic layer that augments the main mapper. It does not perform its own pathfinding. Its xrunto command explicitly calls the underlying MUSH mapper's goto/walkto functions.4 Its primary purpose is to calculate and store the *target room* (the user's chosen "start room") which is then fed to the main mapper for execution. This logic also appears to rely on MUSHclient's "custom exits" (cexits) 26, a system for scripting navigation through complex, non-standard MUD exits (e.g., "open door; north; close door").

### **C. Data Persistence Model (MUSHclient)**

This is the most significant architectural difference that must be overcome.

1. **GetVariable/SetVariable:** MUSHclient scripts do not use native variables for persistent data in the same way Mudlet does. Instead, they often rely on global-like "world" variables, accessed procedurally via functions like GetVariable("myVar") and SetVariable("myVar", "value").6  
2. **Plugin "Save State":** Persistent data, such as the user-defined "start rooms" for the xrunto command, is saved between sessions by setting a save\_state="y" flag within the plugin's XML definition.6 When the world is closed, MUSHclient automatically serializes all plugin-scoped variables into a state file.

This model is the antithesis of Mudlet's. In Mudlet, there is no getVariable.11 All variables are native Lua variables. Persistence is *explicitly* managed by the developer. The developer must choose *what* to save (e.g., a Lua table), *how* to save it (e.g., as JSON using yajl.to\_string 19 or to a database 12), and *when* to save it (e.g., on sysExit or when a value changes). This paradigm shift is the single largest technical hurdle in the port.

### **D. UI Implementation ("Miniwindow")**

The S\&D plugin's GUI is implemented as a MUSHclient "Miniwindow".3 This is a separate, simple text-output window created with the WindowCreate function.10 The plugin's script typically uses triggers to define the start and end of MUD output (e.g., a campaign list) 10, captures this text, and then manually re-prints it to the Miniwindow. This is a simple, non-object-oriented, text-based UI. While functional, it is a legacy technology compared to Mudlet's UI framework. It is functionally equivalent to Mudlet's Geyser.MiniConsole 32 but lacks the power of the full Geyser framework.14

## **III. The Mudlet Target Architecture: A Porting Blueprint**

This section systematically maps each component from Section II to its modern Mudlet equivalent, providing a clear implementation path for SND.Mudlet.

### **A. Core Logic: From Procedural Scripting to Event-Driven Design**

1. **Namespace:** All plugin variables, functions, and data will be contained within a single, global Lua table, SND \= {}. This is a fundamental Mudlet best practice to prevent polluting the global namespace 33 and avoids accidental variable overwrites.  
2. **Event Handling:** The plugin's logic will be event-driven, using Mudlet's built-in event engine.13  
   * Instead of a single, monolithic script, functionality will be decoupled.  
   * **Example:** A trigger that matches a campaign target line will *only* parse the data and store it (see Section III.B). It will then emit a global event: raiseEvent("SND.targetUpdated", {mob \= "orc", area \= "Midgaard"}).19  
   * A separate function, SND.GUI:update(), will be registered at startup with registerAnonymousEventHandler("SND.targetUpdated", SND.GUI.update).18 This decouples the parsing logic from the display logic, making the code cleaner, more stable, and more extensible.  
3. **Triggers and Aliases:**  
   * MUSHclient's XML triggers 5 will be replaced with standard Mudlet triggers, created as part of the SND.Mudlet package.12  
   * Aliases like xrunto and qw will be created as permanent aliases in Mudlet. Their "Action" field will *not* contain code; it will simply call a function within the SND namespace, passing the regex matches. For example, the xrunto alias (pattern: ^xrunto (.+)$) will have its script set to SND:xrunto(matches).11  
   * Dynamic, short-term text-matching (e.g., "wait for the MUD's response to the where command") will be handled using tempTrigger or tempRegexTrigger 12, which are created on-the-fly and automatically destroy themselves after firing.

### **B. Proposed Data Model and Persistence**

1. **Replacing GetVariable:** All MUSHclient GetVariable 7 calls and procedural variable access will be replaced by direct, native access to keys within the SND Lua table (e.g., SND.config.autoHuntEnabled \= true).11  
2. **Persistence Strategy:** A hybrid persistence model is recommended to leverage the best of Mudlet's APIs.  
   * **For Plugin Configuration & Target Lists:** Use Mudlet's built-in SQLite database engine.12 At startup, the script will run SND.db \= db:create("SND.db", {...schema... }). This is vastly superior to flat-file (JSON) storage for structured data like target lists or user preferences.34 It is atomic, prevents data corruption from a bad write, and is the best practice for this type of data.17  
   * **For Map-Specific Data:** Use the Mudlet Mapper's User Data API.15 This is the critical component for replicating the "Mapper Extender" and is detailed in the next section.  
   * **For Export/Import (Optional):** The yajl.to\_string 13 and yajl.to\_value 13 functions should be used to create optional snd export and snd import commands. This allows users to back up their configuration or share their "start room" data with others.

### **C. Replicating the "Mapper Extender" with the Mudlet API**

This is the most critical component of the port. The MUSHclient "Mapper Extender" 4 will be replaced entirely by a few calls to the native Mudlet Mapper API.15

1. **The "Start Room" Solution:**  
   * The MUSHclient plugin's core problem—storing a "start room" ID for an area —is solved in Mudlet using setAreaUserData.  
   * A new alias, snd setstart, will be created.  
   * **Function SND:setStartRoom():**  
     1. Get the user's current roomID. This is typically available via GMCP (e.g., gmcp.Room.Info.num) or a custom user variable.  
     2. Get the areaID for that room using local areaID \= getRoomArea(roomID).17  
     3. Save this roomID as the "start room" for that area using setAreaUserData(areaID, "SND.startRoom", roomID).15 The key is namespaced to "SND" to prevent conflicts with other scripts.33  
     4. Provide user feedback: cecho(string.format("Start room for '%s' set to room %d.", getRoomAreaName(areaID), roomID)).17  
2. **The xrunto Implementation:**  
   * The xrunto \[areaname\] alias will call SND:xrunto(areaName).  
   * **Function SND:xrunto(areaName):**  
     1. Get the master list of all areas: local areas \= getAreaTable().17  
     2. Find the target areaID by iterating areas and performing a case-insensitive partial match on areaName.52  
     3. If areaID is found, retrieve the custom "start room" ID: local areaData \= getAllAreaUserData(areaID).15 local startRoomID \= areaData.  
     4. If startRoomID exists:  
        a. Get the player's current room: local currentRoom \= gmcp.Room.Info.num.  
        b. Calculate the path: local path, cost \= mmp.findRoute(currentRoom, startRoomID).15  
        c. If a path is found (cost \> 0), execute it: walkTo(path).15  
        d. If no path is found, cecho("Path to '...' blocked or does not exist.").  
     5. If startRoomID does *not* exist, cecho(string.format("No start room set for '%s'. Go there and type 'snd setstart'.", areaName)).  
3. **The qw (Quick-Where) Implementation:**  
   * The qw \[mobname\] alias will call SND:quickWhere(matches).  
   * This function will:  
     1. Send the where \[mobname\] command to the MUD.  
     2. Create a tempRegexTrigger 12 to capture the MUD's response (e.g., "The golden dragon is somewhere in: The Dragon's Lair.").  
     3. Parse the room name ("The Dragon's Lair") from the response.  
     4. Use the Mudlet mapper functions (e.g., iterating getAreaTable() and getRooms(areaID) or using searchRoomUserData() 13) to find the roomID that matches that room name.  
     5. Once the roomID is found, cecho a clickable prompt that, when clicked, will call mmp.findRoute() and walkTo() that room.  
4. **Handling Custom Exits (cexits):**  
   * The MUSHclient cexits 26 present a significant porting risk. Mudlet's walkTo() function relies on the map graph. If the user's map does not contain the "special exits" (e.g., "open door") 36 required to navigate, the walkTo() command will fail.  
   * **Solution:** SND.Mudlet must *not* attempt to solve this. It should rely on the user's *existing* Mudlet map. The plugin is a navigation *assistant*, not a *mapping script*.36 The documentation for SND.Mudlet must clearly state that it requires a "complete and correct" Mudlet map to function. If xrunto fails, it is a problem with the user's map, not the SND plugin.

### **D. GUI Replacement: From "Miniwindow" to Geyser**

The legacy MUSHclient "Miniwindow" 9 will be replaced with a modern, dockable, object-oriented Geyser window.14

1. **UI Structure:** The UI will be constructed using Geyser objects 14:  
   * **Main Window:** SND.GUI.Window \= Geyser.UserWindow:new({name \= "SND.Window",...}). Using Geyser.UserWindow allows the UI to be popped out of the main Mudlet window, moved to a second monitor, and resized.37  
   * **Layout:** A Geyser.VBox 14 will be placed inside the main window to organize elements vertically.  
   * **Title/Status:** A Geyser.Label 38 at the top: SND.GUI.Title \= Geyser.Label:new({name \= "SND.Title",...}, SND.GUI.Window).  
   * **Target List:** A Geyser.Container will hold a dynamically populated list of clickable Geyser.Labels. (Using labels is preferable to a MiniConsole as they can have individual click events, hover effects, and tooltips 14).  
   * **Buttons:** A Geyser.HBox at the bottom will contain clickable Geyser.Label elements 14 for "Hunt On/Off," "Update Targets," etc.  
2. **Styling:** The entire UI will be styled using setProfileStyleSheet().14 This allows the user to customize the look and feel (colors, fonts, borders) by editing a single stylesheet, without touching the plugin's Lua logic.  
3. **Interactivity:**  
   * The SND.GUI:update() function (called by the SND.targetUpdated event) will read the target list from SND.db and dynamically create, destroy, or update the Geyser.Labels in the target list container.  
   * Each target label's onClicked property will be set to a function that calls the appropriate navigation logic, e.g., function() SND:xrunto("Midgaard") end.  
   * Tooltips will be added using mylabel:setToolTip("Click to navigate").37

### **E. MUSHclient-to-Mudlet Technology Translation Table**

This table provides a high-level "cheat sheet" for the developer, mapping core MUSHclient concepts from the original plugin to their direct Mudlet equivalents.

| Concept / Feature | MUSHclient Implementation (The "Old Way") | Mudlet Implementation (The "New Way") | Reference |
| :---- | :---- | :---- | :---- |
| **Plugin Structure** | XML file with embedded scripts. | Mudlet Package (.mpackage) containing Lua scripts. | 2 |
| **Core Scripting** | Lua, VBScript, or JScript. | **Lua 5.1+** (Native) | 11 |
| **GUI / UI** | "Miniwindow" (WindowCreate). Simple text output. | **Geyser Framework** (Geyser.Container, Geyser.Label). | 9 |
| **Variable Access** | GetVariable("var"), SetVariable("var", val) | Native Lua: SND.var, SND.var \= val | 6 |
| **Data Persistence** | save\_state="y" flag in plugin XML. | Explicit I/O: **db:save()** (SQLite) or table.save() | 8 |
| **Logic Flow** | Procedural, linear script execution. | **Event-Driven** (raiseEvent, registerAnonymousEventHandler). | 18 |
| **Trigger Matching** | %1, %2 for captures. | matches, matches for captures. | 16 |
| **Sending Commands** | Send("command") (capital 'S'). | send("command") (lowercase 's'). | 16 |
| **Mapper Navigation** | mapper goto/walkto (via Extender). | mmp.findRoute() \+ walkTo(). | 4 |
| **Custom Map Data** | Stored in plugin's "save state" file. | **setAreaUserData(id, key, val)** / getAllAreaUserData(id). | 8 |
| **Dynamic Triggers** | N/A (Triggers are generally static). | **tempTrigger()**, tempRegexTrigger(). | 12 |

## **IV. Product Requirements Document (PRD) Framework**

This section translates the technical blueprint into a formal Product Requirements Document (PRD) for the SND.Mudlet module, defining the product's features, scope, and constraints.41

### **A. User Personas & Stories**

User stories place the end-user at the center of the design, articulating a feature's value from their perspective.44

* **User Persona 1: The Campaign Hunter**  
  * **Story 1 (Tracking):** "As a Campaign Hunter, I want a window that automatically lists my current campaign targets so that I can track my progress at a glance without typing 'campaign'." 47  
  * **Story 2 (Navigation):** "As a Campaign Hunter, I want to click a target's name in my list so that the client automatically starts navigating me to the start of that target's area." 46  
* **User Persona 2: The Explorer / Veteran**  
  * **Story 3 (Customization):** "As an Explorer, I want to permanently set a custom 'start room' for an area (e.g., at the zone entrance or a key junction) so that xrunto always takes me to my preferred location." 44  
  * **Story 4 (Efficiency):** "As a Veteran, I want to type xrt midgaard in the command line and have the client instantly start walking me to my 'start room' for Midgaard." 45  
* **User Persona 3: The Questor**  
  * **Story 5 (Finding):** "As a Questor, I want to type qw 'golden dragon' after getting a quest so that the plugin can find its location on my map and show me a clickable path to get there." 47

### **B. Functional Requirements (FRs)**

Functional requirements describe *what the system must do*.41  
**Module: Target Parsing & Storage**

* **FR-1.1:** The system **must** provide triggers that accurately parse Aardwolf's campaign target information.  
* **FR-1.2:** The system **must** provide triggers that accurately parse Aardwolf's global quest target information.  
* **FR-1.3:** The system **must** store the parsed list of targets in the Mudlet SQLite database using the db: API.12  
* **FR-1.4:** The system **must** load the target list from the database when the profile is loaded.

**Module: GUI (Geyser)**

* **FR-2.1:** The system **shall** display the current target list in a Geyser-based window.14  
* **FR-2.2:** This window **must** be toggleable (show/hide) via an alias (e.g., snd toggle).  
* **FR-2.3:** This window **must** be a Geyser.UserWindow 37, allowing it to be movable, dockable, resizable, and popped out of the client. Its position and state must be saved.  
* **FR-2.4:** Each target listed in the GUI **must** be clickable, triggering the navigation logic.

**Module: Mapper Integration (xrunto)**

* **FR-3.1:** The system **must** provide an alias (snd setstart) that saves the user's current room ID as the "start room" for the user's current area.  
* **FR-3.2:** This "start room" ID **must** be stored using setAreaUserData(areaID, "SND.startRoom", roomID).17  
* **FR-3.3:** The system **must** provide an alias (xrunto \<area name\>) that accepts a partial or full area name.  
* **FR-3.4:** The xrunto alias **must** look up the areaID from the area name, retrieve the SND.startRoom ID from getAllAreaUserData 15, and calculate a path using mmp.findRoute().15  
* **FR-3.5:** The xrunto alias **must** execute the path using walkTo().  
* **FR-3.6:** If no "start room" is set, the system **must** notify the user with a clear, actionable error message (e.g., "No start room set for 'Midgaard'. Go there and type 'snd setstart'.").

**Module: Quick-Where (qw)**

* **FR-4.1:** The system **must** provide an alias (qw \<mob name\>).  
* **FR-4.2:** This alias **must** send a where \<mob name\> command to the MUD.  
* **FR-4.3:** The system **must** use a temporary trigger (tempTrigger 12) to capture the MUD's response.  
* **FR-4.4:** The system **must** parse the room name from the response, find its roomID on the map, and provide a clickable cecho prompt to navigate to that room.

**Module: Combat Utilities**

* **FR-5.1:** The system **must** provide an alias (akill) that sends the kill command for the last-known target.

### **C. Non-Functional Requirements (NFRs)**

Non-functional requirements define *how the system should perform* and its quality attributes.48

* **NFR-1 (Performance):**  
  * **NFR-1.1:** All pathfinding calculations (mmp.findRoute()) **must** complete in under 500ms.  
  * **NFR-1.2:** GUI updates (showing/hiding the window, updating the target list) **must** appear instantaneous to the user (e.g., \< 100ms response time).  
* **NFR-2 (Compatibility & Data Integrity):**  
  * **NFR-2.1:** The plugin **must not** interfere with the Mudlet Generic Mapper script 36 or any other user-installed mapping scripts. It is an *augmentation*, not a *replacement*.  
  * **NFR-2.2:** The plugin **must not** modify or delete any core map data. All custom data **must** be stored *only* using the setAreaUserData / setRoomUserData API.15  
  * **NFR-2.3:** All database tables, user data keys, and global functions/variables **must** be namespaced with "SND" (e.g., SND.db, SND.startRoom) to prevent conflicts.33  
* **NFR-3 (Usability):**  
  * **NFR-3.1:** The Geyser UI **must** be intuitive and follow the design language of modern Mudlet UIs 14, including support for user-defined stylesheets.  
  * **NFR-3.2:** All plugin commands **must** provide clear cecho feedback (e.g., "Start room for Midgaard set.").  
  * **NFR-3.3:** The plugin **must** provide a help function (snd help) that explains all aliases and their usage.  
* **NFR-4 (Modularity & Extensibility):**  
  * **NFR-4.1:** The plugin **must** raise custom events for key actions (e.g., SND.targetUpdated, SND.navStarted, SND.navCompleted) to allow other user scripts to integrate with it.13

## **V. Implementation Strategy and Risk Analysis**

### **A. Phased Development Plan**

A phased approach is recommended to tackle high-value features first and ensure the core logic is sound before building the UI.

* **Phase 1: Core Mapper Logic (The "Mapper Extender")**  
  1. **Objective:** Replicate the xrunto functionality. This is the highest-value, highest-priority feature.  
  2. **Tasks:**  
     * Create the SND \= {} namespace table.  
     * Implement the SND:setStartRoom() function using getRoomArea and setAreaUserData.17  
     * Create the snd setstart alias to call this function.  
     * Implement the SND:xrunto() function using getAreaTable, getAllAreaUserData, mmp.findRoute, and walkTo().15  
     * Create the xrunto and xrt aliases.  
  3. **Deliverable:** A functioning xrunto system that allows a user to set and navigate to custom "start rooms." This is the Minimum Viable Product (MVP).  
* **Phase 2: Data Parsing & Storage**  
  1. **Objective:** Get campaign, quest, and where data into the system.  
  2. **Tasks:**  
     * Create the SQLite database schema (db:create()) for persisting targets.12  
     * Build triggers to parse Aardwolf's campaign/quest text.  
     * Implement functions to SND.db:add() and SND.db:remove() targets, and a SND.db:load() function for profile startup.  
     * Have triggers call these functions and then raiseEvent("SND.targetUpdated").19  
     * Implement the SND:quickWhere() logic with its tempRegexTrigger.12  
  3. **Deliverable:** A system that silently parses and persists all targets and a functioning qw alias.  
* **Phase 3: GUI Development (Geyser)**  
  1. **Objective:** Create the user-facing window.  
  2. **Tasks:**  
     * Build the Geyser UI layout (UserWindow, VBox, HBox, Labels) as defined in Section III.D.14  
     * Create the SND.GUI:update() function to read from SND.db and populate the window's target list.  
     * Register SND.GUI:update() to the SND.targetUpdated event.18  
     * Make the target labels in the GUI clickable, having them call SND:xrunto() or SND:quickWhere().  
     * Add combat alias buttons (akill, auto-hunt toggle).  
  3. **Deliverable:** A complete, interactive, and user-friendly SND.Mudlet module that ties all phases together.

### **B. Key Porting Risks and Mitigation**

1. **Risk 1: Original S\&D Logic is in VBScript**  
   * **Description:** The original MUSHclient plugin may use VBScript.24 VBScript is architecturally dissimilar to Lua, making code translation impossible. Its logic is heavily tied to Windows COM objects.27  
   * **Mitigation:** **Do not attempt to read or translate the original script code.** The port must be a "black box" reimplementation. Use the functional analysis 3 and the FRs (Section IV) to write a new, clean Lua implementation from scratch. The original code is irrelevant; its *behavior* is all that matters.  
2. **Risk 2: MUSHclient Custom Exits (cexits)**  
   * **Description:** The original xrunto 4 may rely on a MUSHclient mapper that has complex, scripted cexits 26 to navigate (e.g., "open door; n"). The Mudlet walkTo() function will fail if the user's map does not have equivalent "special exits" 36 defined.  
   * **Mitigation:** **Scoped responsibility.** The SND.Mudlet plugin's responsibility must *end* at the walkTo() command. It is a *navigation assistant*, not a *mapping script*.36 The plugin's documentation and help files must clearly state that it requires a complete and properly configured Mudlet map to function. User-facing errors must report "No path found," not a script error.  
3. **Risk 3: Data Model Paradigm Shift**  
   * **Description:** A developer familiar with MUSHclient's GetVariable 7 and "save state" 8 model may try to replicate this anti-pattern in Mudlet, leading to a poorly designed, non-native script.  
   * **Mitigation:** Adhere strictly to the target architecture. All data must be stored in the SND namespaced table.33 All persistence must be *explicitly* handled via db:save() 12 for config/targets and setAreaUserData() 17 for map data. This is non-negotiable for a high-quality Mudlet module.  
4. **Risk 4: User Map Incompleteness**  
   * **Description:** The qw (quick-where) feature relies on the plugin being able to find a room ID from a room name. The xrunto feature relies on the areaName being in the map. If the user's map is incomplete, these features will fail.  
   * **Mitigation:** Implement robust, user-friendly error handling.  
     * If SND:xrunto(areaName) cannot find areaName in getAreaTable() 17, it must cecho a clear error ("Area '...' not found in your map.").  
     * If SND:quickWhere() cannot find a roomID for a parsed room name, it must cecho ("Room '...' not found in your map.").

#### **Works cited**

1. Sn D — AardWiki \- Aardwolf MUD, accessed November 17, 2025, [https://www.aardwolf.com/wiki/index.php/Help/SnD](https://www.aardwolf.com/wiki/index.php/Help/SnD)  
2. AardCrowley/Search-and-Destroy: Safe, Legal Search and ... \- GitHub, accessed November 17, 2025, [https://github.com/AardCrowley/Search-and-Destroy](https://github.com/AardCrowley/Search-and-Destroy)  
3. Google Code Archive \- Google Code, accessed November 17, 2025, [https://code.google.com/archive/p/aardwolf-scriptalicious/](https://code.google.com/archive/p/aardwolf-scriptalicious/)  
4. aardwolf-lunk/WinkleWinkle-Search-And-Destroy-Triple ... \- GitHub, accessed November 17, 2025, [https://github.com/aardwolf-lunk/WinkleWinkle-Search-And-Destroy-Triple-Pack-Up-To-Date](https://github.com/aardwolf-lunk/WinkleWinkle-Search-And-Destroy-Triple-Pack-Up-To-Date)  
5. MUSHclient : General : Importing triggers \- Gammon Forum, accessed November 17, 2025, [https://www.gammon.com.au/forum/bbshowpost.php?bbsubject\_id=5361](https://www.gammon.com.au/forum/bbshowpost.php?bbsubject_id=5361)  
6. Variables \- MUSHclient documentation \- Gammon Software Solutions, accessed November 17, 2025, [https://www.gammon.com.au/scripts/doc.php?general=variables](https://www.gammon.com.au/scripts/doc.php?general=variables)  
7. MUSHclient script function: GetVariable \- Gammon Software Solutions, accessed November 17, 2025, [https://www.mushclient.com/scripts/function.php?name=GetVariable](https://www.mushclient.com/scripts/function.php?name=GetVariable)  
8. MUSHclient : Plugins : Plugin with saved states \- Gammon Forum, accessed November 17, 2025, [https://gammon.com.au/forum/bbshowpost.php?bbsubject\_id=8849](https://gammon.com.au/forum/bbshowpost.php?bbsubject_id=8849)  
9. MUSHclient : Miniwindows : Help with inventory miniwindow please \- Gammon Forum, accessed November 17, 2025, [https://mushclient.com/forum/bbshowpost.php?bbsubject\_id=10190](https://mushclient.com/forum/bbshowpost.php?bbsubject_id=10190)  
10. MUSHclient : General : Making a miniwindow moveable. \- Gammon Forum, accessed November 17, 2025, [https://www.gammon.com.au/forum/?id=11873](https://www.gammon.com.au/forum/?id=11873)  
11. Manual:Using Variables in Mudlet, accessed November 17, 2025, [https://wiki.mudlet.org/w/Manual:Using\_Variables\_in\_Mudlet](https://wiki.mudlet.org/w/Manual:Using_Variables_in_Mudlet)  
12. Manual:Scripting \- Mudlet Wiki, accessed November 17, 2025, [https://wiki.mudlet.org/w/manual:scripting](https://wiki.mudlet.org/w/manual:scripting)  
13. Manual:Lua Functions \- Mudlet Wiki, accessed November 17, 2025, [https://wiki.mudlet.org/w/Manual:Lua\_Functions](https://wiki.mudlet.org/w/Manual:Lua_Functions)  
14. Manual:Geyser \- Mudlet Wiki, accessed November 17, 2025, [https://wiki.mudlet.org/w/manual:geyser](https://wiki.mudlet.org/w/manual:geyser)  
15. Manual:Mapper Functions \- Mudlet Wiki, accessed November 17, 2025, [https://wiki.mudlet.org/w/Manual:Mapper\_Functions](https://wiki.mudlet.org/w/Manual:Mapper_Functions)  
16. Manual:Migrating \- Mudlet Wiki, accessed November 17, 2025, [https://wiki.mudlet.org/w/manual:migrating](https://wiki.mudlet.org/w/manual:migrating)  
17. Technical Manual/en \- Mudlet Wiki, accessed November 17, 2025, [https://wiki.mudlet.org/w/Manual:Technical\_Manual/en](https://wiki.mudlet.org/w/Manual:Technical_Manual/en)  
18. Manual:Event Engine \- Mudlet Wiki, accessed November 17, 2025, [https://wiki.mudlet.org/w/Manual:Event\_Engine](https://wiki.mudlet.org/w/Manual:Event_Engine)  
19. Technical Manual \- Mudlet Wiki, accessed November 17, 2025, [https://wiki.mudlet.org/w/Manual:Technical\_Manual](https://wiki.mudlet.org/w/Manual:Technical_Manual)  
20. Mudlet 3.5.0 – new website, toggle search, copy/paste triggers and aliases \- SourceForge, accessed November 17, 2025, [https://sourceforge.net/p/mudlet/news/2017/10/mudlet-350--new-website-toggle-search-copypaste-triggers-and-aliases/](https://sourceforge.net/p/mudlet/news/2017/10/mudlet-350--new-website-toggle-search-copypaste-triggers-and-aliases/)  
21. Aardwolf Mush Client Plugins and VI support \- Google Code, accessed November 17, 2025, [https://code.google.com/archive/p/aardwolf-scriptalicious](https://code.google.com/archive/p/aardwolf-scriptalicious)  
22. Scripting \- MUSHclient documentation \- Gammon Software Solutions, accessed November 17, 2025, [https://www.gammon.com.au/scripts/doc.php?general=scripting](https://www.gammon.com.au/scripts/doc.php?general=scripting)  
23. MUSHclient : General : Plugin execute a script on main lua file \- Gammon Forum, accessed November 17, 2025, [https://www.gammon.com.au/forum/bbshowpost.php?bbsubject\_id=14358](https://www.gammon.com.au/forum/bbshowpost.php?bbsubject_id=14358)  
24. MUSHclient : General : Languages \- Gammon Forum, accessed November 17, 2025, [https://gammon.com.au/forum/?id=4862](https://gammon.com.au/forum/?id=4862)  
25. MUSHclient : General : Autologin: Built-in vs. Triggers \- Gammon Forum, accessed November 17, 2025, [https://www.gammon.com.au/forum/bbshowpost.php?bbsubject\_id=5166](https://www.gammon.com.au/forum/bbshowpost.php?bbsubject_id=5166)  
26. MUSHclient : Tips and tricks : Aardwolf Mapper Tutorial (by Lunk) 2/2 \- Gammon Forum, accessed November 17, 2025, [https://www.gammon.com.au/forum/?id=12930](https://www.gammon.com.au/forum/?id=12930)  
27. MUSHclient : VBscript : Comprehensive Mud Mapping \- Gammon Forum, accessed November 17, 2025, [https://mushclient.com/forum/?id=10800\&reply=8](https://mushclient.com/forum/?id=10800&reply=8)  
28. MUSHclient : Development : Porting: Linux Native? MUSHclient \- Gammon Forum, accessed November 17, 2025, [https://www.gammon.com.au/forum/?id=10614](https://www.gammon.com.au/forum/?id=10614)  
29. MUSHclient : Suggestions : Variables in scripts \- Gammon Forum, accessed November 17, 2025, [https://www.gammon.com.au/forum/bbshowpost.php?bbsubject\_id=15248](https://www.gammon.com.au/forum/bbshowpost.php?bbsubject_id=15248)  
30. Gammon Forum : MUSHclient : Suggestions : Plugin Saving behavior, accessed November 17, 2025, [https://www.mushclient.com/forum/bbshowpost.php?bbsubject\_id=10472\&page=1](https://www.mushclient.com/forum/bbshowpost.php?bbsubject_id=10472&page=1)  
31. MUSHclient Mini-window Help Request : r/MUD \- Reddit, accessed November 17, 2025, [https://www.reddit.com/r/MUD/comments/12oczx4/mushclient\_miniwindow\_help\_request/](https://www.reddit.com/r/MUD/comments/12oczx4/mushclient_miniwindow_help_request/)  
32. Manual:UI Functions \- Mudlet Wiki, accessed November 17, 2025, [https://wiki.mudlet.org/w/Manual:UI\_Functions](https://wiki.mudlet.org/w/Manual:UI_Functions)  
33. Manual:Best Practices \- Mudlet Wiki, accessed November 17, 2025, [https://wiki.mudlet.org/w/Manual:Best\_Practices](https://wiki.mudlet.org/w/Manual:Best_Practices)  
34. Storing JSON in database vs. having a new column for each key \- Stack Overflow, accessed November 17, 2025, [https://stackoverflow.com/questions/15367696/storing-json-in-database-vs-having-a-new-column-for-each-key](https://stackoverflow.com/questions/15367696/storing-json-in-database-vs-having-a-new-column-for-each-key)  
35. When should I consider a database instead of storing a single JSON file? : r/node \- Reddit, accessed November 17, 2025, [https://www.reddit.com/r/node/comments/dfmrlj/when\_should\_i\_consider\_a\_database\_instead\_of/](https://www.reddit.com/r/node/comments/dfmrlj/when_should_i_consider_a_database_instead_of/)  
36. Manual:Mapper \- Mudlet Wiki, accessed November 17, 2025, [https://wiki.mudlet.org/w/Manual:Mapper](https://wiki.mudlet.org/w/Manual:Mapper)  
37. 4.6 – Geyser, Geyser, Geyser\! \- Mudlet, accessed November 17, 2025, [https://www.mudlet.org/2020/03/4-6-geyser-geyser-geyser/](https://www.mudlet.org/2020/03/4-6-geyser-geyser-geyser/)  
38. Module Geyser.Label \- Mudlet, accessed November 17, 2025, [https://www.mudlet.org/geyser/files/geyser/Geyser.Label.html](https://www.mudlet.org/geyser/files/geyser/Geyser.Label.html)  
39. Manual:Technical Manual TOC \- Mudlet Wiki, accessed November 17, 2025, [https://wiki.mudlet.org/w/Manual:Technical\_Manual\_TOC](https://wiki.mudlet.org/w/Manual:Technical_Manual_TOC)  
40. MUSHclient : General : Custom events \- Gammon Forum, accessed November 17, 2025, [https://gammon.com.au/forum/?id=11863\&reply=1](https://gammon.com.au/forum/?id=11863&reply=1)  
41. A Guide to Functional Requirements (with Examples) \- Nuclino, accessed November 17, 2025, [https://www.nuclino.com/articles/functional-requirements](https://www.nuclino.com/articles/functional-requirements)  
42. How to Write a Product Requirements Document (PRD) | Discovery Phase of Software Development \- Fulcrum Rocks, accessed November 17, 2025, [https://fulcrum.rocks/blog/product-requirements-document](https://fulcrum.rocks/blog/product-requirements-document)  
43. How to write a product requirements document : r/ProductManagement \- Reddit, accessed November 17, 2025, [https://www.reddit.com/r/ProductManagement/comments/nh700w/how\_to\_write\_a\_product\_requirements\_document/](https://www.reddit.com/r/ProductManagement/comments/nh700w/how_to_write_a_product_requirements_document/)  
44. User stories with examples and a template \- Atlassian, accessed November 17, 2025, [https://www.atlassian.com/agile/project-management/user-stories](https://www.atlassian.com/agile/project-management/user-stories)  
45. User stories — examples and templates \- Adobe for Business, accessed November 17, 2025, [https://business.adobe.com/blog/basics/user-story-examples](https://business.adobe.com/blog/basics/user-story-examples)  
46. 20 User story examples and best practices \- Justinmind, accessed November 17, 2025, [https://www.justinmind.com/blog/examples-user-story-best-practices/](https://www.justinmind.com/blog/examples-user-story-best-practices/)  
47. 10 Powerful User Stories Examples to Boost Your Product | Miro, accessed November 17, 2025, [https://miro.com/product-development/user-story-examples/](https://miro.com/product-development/user-story-examples/)  
48. Nonfunctional Requirements: Examples, Types and Approaches \- AltexSoft, accessed November 17, 2025, [https://www.altexsoft.com/blog/non-functional-requirements/](https://www.altexsoft.com/blog/non-functional-requirements/)  
49. Writing Non-Functional Requirements in 6 Steps, accessed November 17, 2025, [https://www.modernrequirements.com/blogs/what-are-non-functional-requirements-and-how-to-build-them/](https://www.modernrequirements.com/blogs/what-are-non-functional-requirements-and-how-to-build-them/)  
50. Non functional requirements and functional requirement example \- Stack Overflow, accessed November 17, 2025, [https://stackoverflow.com/questions/62546088/non-functional-requirements-and-functional-requirement-example](https://stackoverflow.com/questions/62546088/non-functional-requirements-and-functional-requirement-example)  
51. Non-Functional Requirements: Tips, Tools, and Examples \- Perforce Software, accessed November 17, 2025, [https://www.perforce.com/blog/alm/what-are-non-functional-requirements-examples](https://www.perforce.com/blog/alm/what-are-non-functional-requirements-examples)  
52. mudlet-mapper.xml \- GitHub, accessed November 17, 2025, [https://raw.githubusercontent.com/IRE-Mudlet-Mapping/ire-mapping-script/f8cbf1207d19f1f8e75a8c264ed7b4669c89cc40/mudlet-mapper.xml](https://raw.githubusercontent.com/IRE-Mudlet-Mapping/ire-mapping-script/f8cbf1207d19f1f8e75a8c264ed7b4669c89cc40/mudlet-mapper.xml)