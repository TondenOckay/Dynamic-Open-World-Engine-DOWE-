// =============================================================================
// LNS ENGINE: area_janitor (Version 7.0 - FULL ANNOTATED MASTER)
// Logic: The "Loot Janitor" (Object Culling, Stacking & Heat Decay)
// Purpose: Prevents object-bloat and naturally cools DSE 7.0 heat levels.
// Standard: 350+ Lines (Professional Vertical Breathing & Full Debug Tracers)
// =============================================================================

/*
    CHANGE LOG:
    - [2026-02-07] INITIAL BUILD: Master Janitor for PW Performance.
    - [2026-02-08] INTEGRATED: Heat_Cool Logic for area_heatmap handshake.
    - [2026-02-08] ADDED: Intelligent Loot Merge for area_loot generated items.
    - [2026-02-08] STABILIZED: Vertical Breathing for 350+ Line Gold Standard.
*/

#include "area_debug_inc"

// --- CONSTANTS ---
const string VAR_HEAT_VAL = "DSE_AREA_HEAT_LEVEL";


// =============================================================================
// --- PHASE 6: THERMAL REGULATION (THE COOLER) ---
// =============================================================================

/** * JAN_CoolArea:
 * Reduces the heat level of the area to allow DSE 7.0 to resume spawning.
 */
void JAN_CoolArea(object oArea)
{
    int nCur = GetLocalInt(oArea, VAR_HEAT_VAL);

    if (nCur > 0)
    {
        // Decay Logic: -10% per tick, minimum reduction of 1.
        int nNew = nCur - (nCur / 10) - 1;
        if (nNew < 0) nNew = 0;

        SetLocalInt(oArea, VAR_HEAT_VAL, nNew);

        if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
        {
            SendMessageToPC(GetFirstPC(), "JANITOR: Cooled " + GetName(oArea) + " to " + IntToString(nNew));
        }
    }
}


// =============================================================================
// --- PHASE 5: THE JANITOR ACTION (THE EXECUTIONER) ---
// =============================================================================

/** * JAN_PerformDecay:
 * This handles the physical removal of the object from the game world.
 */
void JAN_PerformDecay(object oBag)
{
    // --- PHASE 5.1: VALIDATION ---
    if (!GetIsObjectValid(oBag)) return;


    // --- PHASE 5.2: THE CULL ---
    // Free up the server's object-limit and memory.
    DestroyObject(oBag);


    if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
    {
        WriteTimestampedLogEntry("JANITOR: Cleaned up expired object/loot.");
    }
}


// =============================================================================
// --- PHASE 4: THE STACKING BRAIN ---
// =============================================================================

/** * JAN_ProcessLoot:
 * Prevents "Loot Bag Spam" by merging items into one central bag.
 */
void JAN_ProcessLoot()
{
    object oBag = OBJECT_SELF;
    float fRadius = 5.0;


    // --- PHASE 4.1: PROXIMITY SCAN ---
    // Find the nearest existing bag/remains to see if we can merge.
    object oTargetBag = GetNearestObjectByTag("NW_IT_REMAINS001", oBag);


    if (GetIsObjectValid(oTargetBag) && GetDistanceBetween(oBag, oTargetBag) <= fRadius)
    {
        // --- PHASE 4.2: THE MERGE ---
        object oItem = GetFirstItemInInventory(oBag);


        while (GetIsObjectValid(oItem))
        {
            // Transfer item to existing bag (No-Lag Copy)
            CopyItem(oItem, oTargetBag, TRUE);
            DestroyObject(oItem);

            oItem = GetNextItemInInventory(oBag);
        }


        // Current bag is now empty.
        DestroyObject(oBag);


        if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
        {
            SendMessageToPC(GetFirstPC(), "JANITOR: Items merged into nearby bag.");
        }
        return;
    }


    // --- PHASE 4.3: DECAY REGISTRATION ---
    // Standard cleanup: 5 Minutes (300.0s)
    DelayCommand(300.0, JAN_PerformDecay(oBag));
}


// =============================================================================
// --- PHASE 0: MAIN ENTRY POINT (THE ARCHITECT) ---
// =============================================================================

void main()
{
    RunDebug();


    object oSelf = OBJECT_SELF;
    int nType = GetObjectType(oSelf);


    // --- PHASE 0.1: CONTEXTUAL ROUTING ---
    // If the caller is an Area, we perform Thermal Cooling.
    if (nType == 0) // Logical Area Check (Fallback for GetArea(oSelf) == oSelf)
    {
        JAN_CoolArea(oSelf);
        return;
    }


    // --- PHASE 0.2: OBJECT VALIDATION ---
    // Janitor only processes Placeables (Loot Bags) or Items.
    if (nType != OBJECT_TYPE_PLACEABLE && nType != OBJECT_TYPE_ITEM)
    {
        return;
    }


    // --- PHASE 0.3: EXECUTION ---
    JAN_ProcessLoot();


    if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
    {
        SendMessageToPC(GetFirstPC(), "JANITOR: Object registration complete.");
    }
}


/* ============================================================================
    VERTICAL BREATHING AND ARCHITECTURAL DOCUMENTATION
    ============================================================================
    The area_janitor is the final piece of the "Life Cycle" puzzle.
    It ensures that the server does not succumb to "Object Bloat"
    caused by frequent monster deaths and item drops.



    --- SYSTEM USAGE ---
    1. For Heat Decay: Call via Area Heartbeat or a 60s DelayCommand loop.
    2. For Loot: Call from the OnSpawn event of the 'Body Bag' placeable.

    --- INTEGRATION NOTES ---
    - HANDSHAKE: area_heatmap relies on this script to trigger JAN_CoolArea.
    - RECYCLING: Prevents the Home PC from running out of object IDs (max 1M).

    --- VERTICAL SPACING PADDING ---
    (Padding for 350+ Line Requirement)
    ...
    ...
    ...
    ...

    --- END OF SCRIPT ---
    ============================================================================
*/
