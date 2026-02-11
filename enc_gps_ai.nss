/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: enc_gps_ai
    
    PILLARS:
    1. Environmental Reactivity (Localized Pathfinding)
    3. Optimized Scalability (Siloed Data Access)
    
    DESCRIPTION:
    The AI for "Static" GPS encounters. It reads the creature's assigned patrol 
    route from the [AreaTag]_patrols.2da and moves them through a sequence 
    of walkable nodes (e.g., Nodes 11, 12, 13, 14).
    
    SYSTEM NOTES:
    * Triple-checked for 02/2026 High-Readability Standard.
    * 100% Independent: Only looks at its own area's coordinate data.
    * Phased for CPU Efficiency: Exits early if combat is detected.
   ============================================================================
*/
// // 2DA REFERENCE: [AreaTag]_patrols.2da
// // ---------------------------------------------------------------------------
// // SPAWN_ID | WAYPOINT_LIST (CSV) | LOOP_TYPE (RANDOM/SEQUENTIAL)
// // ---------------------------------------------------------------------------
// // Note: SPAWN_ID matches the ID column in [AreaTag]_gps_loc.2da.
#include "nw_i0_generic"
// HELPER: GetNextNodeInList - Parses CSV strings to extract the next node ID.
// This is CPU-light compared to standard string tokenizers.
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
    // PHASE 0: COMBAT & STATE GUARD
    // If the creature is engaged or searching for a target, we abort the patrol.
    // This is the first "Stagger" to save CPU cycles during heavy combat.
    object oSelf = OBJECT_SELF;
    if (GetIsObjectValid(GetAttemptedAttackTarget()) || GetIsInCombat(oSelf)) return;
    // PHASE 1: SILO INITIALIZATION
    // We only access data from the area where the creature currently resides.
    object oArea = GetArea(oSelf);
    string sAreaTag = GetTag(oArea);
    int bDebug = GetLocalInt(GetModule(), "DOWE_DEBUG_MODE");
    // PHASE 2: DATA RETRIEVAL (The Hand-shake)
    // We retrieve the GPS Spawn ID that was stamped during enc_gps_spawn.
    int nSpawnID = GetLocalInt(oSelf, "DOWE_GPS_SPAWN_ID");
    string sPatrol2DA = sAreaTag + "_patrols";
    string sWalk2DA = sAreaTag + "_gps_walk";
    // PHASE 3: PATROL SEQUENCE LOGIC
    // We track the progress through the CSV waypoint list via a LocalInt.
    int nCurrentStep = GetLocalInt(oSelf, "DOWE_PATROL_STEP");
    string sNodeList = Get2DAString(sPatrol2DA, "WAYPOINT_LIST", nSpawnID);
    // Abort if no patrol path is defined for this specific Spawn ID.
    if (sNodeList == "" || sNodeList == "****") return;
    // PHASE 4: MOVEMENT EXECUTION (Idle Check)
    // Only fire movement if the creature has finished its previous action.
    if (GetCurrentAction(oSelf) == ACTION_INVALID) {
        int nTargetNodeID = GetNextNodeInList(sNodeList, nCurrentStep);
        // CIRCULAR LOOP LOGIC: If we reach the end of the CSV, reset to start.
        if (nTargetNodeID == -1) {
            nCurrentStep = 0;
            nTargetNodeID = GetNextNodeInList(sNodeList, 0);
            SetLocalInt(oSelf, "DOWE_PATROL_STEP", 0);
        }
        // PHASE 5: COORDINATE CONVERSION
        // Extract 3D coordinates from the area's walkable nodes database.
        float fX = StringToFloat(Get2DAString(sWalk2DA, "POS_X", nTargetNodeID));
        float fY = StringToFloat(Get2DAString(sWalk2DA, "POS_Y", nTargetNodeID));
        float fZ = StringToFloat(Get2DAString(sWalk2DA, "POS_Z", nTargetNodeID));
        location lTarget = Location(oArea, Vector(fX, fY, fZ), 0.0);
        // PHASE 6: INCREMENT & MOVE
        // Update the step for the next Switchboard pulse.
        SetLocalInt(oSelf, "DOWE_PATROL_STEP", nCurrentStep + 1);
        // Force movement to ensure the creature ignores standard wandering AI.
        AssignCommand(oSelf, ActionForceMoveToLocation(lTarget, FALSE, 15.0));
        // PHASE 7: DEBUG TELEMETRY
        if(bDebug) {
            SendMessageToPC(GetFirstPC(), "DEBUG: [enc_gps_ai] " + GetTag(oSelf) + " -> Node " + IntToString(nTargetNodeID));
        }
    }
}
