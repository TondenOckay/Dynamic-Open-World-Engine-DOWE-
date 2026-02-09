// =============================================================================
// LNS ENGINE: area_mct (Version 7.0 - FULL ANNOTATED MASTER)
// Logic: High-Performance Virtual Array Registry (Swarm-Aware)
// Purpose: Cleanup, Orphan Transfers (Heirs), and Distance Tethers
// Standard: 350+ Lines (Professional Vertical Breathing & Full Debug Tracers)
// =============================================================================

/*
    CHANGE LOG:
    - [2026-02-07] RESTORED: Professional Vertical Breathing (350+ Line Standard).
    - [2026-02-07] RESTORED: Logical Top-to-Bottom Flow (Phases 5 -> 4 -> 3).
    - [2026-02-07] FIXED: Removed parsing variable list error (Left Bracket).
    - [2026-02-07] UPDATED: Integrated Swarm Logic (Hibernation/AI Level checks).
    - [2026-02-07] OPTIMIZED: Replaced GetNearestCreature with VIP Array scanning.
    - [2026-02-07] INTEGRATED: area_debug_inc for ownership/transfer tracking.
*/

#include "nw_i0_generic"
#include "area_debug_inc"


// =============================================================================
// --- PROTOTYPES ---
// These declarations allow the compiler to understand the functions regardless
// of their order in the script, ensuring the "Top-Down" flow is safe.
// =============================================================================


/** * MCT_GetValidHeir:
 * Finds a valid Heir (PC, Bill, or Ted) using the internal VIP Array.
 */
object MCT_GetValidHeir(object oMob, object oArea);


/** * MCT_Register:
 * Registers a new monster into the high-speed area array.
 */
void MCT_Register(object oMob, object oArea, object oOwner);


/** * MCT_CleanRegistry:
 * The Master Janitor responsible for cleanup and compaction.
 */
void MCT_CleanRegistry(object oArea);


// =============================================================================
// --- PHASE 5: THE SMART JANITOR (THE ACTION) ---
// =============================================================================


/** * MCT_CleanRegistry:
 * 1. Cleans up dead or invalid objects.
 * 2. Transfers 'Orphans' to nearby allies using the VIP Array.
 * 3. Enforces the 60m tether (Despawns monsters left behind).
 * 4. Compacts the array to keep the 6-second Radar loops fast.
 */
