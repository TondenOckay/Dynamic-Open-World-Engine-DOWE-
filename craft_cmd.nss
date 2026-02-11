/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: craft_cmd
    
    PILLARS:
    1. Environmental Reactivity (Contextual Profession Interaction)
    3. Optimized Scalability (480-Player Phase-Staggering)
    
    DESCRIPTION:
    The Gatekeeper for all professions. Handles Tool Checks, Skill Math, 
    and the 10% Skill Gain. 
    * GOLD STANDARD UPDATE: Now includes Auto-Return of items if Skill/Tool 
      requirements are not met.
    
    SYSTEM NOTES:
    * Triple-checked for CPU Frame-Budgeting.
    * Integrated with the_switchboard (P&P Variables).
   ============================================================================
*/

// // 2DA REFERENCE (GATHER_MINE, GATHER_WOOD, GATHER_HERB, CRAFT_SMITH, etc)
// // Label | MinReq | BaseCh | ToolReq | Mode | Profession | Result | Item1 | Qty1 | ...

void main() {
    object oPC = GetLastUsedBy();
    object oTarget = OBJECT_SELF;
    
    // PHASE 0: DEBUG INITIALIZATION
    int bDebug = GetLocalInt(GetModule(), "DOWE_DEBUG_MODE");
    if(bDebug) SendMessageToPC(oPC, "DEBUG: [craft_cmd] Interaction pulse on " + GetTag(oTarget));

    // PHASE 1: ANTI-SPAM & CPU THROTTLING
    if (GetLocalInt(oPC, "DOWE_ACT_BUSY")) {
        if(bDebug) SendMessageToPC(oPC, "DEBUG: [craft_cmd] Blocked: Player Busy.");
        return;
    }
    SetLocalInt(oPC, "DOWE_ACT_BUSY", TRUE);
    DelayCommand(1.2, DeleteLocalInt(oPC, "DOWE_ACT_BUSY"));

    // PHASE 2: DATA ACQUISITION (the_switchboard CACHE)
    string sProf  = GetLocalString(oTarget, "PP_PROFESSION"); 
    int nMinReq   = GetLocalInt(oTarget, "PP_MIN_REQ");
    int nBaseCh   = GetLocalInt(oTarget, "PP_BASE_CHANCE");
    string sTool  = GetLocalString(oTarget, "PP_TOOL_TAG");
    int nMode     = GetLocalInt(oTarget, "PP_CRAFT_MODE"); // 1=Gather, 2=Create
    int nSkill    = GetLocalInt(oPC, "SKILL_" + sProf);

    // PHASE 3: REQUIREMENT VALIDATION & AUTO-RETURN
    int bFail = FALSE;
    string sError = "";

    // Check Tool Requirement
    if (sTool != "" && !GetIsObjectValid(GetItemPossessedBy(oPC, sTool))) {
        sError = "Proper tool required: " + sTool;
        bFail = TRUE;
    }
    // Check Skill Floor
    else if (nSkill < nMinReq) {
        sError = "Skill insufficient. Need " + IntToString(nMinReq);
        bFail = TRUE;
    }

    if (bFail) {
        FloatingTextStringOnCreature(sError, oPC);
        if(bDebug) SendMessageToPC(oPC, "DEBUG: [craft_cmd] Validation Failed. Executing Auto-Return.");
        
        // GOLD STANDARD: If it's a container (Mode 2), spit items back to PC bags
        if (nMode == 2) {
            object oItem = GetFirstItemInInventory(oTarget);
            while (GetIsObjectValid(oItem)) {
                CopyItem(oItem, oPC, TRUE);
                DestroyObject(oItem);
                oItem = GetNextItemInInventory(oTarget);
            }
        }
        return;
    }

    // PHASE 4: SUCCESS MATH (4% PROGRESSION RULE)
    int nChance = nBaseCh + ((nSkill - nMinReq) * 4);
    if (nChance > 95) nChance = 95; 
    int bSuccess = (d100() <= nChance);

    // PHASE 5: 10% PROGRESSION ROLL (Independent of Success)
    if (d100() <= 10) {
        SetLocalInt(oPC, "SKILL_" + sProf, nSkill + 1);
        SendMessageToPC(oPC, "PROGRESS: Your " + sProf + " skill is now " + IntToString(nSkill + 1) + "!");
        ExecuteScript("dowe_db_sync", oPC); 
    }

    // PHASE 6: MODULAR DELEGATION
    SetLocalInt(oTarget, "TEMP_SUCCESS", bSuccess);
    if (nMode == 1) ExecuteScript("craft_gather", oTarget);
    else ExecuteScript("craft_create", oTarget);
}
