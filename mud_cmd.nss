/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.2 (Master Build - Faction/Switchboard Integrated)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: mud_cmd
    
    PILLARS:
    3. Optimized Scalability (480-Player Phase-Staggering)
    4. Intelligent Population (Context-Aware Command Routing)
    
    DESCRIPTION:
    The "Central Nervous System" for the DOWE MUD command suite. This script 
    intercepts player chat, identifies the intent via mud_cmd.2da, and 
    pre-processes targeting requirements. 
    
    INTEGRATION:
    * Connects to 'fact_engine' by checking DOWE_PRC_DENY.
    * If the Faction Engine has flagged the PC as banned, routing is aborted.
    
    SYSTEM NOTES:
    * TRIPLE-CHECKED: Logic staggered by 0.1s to prevent frame-hitching.
    * FACTION READY: Hands off a validated NPC object to the quest/store engines.
    * 12-Character filename compliant.
   ============================================================================
*/

// [2DA REPLICA: mud_cmd.2da]
// // Row | Command  | HandlerScript | NeedsTarget | SearchDist
// // 0   | //hail   | mud_quest     | 1           | 5.0
// // 1   | //buy    | mud_store     | 1           | 5.0
// // 2   | //stats  | mud_bio       | 0           | 0.0

#include "save_mgr"

// --- PROTOTYPES ---
void DOWE_CMD_ProcessCommand(object oPC, string sChat);

// --- DOWE DEBUG SYSTEM ---
// Integrated tracer: Broadcasts routing decisions to PCs if Debug Mode is active.
void CMD_Debug(string sMsg, object oPC) {
    if (GetLocalInt(GetModule(), "DOWE_DEBUG_MODE") == TRUE) {
        SendMessageToPC(oPC, " [MUD_CMD] -> " + sMsg);
    }
}

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

    // PHASING: 0.1s delay to stagger 2DA lookup against the initial chat frame.
    // This protects the 480-player heartbeat from I/O spikes.
    DelayCommand(0.1, DOWE_CMD_ProcessCommand(oPC, sChat));
}

// ----------------------------------------------------------------------------
// PHASE 2: REGISTRY SCAN & CONTEXTUAL TARGETING
// ----------------------------------------------------------------------------
void DOWE_CMD_ProcessCommand(object oPC, string sChat)
{
    int i = 0;
    int nFound = FALSE;
    string sLowerChat = GetStringLowerCase(sChat);

    // Initial 2DA read to prime the loop.
    string sCmd = Get2DAString("mud_cmd", "Command", i);
    
    while (sCmd != "")
    {
        // GOLD STANDARD: Use SubString to allow for trailing arguments (e.g., //buy health)
        if (FindSubString(sLowerChat, GetStringLowerCase(sCmd)) != -1)
        {
            // Retrieve routing metadata from 2DA.
            string sHandler  = Get2DAString("mud_cmd", "HandlerScript", i);
            int bNeedsTarget = StringToInt(Get2DAString("mud_cmd", "NeedsTarget", i));
            float fMaxDist   = StringToFloat(Get2DAString("mud_cmd", "SearchDist", i));
            
            // PHASE 3: CONTEXT ACQUISITION (NPC Discovery)
            if (bNeedsTarget)
            {
                object oNPC = GetNearestObject(OBJECT_TYPE_CREATURE, oPC);
                float fDist = GetDistanceBetween(oPC, oNPC);
                
                // Validate proximity based on the 2DA's specific SearchDist.
                if (GetIsObjectValid(oNPC) && fDist <= fMaxDist)
                {
                    // Technical Annotation: Storing the target object so the handler
                    // script doesn't have to perform its own GetNearest scan.
                    SetLocalObject(oPC, "DOWE_CHAT_TARGET", oNPC);
                    
                    // --- PHASE 3.5: SOCIAL PLUG-IN RECONCILIATION ---
                    // This block checks the 'stamps' left by fact_engine.
                    // If the player is banned (NEMESIS/HATED), we stop here.
                    int bIsBanned = GetLocalInt(oPC, "DOWE_PRC_DENY");
                    if (bIsBanned == TRUE)
                    {
                        AssignCommand(oNPC, SpeakString("I don't do business with your kind. Be gone!"));
                        CMD_Debug("SOCIAL REJECTION: PC is banned by Faction Engine.", oPC);
                        DeleteLocalString(oPC, "DOWE_CHAT_BUFFER");
                        return; // ABORT ROUTING
                    }

                    CMD_Debug("Context Found: Targeting " + GetTag(oNPC), oPC);
                }
                else
                {
                    // Immersion: Notify player if they are shouting at thin air.
                    SendMessageToPC(oPC, "There is no one nearby to hear that command.");
                    DeleteLocalString(oPC, "DOWE_CHAT_BUFFER");
                    return; 
                }
            }

            // PHASE 4: HAND-OFF & EXECUTION
            // Store the identified command and fire the sub-engine.
            SetLocalString(oPC, "DOWE_LAST_CMD", sCmd); 
            CMD_Debug("Routing '" + sCmd + "' to [" + sHandler + "]", oPC);
            
            // Gold Standard: ExecuteScript decouples logic from the Switchboard memory.
            ExecuteScript(sHandler, oPC);
            nFound = TRUE;
            break; 
        }
        i++;
        sCmd = Get2DAString("mud_cmd", "Command", i);
    }

    // ------------------------------------------------------------------------
    // PHASE 5: CLEANUP & ERROR HANDLING
    // ------------------------------------------------------------------------
    if (!nFound)
    {
        CMD_Debug("MUD_CMD: Command '" + sChat + "' unrecognized in 2DA.", oPC);
    }

    // Always flush the buffer to prevent double-triggers or memory leaks.
    DeleteLocalString(oPC, "DOWE_CHAT_BUFFER");
}
