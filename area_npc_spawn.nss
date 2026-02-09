// =============================================================================
// SCRIPT: area_npc_spawn
// Purpose: Individual NPC Initialization and Version 7.0 Debug Handshake.
// Location: Place this in the ON_SPAWN slot of your Monsters/NPCs.
// =============================================================================

#include "nw_i0_generic"
#include "area_debug_inc"

void main()
{
    // -------------------------------------------------------------------------
    // VERSION 7.0 DIAGNOSTIC
    // -------------------------------------------------------------------------
    // This calls the heavy logic to report:
    // 1. Who created this NPC (Encounter vs Script).
    // 2. Which Area they were born in.
    // 3. Current saturation levels.
    // -------------------------------------------------------------------------
    RunDebug();


    // -------------------------------------------------------------------------
    // NATIVE INITIALIZATION
    // -------------------------------------------------------------------------
    // We execute the default NWN spawn logic to ensure Factions,
    // Listening patterns, and AI states are set correctly.
    // -------------------------------------------------------------------------
    ExecuteScript("nw_c2_default9", OBJECT_SELF);


    // -------------------------------------------------------------------------
    // LNS / DSE HANDSHAKE
    // -------------------------------------------------------------------------
    // This is where your Version 1.2 LNS Engine picks up the monster.
    // We stamp a local variable to confirm this mob is now "Managed."
    // -------------------------------------------------------------------------
    SetLocalInt(OBJECT_SELF, "DSE_MANAGED", TRUE);


    // Safety Tracer for the Combat Log
    if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
    {
        SendMessageToPC(GetFirstPC(), "NPC_SPAWN: " + GetTag(OBJECT_SELF) + " is now online.");
    }
}
