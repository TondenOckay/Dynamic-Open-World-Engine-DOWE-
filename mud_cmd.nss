/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: mud_cmd
    
    PILLARS:
    3. Optimized Scalability (480-Player Phase-Staggering)
    4. Intelligent Population (MUD-Style Command Routing)
    
    SYSTEM NOTES:
    * THE BRAIN: Scans 'mud_cmd.2da' to find the correct handler script.
    * DECOUPLING: Keeps the quest/shop logic in separate memory spaces.
    * 12-Character filename compliant. 
    * Built for 2026 High-Readability Standard.
   ============================================================================
*/

// // 2DA REPLICA: mud_cmd.2da
// // Index | Command  | HandlerScript
// // 0     | //hail   | mud_quest
// // 1     | //buy    | mud_shop
// // 2     | //stats  | mud_bio

#include "save_mgr"

// --- PROTOTYPES ---
// Logic for handling the hand-off to secondary scripts.
void DOWE_CMD_ProcessCommand(object oPC, string sChat);

// ----------------------------------------------------------------------------
// PHASE 1: THE GATEKEEPER (Initialization & Validation)
// ----------------------------------------------------------------------------
void main()
{
    object oPC = OBJECT_SELF;
    // Capture the string stored by the OnPlayerChat event.
    string sChat = GetLocalString(oPC, "DOWE_CHAT_BUFFER");
    
    // TRIPLE-CHECK: Ensure the buffer isn't empty and the player is valid.
    if (sChat == "" || !GetIsPC(oPC)) return;

    // PHASING: We use a tiny delay (0.1s) to stagger the 2DA lookup.
    // This prevents the Chat Event frame from hitching if 10 players type at once.
    DelayCommand(0.1, DOWE_CMD_ProcessCommand(oPC, sChat));
}

// ----------------------------------------------------------------------------
// PHASE 2: THE REGISTRY SCAN (2DA Lookup)
// ----------------------------------------------------------------------------
void DOWE_CMD_ProcessCommand(object oPC, string sChat)
{
    int i = 0;
    string sCmd = Get2DAString("mud_cmd", "Command", i);
    int nFound = FALSE;

    // Loop through the 2DA registry to find the matching command.
    while (sCmd != "")
    {
        if (sChat == sCmd)
        {
            string sHandler = Get2DAString("mud_cmd", "HandlerScript", i);
            
            // TECHNICAL ANNOTATION: ExecuteScript is used here to clear the 
            // current script's memory (the 'Brain') before loading the next one.
            DOWE_MGR_Debug("MUD_CMD: Validated '" + sChat + "'. Routing to: " + sHandler, oPC);
            
            // PHASE 3: EXECUTION (Delegation to Subsystem)
            ExecuteScript(sHandler, oPC);
            nFound = TRUE;
            break;
        }
        i++;
        sCmd = Get2DAString("mud_cmd", "Command", i);
    }

    // ------------------------------------------------------------------------
    // PHASE 4: CLEANUP & ERROR HANDLING
    // ------------------------------------------------------------------------
    if (!nFound)
    {
        DOWE_MGR_Debug("MUD_CMD: Command '" + sChat + "' not recognized in 2DA.", oPC);
    }

    // Always clear the buffer after processing to prevent accidental double-triggers.
    DeleteLocalString(oPC, "DOWE_CHAT_BUFFER");
}
