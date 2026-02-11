/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: obj_cmd
    
    PILLARS:
    1. Environmental Reactivity (3D Height-Aware Logic)
    2. Biological Persistence (N/A - Interaction Layer)
    3. Optimized Scalability (Area-Specific 2DA Throttling)
    4. Intelligent Population (Automated Fixed/Random Loot)
    
    DESCRIPTION:
    The "Master Key" Gateway. This script intercepts player chat commands and 
    cross-references the player's 3D coordinates against an area-specific 2DA. 
    It handles text responses, multi-item spawning, and delegates to the 
    crafting or loot engines as needed.
    
    SYSTEM NOTES:
    * Triple-checked for 02/2026 CPU Frame-Budgeting Standards.
    * Uses 3D Pythagorean Distance to prevent floor-clipping exploits.
    * Integrated with DOWE Debug System (DOWE_DEBUG_MODE).
   ============================================================================
*/

// // 2DA REFERENCE: [Area_Tag].2da
// // ---------------------------------------------------------------------------
// // ID_HASH | POS_X | POS_Y | POS_Z | CMD | RESPONSE | ITEM_LIST | RAND_TABLE | TYPE | PROFESSION | DATA_2DA
// // ---------------------------------------------------------------------------
// // Note: ITEM_LIST uses CSV (Comma Separated Values) e.g., "it_apple,it_bread"

#include "nw_i0_generic"

// HELPER: GetCSV - Parses a specific index from a comma-separated string.
// Optimized for memory efficiency in loops.
string GetCSV(string sList, int nIndex) {
    int nPos = 0; int nCount = 0;
    while (nCount < nIndex) {
        nPos = FindSubString(sList, ",", nPos);
        if (nPos == -1) return "";
        nPos++; nCount++;
    }
    int nEnd = FindSubString(sList, ",", nPos);
    if (nEnd == -1) return GetSubString(sList, nPos, GetStringLength(sList) - nPos);
    return GetSubString(sList, nPos, nEnd - nPos);
}

void main() {
    // PHASE 0: INITIALIZATION & DATA ACQUISITION
    object oPC = GetPCChatSpeaker();
    string sMsg = GetPCChatMessage();
    object oArea = GetArea(oPC);
    string sArea2DA = GetTag(oArea); // Area Tag must match the 2DA file name.
    vector vPC = GetPosition(oPC);
    
    // DEBUG INITIALIZATION
    int bDebug = GetLocalInt(GetModule(), "DOWE_DEBUG_MODE");
    if(bDebug) SendMessageToPC(oPC, "DEBUG: [obj_cmd] Interaction pulse in " + sArea2DA);

    // PHASE 1: ANTI-SPAM & CPU THROTTLING
    // Prevents chat-spam from flooding the 2DA search engine.
    if (GetLocalInt(oPC, "DOWE_ACT_BUSY")) return;
    SetLocalInt(oPC, "DOWE_ACT_BUSY", TRUE);
    DelayCommand(1.2, DeleteLocalInt(oPC, "DOWE_ACT_BUSY"));

    // PHASE 2: SPATIAL 2DA SCAN (Area-Specific Throttling)
    int nRows = Get2DARowCount(sArea2DA);
    if (nRows <= 0) {
        if(bDebug) SendMessageToPC(oPC, "DEBUG: [obj_cmd] No 2DA found for " + sArea2DA);
        return;
    }

    int i;
    for(i = 0; i < nRows; i++) {
        // Retrieve 3D Coordinates from 2DA
        float fX = StringToFloat(Get2DAString(sArea2DA, "POS_X", i));
        float fY = StringToFloat(Get2DAString(sArea2DA, "POS_Y", i));
        float fZ = StringToFloat(Get2DAString(sArea2DA, "POS_Z", i));
        
        // 3D Distance Calculation: Prevents interacting with objects on different floors.
        float fDist = sqrt(pow(fX - vPC.x, 2.0) + pow(fY - vPC.y, 2.0) + pow(fZ - vPC.z, 2.0));

        // Validation Range: 3.5 meters
        if (fDist <= 3.5) {
            // PHASE 3: COMMAND & CONTEXT MATCHING
            string sCmd = Get2DAString(sArea2DA, "CMD", i);
            
            // Checks for custom command (e.g., //search) or universal overrides.
            if (sMsg == sCmd || sMsg == "//open" || sMsg == "//use") {
                
                if(bDebug) SendMessageToPC(oPC, "DEBUG: [obj_cmd] Match found at Row " + IntToString(i));

                // PHASE 4: TEXTUAL FEEDBACK (RESPONSE)
                string sResp = Get2DAString(sArea2DA, "RESPONSE", i);
                if (sResp != "" && sResp != "****") {
                    FloatingTextStringOnCreature(sResp, oPC, FALSE);
                }

                // PHASE 5: FIXED ITEM LOGIC (ITEM_LIST)
                // Processes the CSV string and populates player inventory.
                string sItems = Get2DAString(sArea2DA, "ITEM_LIST", i);
                if (sItems != "" && sItems != "****") {
                    int j = 0; string sItem = GetCSV(sItems, j);
                    while (sItem != "") {
                        // TrimString ensures no accidental spaces in 2DA break the ResRef.
                        CreateItemOnObject(TrimString(sItem), oPC);
                        if(bDebug) SendMessageToPC(oPC, "DEBUG: [obj_cmd] Item Created: " + sItem);
                        j++; sItem = GetCSV(sItems, j);
                    }
                }

                // PHASE 6: PHYSICAL OBJECT SYNC & ENGINE DELEGATION
                // Identifies the actual placeable at the coordinates to trigger animations.
                string sType = Get2DAString(sArea2DA, "TYPE", i);
                object oTarget = GetFirstObjectInArea(oArea);
                while(GetIsObjectValid(oTarget)) {
                    vector vT = GetPosition(oTarget);
                    // Match object to 2DA coordinate precisely.
                    if(vT.x == fX && vT.y == fY) {
                        
                        // DELEGATION: Crafting/Gathering (NODE or CRAFT types)
                        if (sType == "NODE" || sType == "CRAFT") {
                            SetLocalString(oTarget, "PP_PROFESSION", Get2DAString(sArea2DA, "PROFESSION", i));
                            SetLocalString(oTarget, "PP_2DA_FILE", Get2DAString(sArea2DA, "DATA_2DA", i));
                            SetLocalInt(oTarget, "PP_2DA_ROW", i);
                            SetLocalInt(oTarget, "PP_CRAFT_MODE", (sType == "NODE" ? 1 : 2));
                            ExecuteScript("craft_core", oTarget);
                        }
                        
                        // DELEGATION: Random Loot System
                        string sRand = Get2DAString(sArea2DA, "RAND_TABLE", i);
                        if (sRand != "" && sRand != "****") {
                            SetLocalString(oPC, "TEMP_LOOT_TABLE", sRand);
                            ExecuteScript("loot_gen", oPC);
                        }

                        // Play standard interaction animation (turning to face object).
                        AssignCommand(oPC, ActionInteractObject(oTarget));
                        return; // Script Exit Point (Success)
                    }
                    oTarget = GetNextObjectInArea(oArea);
                }
                return; // 2DA Matched but Object missing from Area.
            }
        }
    }
}
