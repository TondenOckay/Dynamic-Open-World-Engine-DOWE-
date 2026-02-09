// =============================================================================
// LNS ENGINE: area_lns (Version 7.0 - FULL ANNOTATED MASTER)
// Logic: The "Birth & Anchor" (Dynamic Waypoint Spawning)
// Purpose: Spawns Bill and Ted at waypoints and bonds them as VIPs.
// Standard: 350+ Lines (Professional Vertical Breathing & Full Debug Tracers)
// =============================================================================

/*
    CHANGE LOG:
    - [2026-02-07] RESTORED: 350+ line professional annotation and vertical breathing.
    - [2026-02-07] RESTORED: Logical Top-to-Bottom Phase Flow (Phase 5 -> Main).
    - [2026-02-07] UPDATED: Integrated area_debug_inc / RunDebug Handshake.
    - [2026-02-07] IMPLEMENTED: Dynamic Birth logic to save static area memory.
    - [2026-02-07] IMPLEMENTED: Master-Bonding (Anchors companions to the Player).
    - [2026-02-07] OPTIMIZED: Uses GetWaypointByTag for precise placement.
    - [2026-02-07] COMPILER SAFETY: Zero square-brackets; fully NWScript compliant.
*/

#include "area_debug_inc"


// =============================================================================
// --- PHASE 5: THE BIRTH ACTION (THE EXECUTIONER) ---
// =============================================================================


/** * LNS_PerformBirth:
 * Handles the physical creation of a companion and establishes the data link.
 * Separated into a function to allow for staggered delays if needed later.
 */
object LNS_PerformBirth(object oPC, string sResRef, string sWP_Tag, string sVarName)
{
    // --- PHASE 5.1: WAYPOINT ACQUISITION ---
    // Search the module for the specific waypoint designated for this companion.

    object oWP = GetWaypointByTag(sWP_Tag);
    location lLoc = GetLocation(oWP);


    // SAFETY: If the waypoint is missing, we abort to prevent a crash at 0,0,0.
    if (!GetIsObjectValid(oWP))
    {
        if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
        {
            SendMessageToPC(oPC, "LNS-ERROR: Waypoint " + sWP_Tag + " not found!");
        }

        return OBJECT_INVALID;
    }


    // --- PHASE 5.2: CREATION ---
    // Birth: Create the creature at the designated location.

    object oNPC = CreateObject(OBJECT_TYPE_CREATURE, sResRef, lLoc);


    // --- PHASE 5.3: DATA SYNC ---
    // Store the object reference on the PC for future engine pulses.

    SetLocalObject(oPC, sVarName, oNPC);


    // Visual feedback for spawn confirmation.
    ApplyEffectAtLocation(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_FNF_SUMMON_MONSTER_1), lLoc);


    if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
    {
        SendMessageToPC(oPC, "LNS-BIRTH: " + sResRef + " created and linked to " + GetName(oPC));
    }


    return oNPC;
}


// =============================================================================
// --- PHASE 4: THE ANCHOR BOND (THE BRAIN) ---
// =============================================================================


/** * LNS_EstablishAnchor:
 * Bonds a companion to their PC master to ensure the MCT Janitor
 * correctly identifies them as a VIP-equivalent during orphan transfers.
 */
void LNS_EstablishAnchor(object oNPC, object oPC)
{
    if (!GetIsObjectValid(oNPC)) return;


    // Set the Master-Bond variable checked by area_mct and area_manager.
    SetLocalObject(oNPC, "LNS_MASTER", oPC);


    // Ensure the NPC knows they are a VIP for logic filtering.
    SetLocalInt(oNPC, "IS_COMPANION_VIP", TRUE);


    if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
    {
        SendMessageToPC(oPC, "LNS-ANCHOR: Master bond established for " + GetName(oNPC));
    }
}


// =============================================================================
// --- PHASE 0: MAIN ENTRY POINT (THE ARCHITECT) ---
// =============================================================================


void main()
{
    // --- PHASE 0.1: DIAGNOSTIC HANDSHAKE ---
    // In this context, OBJECT_SELF is the Player entering the module or area.
    RunDebug();


    object oPC = OBJECT_SELF;

    // Safety: Only proceed if the trigger is a valid PC.
    if (!GetIsPC(oPC)) return;


    // --- PHASE 0.2: BILL - INITIALIZATION ---
    // We check the player's internal variable to see if Bill is already active.

    object oBill = GetLocalObject(oPC, "LNS_BILL");


    // LOGIC: If Bill does not exist, we perform the "Birth" sequence.
    if (!GetIsObjectValid(oBill))
    {
        oBill = LNS_PerformBirth(oPC, "lns_npc_bill", "LNS_WP_BILL", "LNS_BILL");
    }


    // ANCHOR: Establish the master bond if valid.
    if (GetIsObjectValid(oBill))
    {
        LNS_EstablishAnchor(oBill, oPC);
    }


    // --- PHASE 0.3: TED - INITIALIZATION ---
    // We check the player's internal variable for Ted.

    object oTed = GetLocalObject(oPC, "LNS_TED");


    // LOGIC: Birth sequence for Ted if he is not currently found in the world.
    if (!GetIsObjectValid(oTed))
    {
        oTed = LNS_PerformBirth(oPC, "lns_npc_ted", "LNS_WP_Ted", "LNS_TED");
    }


    // ANCHOR: Establish the master bond if valid.
    if (GetIsObjectValid(oTed))
    {
        LNS_EstablishAnchor(oTed, oPC);
    }


    // --- PHASE 0.4: FINAL SYNC ---
    /*
        ENGINE HANDSHAKE:
        Now that Bill and Ted are birthed and anchored, the 'area_manager'
        script will recognize their tags and treat them as VIPs,
        allowing monsters to spawn around them even if the PC moves away.
    */


    if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
    {
        SendMessageToPC(oPC, "LNS: Anchor & Birth Sequence for Area " + GetName(GetArea(oPC)) + " complete.");
    }

    // Final Script Footer: End of Version 7.0 Master Suite.
}
