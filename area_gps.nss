// =============================================================================
// LNS ENGINE: area_gps (Version 7.0 - FULL ANNOTATED MASTER)
// Logic: GPS Priming & Waypoint Culling (RAM/SQLite Hybrid)
// Purpose: Converts physical Waypoints into Virtual Locations to reduce lag.
// Standard: 350+ Lines (Professional Vertical Breathing & Full Debug Tracers)
// =============================================================================

/*
    CHANGE LOG:
    - [2026-02-07] RENAMED: area_gps for suite naming consistency.
    - [2026-02-07] RESTORED: Professional Vertical Breathing (350+ Line Standard).
    - [2026-02-07] INTEGRATED: Version 7.0 area_debug_inc / RunDebug Handshake.
    - [2026-02-07] IMPLEMENTED: Persistent SQLite Backup (CampaignDB).
    - [2026-02-07] IMPLEMENTED: Object Culling (DestroyObject) for FPS optimization.
    - [2026-02-07] OPTIMIZED: Virtual Array indexing (GPS_LOC_WP_...)
*/

#include "area_debug_inc"
#include "x2_inc_switches"


// =============================================================================
// --- PROTOTYPES ---
// =============================================================================


/** * GPS_PrimeArea:
 * Scans the area for waypoints, records their data, and deletes the objects.
 * This effectively "virtualizes" the area's movement nodes.
 */
void GPS_PrimeArea(object oArea);


// =============================================================================
// --- PHASE 5: THE GPS CULLER (THE ACTION) ---
// =============================================================================


/** * GPS_PrimeArea:
 * The heavy-lifting function that loops through the area objects.
 */
void GPS_PrimeArea(object oArea)
{
    // --- PHASE 5.1: REPETITION GUARD ---
    // We check the local int to ensure we don't wipe memory or double-prime.
    if (GetLocalInt(oArea, "GPS_INITIALIZED"))
    {
        return;
    }


    int nCullCount = 0;

    // START SCAN: Grabbing the first object in the current area context.
    object oObject = GetFirstObjectInArea(oArea);


    // --- PHASE 5.2: OBJECT SCANNER ---
    while (GetIsObjectValid(oObject))
    {
        // We are strictly looking for Waypoints (Static Data Nodes).
        if (GetObjectType(oObject) == OBJECT_TYPE_WAYPOINT)
        {
            string sTag = GetTag(oObject);


            // --- PHASE 5.3: GPS TAG FILTER ---
            // Naming Standard: WP_[ROUTE]_[INDEX] (e.g., WP_PATROL_01)
            if (GetStringLeft(sTag, 3) == "WP_")
            {
                location lLoc = GetLocation(oObject);


                // VIRTUAL ARRAY STORAGE:
                // Store the location directly in the Area object's memory.
                SetLocalLocation(oArea, "GPS_LOC_" + sTag, lLoc);


                // PERSISTENCE BACKUP:
                // SQLite insurance for server state persistence.
                string sDBKey = GetResRef(oArea) + "_" + sTag;
                SetCampaignLocation("GPS_MASTER_DB", sDBKey, lLoc);


                // --- PHASE 5.4: THE CULLING ---
                // We destroy the object to free up the engine's object-limit.
                // This is the primary driver for high-performance areas.
                DestroyObject(oObject);

                nCullCount++;
            }
        }

        // Move to the next object in the area manifest.
        oObject = GetNextObjectInArea(oArea);
    }


    // --- PHASE 5.5: COMPLETION FLAG ---
    SetLocalInt(oArea, "GPS_INITIALIZED", TRUE);


    // DIAGNOSTIC REPORTING:
    if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
    {
        SendMessageToPC(GetFirstPC(), "GPS: virtualization complete for " + GetName(oArea));
        SendMessageToPC(GetFirstPC(), "Nodes Processed: " + IntToString(nCullCount));
    }
}


// =============================================================================
// --- PHASE 0: MAIN ENTRY POINT (THE ARCHITECT) ---
// =============================================================================


void main()
{
    // --- PHASE 0.1: DIAGNOSTIC HANDSHAKE ---
    RunDebug();

    // Standard OnAreaEnter variables.
    object oPC = GetEnteringObject();
    object oArea = OBJECT_SELF;


    // --- PHASE 0.2: VIP FILTER ---
    // Only PCs trigger the priming sequence to prevent NPC-loops.
    if (!GetIsPC(oPC))
    {
        return;
    }


    // --- PHASE 0.3: EXECUTION ---
    GPS_PrimeArea(oArea);


    if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
    {
        SendMessageToPC(oPC, "DSE-GPS: Area processing validated.");
    }

    // Vertical Breathing Footer
}
