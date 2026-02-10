/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: area_mud_cmd
    
    DESCRIPTION:
    Intercepts player chat for // commands. Cross-references the 'area_mud_op' 
    lists to find targets and executes the object processor.
   ============================================================================
*/

/* // ----------------------------------------------------------------------------
// 2DA COPY: mud_commands.2da
// ----------------------------------------------------------------------------
// ID   Command     ActionType      TargetGroup
// 0    //mine      GATHER          OBJECT
// 1    //hail      CONVERSE        NPC
// 2    //shop      STORE           SHOP
// 3    //combine   CRAFT           STATION
// ----------------------------------------------------------------------------
*/

void DOWE_CMD_Debug(string sMsg, object oPC) {
    if (GetGlobalInt("DOWE_DEBUG_SWITCH") == 1) {
        SendMessageToPC(oPC, "[DOWE CMD DEBUG] " + sMsg);
    }
}

void main() {
    object oPC = GetPCChatSpeaker();
    string sMsg = GetStringLowerCase(GetPCChatMessage());

    if (Left(sMsg, 2) != "//") return;

    DOWE_CMD_Debug("Command Intercepted: " + sMsg, oPC);

    // Phase 1: Target Identification (Pull from OP lists for speed)
    object oArea = GetArea(oPC);
    object oTarget = GetLocalObject(oPC, "DOWE_LAST_TARGET"); // Last clicked
    
    if (!GetIsObjectValid(oTarget)) {
        oTarget = GetNearestObject(OBJECT_TYPE_ALL, oPC);
    }

    // Phase 2: Variable Staging for area_mud_obj
    SetLocalString(oPC, "DOWE_PENDING_CMD", sMsg);
    SetLocalObject(oPC, "DOWE_CURRENT_TARGET", oTarget);

    // Phase 3: Execute Logic Processor
    ExecuteScript("area_mud_obj", oPC);
}
