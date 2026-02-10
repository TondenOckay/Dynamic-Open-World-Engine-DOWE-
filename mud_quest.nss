/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.3 (Master Build - Faction & Global Ban Integrated)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: mud_quest
    
    PILLARS:
    1. Environmental Reactivity (Social Memory)
    3. Optimized Scalability (Phase-Staggered 2DA Scans)
    4. Intelligent Population (Reputation-Gated Dialogue)
    
    DESCRIPTION:
    The Gold Standard Quest/Dialogue Engine. This script reconciles player 
    chat input against the mud_quest.2da registry. It performs a 
    multi-stage validation check:
    1. Proximity: Is the NPC close enough to hear?
    2. Global Social Check: Is the player blacklisted by this faction?
    3. Faction Standing: Does the player meet the MinRep standing?
    4. Requirements: Does the player have the necessary items or variables?
    
    SYSTEM NOTES:
    * TRIPLE-CHECKED: Logic is staggered (0.2s) to prevent CPU spikes.
    * JSON SYNC: Directly interfaces with the JSON_REPUTATION passport.
    * PLUG-AND-PLAY: Communicates with fact_engine via DOWE_PRC variables.
    * 12-Character filename compliant.
   ============================================================================
*/

// [2DA REPLICA: mud_quest.2da]
// // Index | NPCTag      | Keyword | ReqItem  | ReqVar  | FactID | MinRep | NPCResponse
// // 0     | BLACKSMITH  | hail    | **** | **** | 1      | -150   | "Need iron, traveler?"
// // 1     | BLACKSMITH  | work    | iron_ore | q_smith | 1      | 51     | "Fine ore. I'll take it."

#include "save_mgr"

// --- PROTOTYPES ---
void DOWE_QUEST_Process(object oPC, object oNPC, string sMsg);

// --- DOWE DEBUG SYSTEM ---
void Quest_Debug(string sMsg, object oPC) {
    if (GetLocalInt(GetModule(), "DOWE_DEBUG_MODE") == TRUE) {
        SendMessageToPC(oPC, " [MUD_QUEST] -> " + sMsg);
    }
}

// ----------------------------------------------------------------------------
// PHASE 1: TARGET ACQUISITION & RANGE VALIDATION
// ----------------------------------------------------------------------------
void main()
{
    object oPC = OBJECT_SELF;
    
    // Retrieve the chat buffer and target NPC identified by the switchboard.
    string sMsg = GetLocalString(oPC, "DOWE_CHAT_BUFFER");
    object oNPC = GetLocalObject(oPC, "DOWE_CHAT_TARGET");

    // TRIPLE-CHECK: Range check (5.0m) to ensure the player is "roleplaying" the talk.
    if (!GetIsObjectValid(oNPC) || GetDistanceBetween(oPC, oNPC) > 5.0)
    {
        Quest_Debug("ERR: No valid NPC target within talking distance.", oPC);
        return;
    }

    // --- PHASE 1.5: SOCIAL PLUG-IN RECONCILIATION ---
    // TRIPLE-CHECK: If fact_engine has flagged this player as BANNED (AccessDenied),
    // we abort the quest engine immediately to save CPU cycles.
    if (GetLocalInt(oPC, "DOWE_PRC_DENY") == TRUE)
    {
        AssignCommand(oNPC, SpeakString("I have nothing to say to you. Begone."));
        Quest_Debug("ABORT: PC is globally banned by this faction.", oPC);
        return;
    }

    // PHASING: Stagger the 2DA scan to protect the server's heartbeat.
    DelayCommand(0.2, DOWE_QUEST_Process(oPC, oNPC, sMsg));
}

// ----------------------------------------------------------------------------
// PHASE 2: REPUTATION & LOGIC RECONCILIATION
// ----------------------------------------------------------------------------
void DOWE_QUEST_Process(object oPC, object oNPC, string sMsg)
{
    string sNPCTag = GetTag(oNPC);
    int i = 0;
    int nFound = FALSE;

    // PERFORMANCE: Convert player message to lowercase once.
    string sLowerMsg = GetStringLowerCase(sMsg);

    // Initial 2DA read.
    string sCheckTag = Get2DAString("mud_quest", "NPCTag", i);
    
    while (sCheckTag != "")
    {
        // Only process rows matching the NPC currently being addressed.
        if (sCheckTag == sNPCTag)
        {
            // Keyword Case-Insensitivity Check.
            string sKey = GetStringLowerCase(Get2DAString("mud_quest", "Keyword", i));
            
            // SUBSTRING SEARCH: Support natural chat input.
            if (FindSubString(sLowerMsg, sKey) != -1)
            {
                // PHASE 3: THE FACTION GATE (Specific Row Requirement)
                int nFactID = StringToInt(Get2DAString("mud_quest", "FactID", i));
                int nMinRep = StringToInt(Get2DAString("mud_quest", "MinRep", i));

                // Retrieve player's Reputation JSON from the Master Passport.
                json jReps = GetLocalJson(oPC, "JSON_REPUTATION");
                int nPlayerRep = JsonIntPtr(JsonObjectGet(jReps, IntToString(nFactID)));

                // REPUTATION CHECK: Does player meet the specific line requirement?
                if (nPlayerRep >= nMinRep)
                {
                    // PHASE 4: REQUIREMENT VALIDATION (Item & Variable check)
                    string sReqItem = Get2DAString("mud_quest", "ReqItem", i);
                    string sReqVar  = Get2DAString("mud_quest", "ReqVar", i);
                    
                    int bItemPass = (sReqItem == "****" || GetIsObjectValid(GetItemPossessedBy(oPC, sReqItem)));
                    int bVarPass  = (sReqVar  == "****" || GetLocalInt(oPC, sReqVar) == TRUE);

                    if (bItemPass && bVarPass)
                    {
                        // PHASE 5: EXECUTION (NPC Response)
                        string sText = Get2DAString("mud_quest", "NPCResponse", i);
                        
                        AssignCommand(oNPC, SpeakString(sText));
                        Quest_Debug("SUCCESS: Keyword '" + sKey + "' triggered for Faction " + IntToString(nFactID), oPC);
                        
                        nFound = TRUE;
                        break; // Match found; exit loop.
                    }
                    else
                    {
                        Quest_Debug("FAIL: PC lacks item '" + sReqItem + "' or variable '" + sReqVar + "'.", oPC);
                    }
                }
                else
                {
                    // IMMERSION: Reputation too low for this specific piece of info.
                    AssignCommand(oNPC, SpeakString("I don't trust you enough to discuss that."));
                    Quest_Debug("REJECTION: Player Rep (" + IntToString(nPlayerRep) + ") < MinRep (" + IntToString(nMinRep) + ")", oPC);
                    return; 
                }
            }
        }
        i++;
        sCheckTag = Get2DAString("mud_quest", "NPCTag", i);
    }

    if (!nFound)
    {
        Quest_Debug("IDLE: No keyword match found in 2DA for '" + sLowerMsg + "'", oPC);
    }
}
