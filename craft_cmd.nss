/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: craft_cmd
    
    PILLARS:
    1. Environmental Reactivity (Contextual Profession Interaction)
    3. Optimized Scalability (480-Player Phase-Staggering)
    
    DESCRIPTION:
    The Gatekeeper for all professions. Handles Tool Checks, Skill Math
    (4% per level), and the 10% Skill Gain logic. Hand-off to sub-scripts.
    
    SYSTEM NOTES:
    * Triple-checked for CPU Frame-Budgeting.
    * Integrated with the_switchboard (P&P Variables).
   ============================================================================
*/

// // 2DA REFERENCE (GATHER_MINE.2DA, GATHER_WOOD.2DA, GATHER_HERB.2DA, CRAFT_SMITH.2DA, etc)
// // Label | MinReq | BaseCh | ToolReq | Mode | Profession | Result | Item1 | Qty1 | ...

void main() {
    object oPC = GetLastUsedBy();
    object oTarget = OBJECT_SELF;
    
    // PHASE 0: DEBUG INITIALIZATION
    // Checks if the module-wide debug toggle is active.
    int bDebug = GetLocalInt(GetModule(), "DOWE_DEBUG_MODE");
    if(bDebug) SendMessageToPC(oPC, "DEBUG: [craft_cmd] Initializing interaction on " + GetTag(oTarget));

    // PHASE 1: ANTI-SPAM & CPU THROTTLING
    // Prevents the VM from being flooded by rapid-clicking players.
    if (GetLocalInt(oPC, "DOWE_ACT_BUSY")) {
        if(bDebug) SendMessageToPC(oPC, "DEBUG: [craft_cmd] Action blocked. Player Busy.");
        return;
    }
    SetLocalInt(oPC, "DOWE_ACT_BUSY", TRUE);
    DelayCommand(1.2, DeleteLocalInt(oPC, "DOWE_ACT_BUSY"));

    // PHASE 2: DATA ACQUISITION (the_switchboard CACHE)
    // Variables cached on the object by the Area Pulse to avoid constant 2DA reads.
    string sProf  = GetLocalString(oTarget, "PP_PROFESSION"); 
    int nMinReq   = GetLocalInt(oTarget, "PP_MIN_REQ");
    int nBaseCh   = GetLocalInt(oTarget, "PP_BASE_CHANCE");
    string sTool  = GetLocalString(oTarget, "PP_TOOL_TAG");
    int nMode     = GetLocalInt(oTarget, "PP_CRAFT_MODE"); // 1=Gather, 2=Create
    int nSkill    = GetLocalInt(oPC, "SKILL_" + sProf);

    if(bDebug) SendMessageToPC(oPC, "DEBUG: [craft_cmd] Prof: " + sProf + " | Current Skill: " + IntToString(nSkill));

    // PHASE 3: REQUIREMENT VALIDATION
    // Check Tool: Must be held or in inventory.
    if (sTool != "" && !GetIsObjectValid(GetItemPossessedBy(oPC, sTool))) {
        FloatingTextStringOnCreature("Proper tool required: " + sTool, oPC);
        if(bDebug) SendMessageToPC(oPC, "DEBUG: [craft_cmd] Tool validation failed.");
        return;
    }
    // Check Skill Floor: Is the player even allowed to attempt this?
    if (nSkill < nMinReq) {
        FloatingTextStringOnCreature("Skill insufficient. Need " + IntToString(nMinReq), oPC);
        if(bDebug) SendMessageToPC(oPC, "DEBUG: [craft_cmd] Skill floor check failed.");
        return;
    }

    // PHASE 4: SUCCESS MATH (4% PROGRESSION RULE)
    // Formula: Base + ((Skill - Requirement) * 4)
    int nChance = nBaseCh + ((nSkill - nMinReq) * 4);
    if (nChance > 95) nChance = 95; // 5% failure floor for economic stability.
    int bSuccess = (d100() <= nChance);

    if(bDebug) SendMessageToPC(oPC, "DEBUG: [craft_cmd] Success Chance: " + IntToString(nChance) + "% | Roll: " + IntToString(bSuccess));

    // PHASE 5: 10% PROGRESSION ROLL (FAIL OR SUCCEED)
    // Skill gain is independent of interaction success.
    if (d100() <= 10) {
        int nNewSkill = nSkill + 1;
        SetLocalInt(oPC, "SKILL_" + sProf, nNewSkill);
        SendMessageToPC(oPC, "PROGRESS: Your " + sProf + " skill is now " + IntToString(nNewSkill) + "!");
        ExecuteScript("dowe_db_sync", oPC); // Push to persistent database
        if(bDebug) SendMessageToPC(oPC, "DEBUG: [craft_cmd] Skill gain triggered.");
    }

    // PHASE 6: MODULAR DELEGATION
    // Handing off the logic to sub-scripts to clear the current memory stack.
    SetLocalInt(oTarget, "TEMP_SUCCESS", bSuccess);
    if (nMode == 1) ExecuteScript("craft_gather", oTarget);
    else ExecuteScript("craft_create", oTarget);
}
