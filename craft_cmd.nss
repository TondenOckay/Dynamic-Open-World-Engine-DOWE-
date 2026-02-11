/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: craft_cmd
    
    PILLARS:
    3. Optimized Scalability (Area-Specific 2DA Throttling)
    
    DESCRIPTION:
    Universal listener for //open, //mine, //craft.
    Dynamically maps the 2DA name to the Area Tag for ultra-fast lookup.
    Example: Player in area "mine_level_1" triggers "mine_level_1.2da".
   ============================================================================
*/

void main() {
    object oPC = GetPCChatSpeaker();
    string sMsg = GetPCChatMessage();
    object oArea = GetArea(oPC);
    string sAreaTag = GetTag(oArea);
    vector vPC = GetPosition(oPC);
    int bDebug = GetLocalInt(GetModule(), "DOWE_DEBUG_MODE");

    // PHASE 1: DYNAMIC 2DA IDENTIFICATION
    // We assume the 2DA is named EXACTLY the same as the Area Tag.
    string sArea2DA = sAreaTag; 

    // PHASE 2: SPATIAL SCAN (Throttled to current area data only)
    int nRows = Get2DARowCount(sArea2DA);
    if (nRows <= 0) {
        if(bDebug) SendMessageToPC(oPC, "DEBUG: No 2DA found named: " + sArea2DA);
        return;
    }

    int i;
    for(i = 0; i < nRows; i++) {
        float fX = StringToFloat(Get2DAString(sArea2DA, "POS_X", i));
        float fY = StringToFloat(Get2DAString(sArea2DA, "POS_Y", i));
        
        // Simple distance math to check if player is standing at the 2DA coordinates
        float fDist = sqrt(pow(fX - vPC.x, 2.0) + pow(fY - vPC.y, 2.0));

        if (fDist <= 3.0) {
            // PHASE 3: PHYSICAL OBJECT MATCH
            object oTarget = GetFirstObjectInArea(oArea);
            while(GetIsObjectValid(oTarget)) {
                vector vTarget = GetPosition(oTarget);
                // Check for exact coordinate match to ensure we have the right placeable
                if(vTarget.x == fX && vTarget.y == fY) {
                    
                    int nMode = Get2DAInt(sArea2DA, "MODE", i);
                    
                    // Logic Branch: Open vs Action
                    if (sMsg == "//open") {
                        if (nMode == 2) {
                            if(bDebug) SendMessageToPC(oPC, "DEBUG: Opening Container via " + sArea2DA);
                            AssignCommand(oPC, ActionInteractObject(oTarget));
                        } else {
                            FloatingTextStringOnCreature("This is a resource node, use //mine or //gather.", oPC);
                        }
                        return;
                    }

                    if (sMsg == "//mine" || sMsg == "//craft" || sMsg == "//gather") {
                        // Cache 2DA data onto the object for the Core Engine
                        SetLocalString(oTarget, "PP_PROFESSION", Get2DAString(sArea2DA, "PROFESSION", i));
                        SetLocalString(oTarget, "PP_2DA_FILE", Get2DAString(sArea2DA, "DATA_2DA", i));
                        SetLocalInt(oTarget, "PP_CRAFT_MODE", nMode);
                        SetLocalInt(oTarget, "PP_2DA_ROW", i); // Pass row for deep lookup

                        if(bDebug) SendMessageToPC(oPC, "DEBUG: Match found in " + sArea2DA + " at row " + IntToString(i));
                        ExecuteScript("craft_engine_core", oTarget);
                        return;
                    }
                }
                oTarget = GetNextObjectInArea(oArea);
            }
        }
    }
}
