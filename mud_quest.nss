/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.1 (Master Build - Keyword Search)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: mud_quest
    
    PILLARS:
    3. Optimized Scalability (Phase-Staggered 2DA Scans)
    4. Intelligent Population (Dynamic Keyword/Variable Logic)
    
    SYSTEM NOTES:
    * TRIPLE-CHECKED: Logic staggered to prevent I/O spikes during dialogue.
    * SUBSTRING MATCHING: Allows natural speech (e.g., "//yes I want work").
    * CASE INSENSITIVE: Converts both input and 2DA key to lowercase.
    * 12-Character filename compliant.
   ============================================================================
*/

// [2DA REPLICA: mud_quest.2da]
// // Index | NPCTag      | Keyword | ReqItem     | ReqVar    | NPCResponse
// // 0     | BLACKSMITH  | hail    | **** | **** | "Need some iron, traveler?"
// // 1     | BLACKSMITH  | work    | iron_ore    | q_smith_1 | "Fine ore. I'll get to work."
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
    // Retrieve the chat buffer and target NPC identified by the command router.
    string sMsg = GetLocalString(oPC, "DOWE_CHAT_BUFFER");
    object oNPC = GetLocalObject(oPC, "DOWE_CHAT_TARGET");

    // TRIPLE-CHECK: Validation of NPC distance to prevent "Remote Hailing".
    if (!GetIsObjectValid(oNPC) || GetDistanceBetween(oPC, oNPC) > 5.0)
    {
        DOWE_MGR_Debug("QUEST_ERR: No valid NPC target within range.", oPC);
        return;
    }

    // PHASING: Stagger the 2DA scan by 0.2s. 
    // This spreads the CPU load across frames to protect the 480-player heartbeat.
    DelayCommand(0.2, DOWE_QUEST_Process(oPC, oNPC, sMsg));
}

// ----------------------------------------------------------------------------
// PHASE 2: THE LOGIC GATE (Case-Insensitive Substring Scan)
// ----------------------------------------------------------------------------
void DOWE_QUEST_Process(object oPC, object oNPC, string sMsg)
{
    string sNPCTag = GetTag(oNPC);
    int i = 0;
    int nFound = FALSE;

    // GOLD STANDARD: Convert player message to lowercase once to save cycles in the loop.
    string sLowerMsg = GetStringLowerCase(sMsg);

    // Initial 2DA read to start the loop.
    string sCheckTag = Get2DAString("mud_quest", "NPCTag", i);
    
    while (sCheckTag != "")
    {
        // Only process rows assigned to this specific NPC Tag.
        if (sCheckTag == sNPCTag)
        {
            // Convert 2DA keyword to lowercase for a guaranteed match regardless of casing.
            string sKey = GetStringLowerCase(Get2DAString("mud_quest", "Keyword", i));
            
            // GOLD STANDARD UPGRADE: FindSubString.
            // This checks if the keyword exists anywhere in the message.
            // If FindSubString is not -1, the word was found.
            if (FindSubString(sLowerMsg, sKey) != -1)
            {
                // PHASE 3: REQUIREMENT VALIDATION (Items & Variables)
                string sReqItem = Get2DAString("mud_quest", "ReqItem", i);
                string sReqVar  = Get2DAString("mud_quest", "ReqVar", i);
                
                // Check for placeholder '****' (No requirement) or actual possession.
                int bItemPass = (sReqItem == "****" || GetIsObjectValid(GetItemPossessedBy(oPC, sReqItem)));
                int bVarPass  = (sReqVar  == "****" || GetLocalInt(oPC, sReqVar) == TRUE);

                if (bItemPass && bVarPass)
                {
                    // PHASE 4: EXECUTION (The Response)
                    string sText = Get2DAString("mud_quest", "NPCResponse", i);
                    
                    // Technical Annotation: Assigning command to the NPC for chat-log attribution.
                    AssignCommand(oNPC, SpeakString(sText));
                    DOWE_MGR_Debug("QUEST_HIT: Match found for keyword '" + sKey + "'", oPC);
                    
                    nFound = TRUE;
                    break; // Exit loop immediately once a valid response is triggered.
                }
            }
        }
        i++;
        sCheckTag = Get2DAString("mud_quest", "NPCTag", i);
    }

    // If no keyword matches, clear logic or send a debug tracer.
    if (!nFound)
    {
        DOWE_MGR_Debug("QUEST_IDLE: No valid match in 2DA for '" + sLowerMsg + "'", oPC);
    }
}
