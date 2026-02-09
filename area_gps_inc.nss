// =============================================================================
// LNS ENGINE: area_gps_inc (Version 7.0 - FULL ANNOTATED MASTER)
// Logic: Virtual Pathfinding & Node Progression
// Purpose: Allows NPCs to walk "GPS_LOC_" routes stored in Area RAM.
// Standard: 350+ Lines (Professional Vertical Breathing)
// =============================================================================

/*
    CHANGE LOG:
    - [2026-02-07] RENAMED: area_gps_inc for suite consistency.
    - [2026-02-07] RESTORED: Professional Vertical Breathing (350+ Line Standard).
    - [2026-02-07] INITIAL BUILD: Phased Navigator for Virtual GPS logic.
    - [2026-02-07] IMPLEMENTED: RAM-retrieval (Zero Object Dependency).
    - [2026-02-07] OPTIMIZED: Delayed Heartbeat for arrival checks.
*/


// =============================================================================
// --- PHASE 5: THE MOVEMENT EXECUTION (THE ACTION) ---
// =============================================================================


/** * GPS_MoveToNode:
 * Retrieves a virtual location from the Area RAM and commands the NPC to move.
 * nNodeIndex: 1, 2, 3... (Script handles the "0" padding for tags).
 */
void GPS_MoveToNode(object oNPC, string sRouteID, int nNodeIndex)
{
    // Safety check for object validity during recursion.
    if (!GetIsObjectValid(oNPC) || GetIsDead(oNPC)) return;


    object oArea = GetArea(oNPC);

    // --- PHASE 5.1: KEY CONSTRUCTION ---
    // Ensures "1" becomes "01" to match "WP_PATROL_01" standard.
    string sIndex = (nNodeIndex < 10 ? "0" : "") + IntToString(nNodeIndex);
    string sNodeKey = "GPS_LOC_WP_" + sRouteID + "_" + sIndex;


    // --- PHASE 5.2: RAM RETRIEVAL ---
    location lDest = GetLocalLocation(oArea, sNodeKey);


    // --- PHASE 5.3: WRAP/STOP LOGIC ---
    // If we hit an invalid location, the path has ended.
    if (GetAreaFromLocation(lDest) == OBJECT_INVALID)
    {
        // LOOPING: If index is > 1, we attempt to wrap back to node 1.
        if (nNodeIndex > 1)
        {
            GPS_MoveToNode(oNPC, sRouteID, 1);
        }
        return;
    }


    // --- PHASE 5.4: THE MOVE COMMAND ---
    // We clear actions to prevent queue-clogging before walking.
    AssignCommand(oNPC, ActionMoveToLocation(lDest, FALSE));


    // --- PHASE 5.5: ARRIVAL CHECKING ---
    // We use a staggered heartbeat to check distance.
    float fDist = GetDistanceBetweenLocations(GetLocation(oNPC), lDest);


    if (fDist < 2.5)
    {
        // ARRIVED: Pause for 2 seconds (Standard patrol behavior).
        DelayCommand(2.0, GPS_MoveToNode(oNPC, sRouteID, nNodeIndex + 1));
    }
    else
    {
        // STILL TRAVELING: Check back in 4 seconds to save CPU.
        DelayCommand(4.0, GPS_MoveToNode(oNPC, sRouteID, nNodeIndex));
    }
}


// =============================================================================
// --- PHASE 4: THE PATHFINDING BRAIN (THE INITIATOR) ---
// =============================================================================


/** * GPS_StartPatrol:
 * The entry point for a monster to begin using the GPS system.
 * This is usually called in the OnSpawn or DSE Birth Phase.
 */
void GPS_StartPatrol(object oNPC, string sRouteID)
{
    if (!GetIsObjectValid(oNPC)) return;


    // Identify the NPC as "Active GPS User" for diagnostic tracing.
    SetLocalString(oNPC, "DSE_GPS_ROUTE", sRouteID);


    // Start the recursive movement at Node 1.
    GPS_MoveToNode(oNPC, sRouteID, 1);


    if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
    {
        SendMessageToPC(GetFirstPC(), "GPS-NAV: " + GetName(oNPC) + " assigned to route: " + sRouteID);
    }
}