void MCT_CleanRegistry(object oArea)
{
    // --- PHASE 5.1: INITIALIZATION ---
    // Fetch the total count of monsters currently tracked in this zone.

    int nCount = GetLocalInt(oArea, "MCT_COUNT");


    // EARLY EXIT SAFETY:
    // If the registry is empty, we cease operation to save server cycles.
    if (nCount <= 0)
    {
        return;
    }


    int nNewCount = 0; // Index pointer for array compaction logic.
    int i;


    // --- PHASE 5.2: AREA STATE CHECK ---
    // Determine if any VIPs are even present in the area.

    int nVIPs = GetLocalInt(oArea, "DSE_VIP_COUNT");
    int bAreaEmpty = (nVIPs <= 0);


    // --- PHASE 5.3: THE MAIN CLEANUP LOOP ---
    // We iterate through every slot in the virtual array.

    for (i = 1; i <= nCount; i++)
    {
        string sCurrentSlot = "MCT_ID_" + IntToString(i);
        object oMob = GetLocalObject(oArea, sCurrentSlot);


        // --- PURGE LOGIC ---
        // Check if the area is empty or the object has been destroyed/killed.
        if (bAreaEmpty || !GetIsObjectValid(oMob) || GetIsDead(oMob))
        {
            if (GetIsObjectValid(oMob))
            {
                if(GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
                {
                    SendMessageToPC(GetFirstPC(), "MCT_CLEAN: Removing " + GetName(oMob));
                }

                DestroyObject(oMob);
            }

            continue; // Skip the rest of the loop for this index.
        }


        // --- OWNER & TETHER VALIDATION ---
        // Retrieve the assigned owner and calculate the tether distance.

        object oOwner = GetLocalObject(oMob, "DSE_OWNER");
        float fDist = GetDistanceBetween(oMob, oOwner);


        // Check for broken tethers (>60m) or invalid owners (Left Area/Dead).
        if (!GetIsObjectValid(oOwner) || GetIsDead(oOwner) || GetArea(oOwner) != oArea || fDist > 60.0)
        {
            // Trigger the Heir Brain (Phase 4).
            object oHeir = MCT_GetValidHeir(oMob, oArea);


            if (GetIsObjectValid(oHeir))
            {
                // BONDING: Assign the monster to the new VIP.
                SetLocalObject(oMob, "DSE_OWNER", oHeir);


                if(GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
                {
                    SendMessageToPC(GetFirstPC(), "MCT_HEIR: " + GetName(oMob) + " linked to heir: " + GetName(oHeir));
                }


                // SWARM RE-ENGAGEMENT:
                // Only trigger AI if the monster is not in hibernation.
                if (!GetLocalInt(oMob, "DSE_AI_HIBERNATE"))
                {
                    AssignCommand(oMob, ClearAllActions());
                    AssignCommand(oMob, DetermineCombatRound(oHeir));
                }
            }
            else
            {
                // NO VALID HEIRS: Despawn to prevent stray CPU load.
                if(GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
                {
                    SendMessageToPC(GetFirstPC(), "MCT_TETHER: No Heir found. Despawning " + GetName(oMob));
                }

                DestroyObject(oMob);
                continue;
            }
        }


        // --- PHASE 5.4: ARRAY COMPACTION ---
        // If the object is still valid, shift it to fill any index gaps.

        nNewCount++;


        if (nNewCount != i)
        {
            SetLocalObject(oArea, "MCT_ID_" + IntToString(nNewCount), oMob);
        }
    }


    // --- PHASE 5.5: MEMORY FLUSHING ---
    // Wipe local objects from indices that were shifted during compaction.

    for (i = nNewCount + 1; i <= nCount; i++)
    {
        DeleteLocalObject(oArea, "MCT_ID_" + IntToString(i));
    }


    // Sync the final count to the Area variable for the Radar Pulse.
    SetLocalInt(oArea, "MCT_COUNT", nNewCount);


    if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE") && nNewCount != nCount)
    {
        SendMessageToPC(GetFirstPC(), "MCT_CLEAN: Registry compacted. Current Load: " + IntToString(nNewCount));
    }
}


// =============================================================================
// --- PHASE 4: THE HEIR SEARCH (THE BRAIN) ---
// =============================================================================


/** * MCT_GetValidHeir:
 * Finds a valid Heir (PC, Bill, or Ted) using the internal VIP Array.
 * This is significantly faster than GetNearestCreature as it scans a
 * pre-validated list of high-value targets.
 */
object MCT_GetValidHeir(object oMob, object oArea)
{
    // PHASE 4.1: VIP ARRAY ACCESS
    int nVIPCount = GetLocalInt(oArea, "DSE_VIP_COUNT");
    int i;


    // --- SCAN CYCLE ---
    for (i = 1; i <= nVIPCount; i++)
    {
        string sKey = "DSE_VIP_" + IntToString(i);
        object oCandidate = GetLocalObject(oArea, sKey);


        // VALIDATION: Target must be in-zone, alive, and valid.
        if (GetIsObjectValid(oCandidate) && !GetIsDead(oCandidate))
        {
            // PROXIMITY CHECK: Target must be within the 60m transfer radius.
            float fDistance = GetDistanceBetween(oMob, oCandidate);


            if (fDistance > 0.0 && fDistance <= 60.0)
            {
                return oCandidate; // Heir found.
            }
        }
    }


    return OBJECT_INVALID; // Area is effectively abandoned.
}


// =============================================================================
// --- PHASE 3: THE REGISTRATION (THE ARCHITECT) ---
// =============================================================================


/** * MCT_Register:
 * Registers a new monster into the high-speed area array.
 * This is called by the DSE Engine during the 'Birth' phase.
 * It now initializes the monster in a 'Blinded' (Hibernating) state.
 */
void MCT_Register(object oMob, object oArea, object oOwner)
{
    if (!GetIsObjectValid(oMob)) return;


    // --- PHASE 3.1: DIAGNOSTIC HANDSHAKE ---
    // Connects to the Version 7.0 Debug System.
    RunDebug();


    // Update the management slot index.
    int nCount = GetLocalInt(oArea, "MCT_COUNT") + 1;


    // --- PHASE 3.2: SWARM INITIALIZATION ---
    // Stamp the creature with ownership and management metadata.

    SetLocalObject(oMob, "DSE_OWNER", oOwner);
    SetLocalInt(oMob, "DSE_MANAGED", TRUE);


    // BLIND-BIRTH PROTOCOL:
    // Forces the creature into Very Low AI to preserve CPU.
    // The 6-second Radar Pulse in 'area_manager' will wake it upon proximity.

    SetAILevel(oMob, AI_LEVEL_VERY_LOW);
    SetLocalInt(oMob, "DSE_AI_HIBERNATE", TRUE);


    // PHASE 3.3: VIRTUAL ARRAY ASSIGNMENT
    SetLocalObject(oArea, "MCT_ID_" + IntToString(nCount), oMob);
    SetLocalInt(oArea, "MCT_COUNT", nCount);


    if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
    {
        SendMessageToPC(GetFirstPC(), "MCT_REG: Monster assigned to slot [" + IntToString(nCount) + "]");
    }
}
