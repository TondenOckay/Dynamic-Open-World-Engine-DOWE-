// =============================================================================
// AREA ON_ENTER: INITIALIZER
// Purpose: Triggers the Master Area Manager when a Player enters the zone.
// =============================================================================

#include "area_debug_inc"

// --- MASTER ENGINE TOGGLES (1 = ON, 0 = OFF) ---
int TOGGLE_DEBUG   = 1;
int TOGGLE_LNS     = 1;
int TOGGLE_HOTMAP  = 1;

void main()
{
    // --- VERSION 7.0 HEAVY LOGIC ---
    // Wrapped in the toggle so you can turn off the "Heavy Logic" diagnostic.
    if (TOGGLE_DEBUG == 1)
    {
        RunDebug();
    }

    object oPC = GetEnteringObject();
    object oArea = OBJECT_SELF;

    // Only proceed if the entering object is a real Player.
    if (!GetIsPC(oPC) || GetIsDM(oPC))
    {
        return;
    }

    // -------------------------------------------------------------------------
    // HANDSHAKE: MASTER AREA MANAGER
    // -------------------------------------------------------------------------

    // Only fire the Area Manager (DSE/LNS) if the toggle is ON.
    if (TOGGLE_LNS == 1)
    {
        ExecuteScript("area_manager", oArea);
    }

    // Fire the Hotmap system only if the toggle is ON.
    if (TOGGLE_HOTMAP == 1)
    {
        ExecuteScript("area_hotmap", oArea);
    }
}
