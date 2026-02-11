/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: enc_gps_ai
    
    PILLARS:
    1. Environmental Reactivity (Localized Pathfinding)
    3. Optimized Scalability (Dormancy/Stasis Logic)
    
    DESCRIPTION:
    The AI for "Static" GPS encounters. Includes a Stasis check: if no player
    has been near (40m) in the last 60 seconds, the AI suspends movement.
    
    SYSTEM NOTES:
    * Triple-checked for 02/2026 Gold Standard.
    * Independent: Only functions if "Woken" by a PC Ripple.
   ============================================================================
*/

#include "nw_i0_generic"

// HELPER: GetNextNodeInList - Parses CSV strings for waypoint IDs.
int GetNextNodeInList(string sList, int nIndex) {
    int nPos = 0; int nCount = 0;
    while (nCount < nIndex) {
        nPos = FindSubString(sList, ",", nPos);
        if (nPos == -1) return -1;
        nPos++; nCount++;
    }
    int nEnd = FindSubString(sList, ",", nPos);
    string sRes;
    if (nEnd == -1) sRes = GetSubString(sList, nPos, GetStringLength(sList) - nPos);
    else sRes = GetSubString(sList, nPos, nEnd - nPos);
    return StringToInt(TrimString(sRes));
}

void main() {
    object oSelf = OBJECT_SELF;
    int bDebug = GetLocalInt(GetModule(), "DOWE_DEBUG_MODE");

    // PHASE 0: STASIS & COMBAT GUARD
    // If we haven't been "touched" by a PC ripple in 60s, shut down.
    int nWakeTime = GetLocalInt(oSelf, "DOWE_WAKE_TIME");
    int nCurrentTime = GetTimeSecond() + (GetTimeMinute() * 60);
    
    if (nCurrentTime > (nWakeTime + 60)) {
        if(bDebug && nWakeTime != 0) SetLocalInt(oSelf, "DOWE_WAKE_TIME", 0); // Reset for debug
        return; 
    }

    // Abort if already fighting.
    if (GetIsObjectValid(GetAttemptedAttackTarget()) || GetIsInCombat(oSelf)) return;

    // PHASE 1: SILO INITIALIZATION
    object oArea = GetArea(oSelf);
    string sAreaTag = GetTag(oArea);
    int nSpawnID = GetLocalInt(oSelf, "DOWE_GPS_SPAWN_ID");
    string sPatrol2DA = sAreaTag + "_patrols";
    string sWalk2DA = sAreaTag + "_gps_walk";

    // PHASE 2: PATROL LOGIC
    int nCurrentStep = GetLocalInt(oSelf, "DOWE_PATROL_STEP");
    string sNodeList = Get2DAString(sPatrol2DA, "WAYPOINT_LIST", nSpawnID);
    if (sNodeList == "" || sNodeList == "****") return;

    // PHASE 3: MOVEMENT EXECUTION
    if (GetCurrentAction(oSelf) == ACTION_INVALID) {
        int nTargetNodeID = GetNextNodeInList(sNodeList, nCurrentStep);
        
        // Loop Handling
        if (nTargetNodeID == -1) {
            nCurrentStep = 0;
            nTargetNodeID = GetNextNodeInList(sNodeList, 0);
            SetLocalInt(oSelf, "DOWE_PATROL_STEP", 0);
        }

        // Coordinate Conversion
        float fX = StringToFloat(Get2DAString(sWalk2DA, "POS_X", nTargetNodeID));
        float fY = StringToFloat(Get2DAString(sWalk2DA, "POS_Y", nTargetNodeID));
        float fZ = StringToFloat(Get2DAString(sWalk2DA, "POS_Z", nTargetNodeID));
        location lTarget = Location(oArea, Vector(fX, fY, fZ), 0.0);

        // Advance and Move
        SetLocalInt(oSelf, "DOWE_PATROL_STEP", nCurrentStep + 1);
        AssignCommand(oSelf, ActionForceMoveToLocation(lTarget, FALSE, 15.0));
        
        if(bDebug) SendMessageToPC(GetFirstPC(), "DEBUG: [GPS AI] " + GetTag(oSelf) + " moving to Node " + IntToString(nTargetNodeID));
    }
}
