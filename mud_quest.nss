/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: mud_quest
    
    PILLARS:
    3. Optimized Scalability (Phase-Staggered 2DA Scans)
    4. Intelligent Population (Dynamic Keyword/Variable Logic)
    
    SYSTEM NOTES:
    * TRIPLE-CHECKED: Logic staggered to prevent I/O spikes during dialogue.
    * DATA FLOW: mud_cmd -> mud_quest -> mud_quest.2da.
    * 12-Character filename compliant.
   ============================================================================
*/

// [2DA REPLICA: mud_quest.2da]
// // Index | NPCTag      | Keyword | ReqItem     | ReqVar    | NPCResponse
// // 0     | BLACKSMITH  | hail    | **** | **** | "Need some iron, traveler?"
// // 1     | BLACKSMITH  | sword   | iron_ore    | q_smith_1 | "Fine ore. I'll get to work."
// // 2     | ELDER_JOE   | hail    | **** | **** | "The wolves... they're back."

#include "save_mgr"

// --- PROTOTYPES ---
void DOWE_QUEST_Process(object oPC, object oNPC, string sMsg);

// ----------------------------------------------------------------------------
// PHASE 1: TARGET ACQUISITION (Validation)
// ----------------------------------------------------------------------------
void main()
{
    object oPC = OBJECT_SELF;
    // We retrieve the message and the target identified by the chat_hook/cmd router.
    string sMsg = GetLocalString(oPC, "DOWE_CHAT_BUFFER");
    object oNPC = GetLocalObject(oPC, "DOWE_CHAT_TARGET");

    // TRIPLE-CHECK: Distance and Validity.
    if (!GetIsObjectValid(oNPC) || GetDistanceBetween(oPC, oNPC) > 5.0)
    {
        DOWE_MGR_Debug("QUEST_ERR: No valid NPC target within range.", oPC);
        return;
    }

    // PHASING: Stagger the 2DA scan by 0.2s. 
    // This spreads the load if multiple players 'hail' simultaneously.
    DelayCommand(0.2, DOWE_QUEST_Process(oPC, oNPC, sMsg));
}

// ----------------------------------------------------------------------------
// PHASE 2: THE LOGIC GATE (2DA Analysis)
// ----------------------------------------------------------------------------
void DOWE_QUEST_Process(object oPC, object oNPC, string sMsg)
{
    string sNPCTag = GetTag(oNPC);
    int i = 0;
    int nFound = FALSE;

    // Scan the Quest 2DA for a match on the NPC and the Keyword.
    string sCheckTag = Get2DAString("mud_quest", "NPCTag", i);
    
    while (sCheckTag != "")
    {
        // Check if this row belongs to the NPC the player is talking to.
        if (sCheckTag == sNPCTag)
        {
            string sKey = Get2DAString("mud_quest", "Keyword", i);
            
            // Check if the player's message matches the keyword (e.g., 'hail' or 'help').
            if (sMsg == sKey)
            {
                // PHASE 3: REQUIREMENT VALIDATION (Items & Variables)
                string sReqItem = Get2DAString("mud_quest", "ReqItem", i);
                string sReqVar  = Get2DAString("mud_quest", "ReqVar", i);
                
                int bItemPass = (sReqItem == "****" || GetIsObjectValid(GetItemPossessedBy(oPC, sReqItem)));
                int bVarPass  = (sReqVar  == "****" || GetLocalInt(oPC, sReqVar) == TRUE);

                if (bItemPass && bVarPass)
                {
                    // PHASE 4: EXECUTION (The Response)
                    string sText = Get2DAString("mud_quest", "NPCResponse", i);
                    
                    // Technical Annotation: Using AssignCommand ensures the NPC 
                    // is the owner of the text for visibility/immersion.
                    AssignCommand(oNPC, SpeakString(sText));
                    DOWE_MGR_Debug("QUEST_SUCCESS: " + sNPCTag + " responded to " + sKey, oPC);
                    
                    nFound = TRUE;
                    break; // Exit loop once a valid response is found.
                }
            }
        }
        i++;
        sCheckTag = Get2DAString("mud_quest", "NPCTag", i);
    }

    if (!nFound)
    {
        // If no keyword matches, the NPC simply ignores the player or gives a default.
        DOWE_MGR_Debug("QUEST_IDLE: No keyword/requirement match for " + sNPCTag, oPC);
    }
}
