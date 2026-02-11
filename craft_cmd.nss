/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: craft_cmd
    
    PILLARS:
    1. Environmental Reactivity (Coordinate-Based Logic)
    3. Optimized Scalability (Area-Specific 2DA Throttling)
    
    DESCRIPTION:
    Listens for //open, //mine, //craft, etc. Dynamically loads the 2DA 
    matching the current Area Tag to find the nearest interaction point.
    
    SYSTEM NOTES:
    * Triple-checked for 480-player CPU frame-budgeting.
    * Uses Spatial Math to bypass GetNearestObject overhead.
   ============================================================================
*/

// // 2DA REFERENCE: [AreaTag].2da (e.g., mine_level_1.2da)
// // Row | POS_X | POS_Y | POS_Z | PROFESSION | MODE | DATA_2DA

void main() {
    object oPC = GetPCChatSpeaker();
    string sMsg = GetPCChatMessage();
    object oArea = GetArea(oPC);
    string sArea2DA = GetTag(oArea); // Area Tag MUST match 2DA name
    vector vPC = GetPosition(oPC);
    
    // PHASE 0: DEBUG SYSTEM
    int bDebug = GetLocalInt(GetModule(), "DOWE_DEBUG_MODE");
    if(bDebug) SendMessageToPC(oPC, "DEBUG: [craft_cmd] Scanning 2DA: " + sArea2DA);

    // PHASE 1: CPU GUARD (Anti-Spam)
    if (GetLocalInt(oPC, "DOWE_ACT_BUSY")) return;
    SetLocalInt(oPC, "DOWE_ACT_BUSY", TRUE);
    DelayCommand(1.2, DeleteLocalInt(oPC, "DOWE_ACT_BUSY"));

    // PHASE 2: SPATIAL DATABASE LOOKUP
    int nRows = Get2DARowCount(sArea2DA);
    if (nRows <= 0) {
        if(bDebug) SendMessageToPC(oPC, "DEBUG: [craft_cmd] Failed to load 2DA: " + sArea2DA);
        return;
    }

    int i;
    for(i = 0; i < nRows; i++) {
        float fX = StringToFloat(Get2DAString(sArea2DA, "POS_X", i));
        float fY = StringToFloat(Get2DAString(sArea2DA, "POS_Y", i));
        
        // Distance Calculation (XY Plane)
        float fDist = sqrt(pow(fX - vPC.x, 2.0) + pow(fY - vPC.y, 2.0));

        // Interaction range check (3.0 meters)
        if (fDist <= 3.0) {
            // PHASE 3: OBJECT VERIFICATION
            object oTarget = GetFirstObjectInArea(oArea);
            while(GetIsObjectValid(oTarget)) {
                vector vTarget = GetPosition(oTarget);
                // Confirm object is at the exact 2DA coordinates
                if(vTarget.x == fX && vTarget.y == fY) {
                    
                    int nMode = Get2DAInt(sArea2DA, "MODE", i);
                    
                    // Branch 1: The //open Command (Containers)
                    if (sMsg == "//open") {
                        if (nMode == 2) {
                            if(bDebug) SendMessageToPC(oPC, "DEBUG: Found Container. Opening inventory.");
                            AssignCommand(oPC, ActionInteractObject(oTarget));
                        } else {
                            FloatingTextStringOnCreature("This is a resource, not a container.", oPC);
                        }
                        return;
                    }

                    // Branch 2: The Action Commands (mine/craft/gather/etc)
                    if (sMsg == "//mine" || sMsg == "//craft" || sMsg == "//gather") {
                        // Cache Area-2DA data onto the object for Phase 2 delegation
                        SetLocalString(oTarget, "PP_PROFESSION", Get2DAString(sArea2DA, "PROFESSION", i));
                        SetLocalString(oTarget, "PP_2DA_FILE", Get2DAString(sArea2DA, "DATA_2DA", i));
                        SetLocalInt(oTarget, "PP_CRAFT_MODE", nMode);
                        SetLocalInt(oTarget, "PP_2DA_ROW", i); 

                        if(bDebug) SendMessageToPC(oPC, "DEBUG: Coordinate Match! Running craft_core.");
                        ExecuteScript("craft_core", oTarget);
                        return;
                    }
                }
                oTarget = GetNextObjectInArea(oArea);
            }
        }
    }
}
