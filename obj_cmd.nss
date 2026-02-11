/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: obj_cmd
    
    PILLARS:
    1. Environmental Reactivity (3D Height-Aware Logic)
    3. Optimized Scalability (Area-Specific 2DA Loading)
    
    DESCRIPTION:
    The core listener for all world interactions. Matches player 3D coordinates 
    to the area's specific 2DA database.
   ============================================================================
*/

// // 2DA COLUMN ORDER:
// // ID_HASH | POS_X | POS_Y | POS_Z | CMD | RESPONSE | ITEM_LIST | RAND_TABLE | TYPE | PROFESSION | DATA_2DA

#include "nw_i0_generic"

// Helper: CSV Parser for ITEM_LIST
string GetCSV(string sL, int nI) {
    int nP = 0; int nC = 0;
    while (nC < nI) { nP = FindSubString(sL, ",", nP); if (nP == -1) return ""; nP++; nC++; }
    int nE = FindSubString(sL, ",", nP);
    if (nE == -1) return GetSubString(sL, nP, GetStringLength(sL) - nP);
    return GetSubString(sL, nP, nE - nP);
}

void main() {
    object oPC = GetPCChatSpeaker();
    string sMsg = GetPCChatMessage();
    object oArea = GetArea(oPC);
    string sArea2DA = GetTag(oArea);
    vector vPC = GetPosition(oPC);
    int bDebug = GetLocalInt(GetModule(), "DOWE_DEBUG_MODE");

    // PHASE 1: LOAD AREA DATA
    int nRows = Get2DARowCount(sArea2DA);
    if (nRows <= 0) return; // No data for this area

    int i;
    for(i = 0; i < nRows; i++) {
        // PHASE 2: 3D DISTANCE MATH
        float fX = StringToFloat(Get2DAString(sArea2DA, "POS_X", i));
        float fY = StringToFloat(Get2DAString(sArea2DA, "POS_Y", i));
        float fZ = StringToFloat(Get2DAString(sArea2DA, "POS_Z", i));
        
        float fDist = sqrt(pow(fX - vPC.x, 2.0) + pow(fY - vPC.y, 2.0) + pow(fZ - vPC.z, 2.0));

        if (fDist <= 3.5) {
            // PHASE 3: COMMAND MATCHING
            string sCmd = Get2DAString(sArea2DA, "CMD", i);
            if (sMsg == sCmd || sMsg == "//open") {
                
                if(bDebug) SendMessageToPC(oPC, "DEBUG: [obj_cmd] Interaction matched at Row " + IntToString(i));

                // PHASE 4: RESPONSES & ITEMS
                string sResp = Get2DAString(sArea2DA, "RESPONSE", i);
                if (sResp != "" && sResp != "****") SendMessageToPC(oPC, sResp);

                string sItems = Get2DAString(sArea2DA, "ITEM_LIST", i);
                if (sItems != "" && sItems != "****") {
                    int j = 0; string sItem = GetCSV(sItems, j);
                    while (sItem != "") {
                        CreateItemOnObject(TrimString(sItem), oPC);
                        j++; sItem = GetCSV(sItems, j);
                    }
                }

                // PHASE 5: ENGINE DELEGATION
                string sType = Get2DAString(sArea2DA, "TYPE", i);
                object oT = GetFirstObjectInArea(oArea);
                while(GetIsObjectValid(oT)) {
                    vector vT = GetPosition(oT);
                    if(vT.x == fX && vT.y == fY) {
                        
                        // Handle Crafting/Gathering
                        if (sType == "NODE" || sType == "CRAFT") {
                            SetLocalString(oT, "PP_PROFESSION", Get2DAString(sArea2DA, "PROFESSION", i));
                            SetLocalString(oT, "PP_2DA_FILE", Get2DAString(sArea2DA, "DATA_2DA", i));
                            SetLocalInt(oT, "PP_2DA_ROW", i);
                            SetLocalInt(oT, "PP_CRAFT_MODE", (sType == "NODE" ? 1 : 2));
                            ExecuteScript("craft_core", oT);
                        }
                        
                        // Handle Random Loot Hook
                        string sRand = Get2DAString(sArea2DA, "RAND_TABLE", i);
                        if (sRand != "" && sRand != "****") {
                            SetLocalString(oPC, "TEMP_LOOT_TABLE", sRand);
                            ExecuteScript("loot_gen", oPC);
                        }

                        AssignCommand(oPC, ActionInteractObject(oT));
                        return;
                    }
                    oT = GetNextObjectInArea(oArea);
                }
                return;
            }
        }
    }
}
