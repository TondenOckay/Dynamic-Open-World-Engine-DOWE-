// =============================================================================
// LNS ENGINE: area_manager (Version 7.0 - FULL ANNOTATED MASTER)
// Logic: Manifest-Based Radar, Phased Staggering, & Resource Janitor
// Standard: 350+ Lines (Professional Vertical Breathing & Full Debug Tracers)
// =============================================================================

/*
    CHANGE LOG:
    - [2026-02-07] RESTORED: Logical Top-to-Bottom Flow (Phases 5 -> 4 -> 3 -> Main).
    - [2026-02-07] RESTORED: Extensive white-space for high-readability.
    - [2026-02-07] FIXED: Corrected corrupted main entry and nested bracket errors.
    - [2026-02-07] OPTIMIZED: Phased Radar Pulse logic to use MCT Manifest.
    - [2026-02-07] INTEGRATED: Version 7.0 area_debug_inc / RunDebug Handshake.
    - [2026-02-08] INTEGRATED: Area_Mud_NPC v2.0 Static World Setup (Phase 3.3).
    - [2026-02-08] INTEGRATED: Phase 6.0 Resource Janitor (4-Min Node Respawn).
*/

#include "area_mct"
#include "nw_i0_generic"
#include "area_debug_inc"
#include "area_mud_inc"


// =============================================================================
// --- PHASE 6: THE RESOURCE JANITOR (NODE RESPAWN) ---
// =============================================================================


/** * AM_Pulse_ResourceJanitor:
 * Scans the area for culled (vanished) resource nodes.
 * Uses a staggered tick system to handle the 4-minute respawn window.
 */
void AM_Pulse_ResourceJanitor(object oArea)
{
    // --- PHASE 6.1: THE KILL-SWITCH ---
    int nVIPCount = GetLocalInt(oArea, "DSE_VIP_COUNT");

    // If no players are here, we kill the janitor loop to save CPU.
    if (nVIPCount <= 0)
    {
        SetLocalInt(oArea, "JANITOR_ACTIVE", FALSE);
        return;
    }


    // --- PHASE 6.2: SCANNING CULLED OBJECTS ---
    // We scan for items marked with the IS_CULLED flag (from the Crafting Engine).
    object oNode = GetFirstObjectInArea(oArea);

    while (GetIsObjectValid(oNode))
    {
        if (GetLocalInt(oNode, "IS_CULLED"))
        {
            int nTicks = GetLocalInt(oNode, "RESPAWN_TICKS") + 1;

            // CYCLE LOGIC: Each Pulse = 120s (2m). 2 Ticks = 240s (4m).
            if (nTicks >= 2)
            {
                // Logic: Restore the Node (Un-Cull)
                SetObjectVisualTransform(oNode, OBJECT_VISUAL_TRANSFORM_SCALE, 1.0);

                // Cleanup variables for the next harvesting cycle
                DeleteLocalInt(oNode, "IS_CULLED");
                DeleteLocalInt(oNode, "NODE_RES_COUNT");
                DeleteLocalInt(oNode, "RESPAWN_TICKS");

                if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
                {
                    SendMessageToPC(GetFirstPC(), "[JANITOR] Resource Respawn: " + GetTag(oNode));
                }
            }
            else
            {
                // Increment tick count and wait for the next 2-minute pulse.
                SetLocalInt(oNode, "RESPAWN_TICKS", nTicks);
            }
        }
        oNode = GetNextObjectInArea(oArea);
    }


    // --- PHASE 6.3: RESCHEDULE ---
    // Janitor Heartbeat: 120.0 seconds (2 Minutes).
    DelayCommand(120.0, AM_Pulse_ResourceJanitor(oArea));
}


// =============================================================================
// --- PHASE 5: THE RADAR PULSE (THE ACTION) ---
// =============================================================================


/** * AM_Pulse_AIRadar:
 * The "Manual NWNX" Radar.
 * Runs every 6 seconds to wake up hibernating monsters near players.
 * Uses the MCT Manifest to avoid expensive area-wide object scans.
 */
void AM_Pulse_AIRadar(object oArea)
{
    // --- PHASE 5.1: THE KILL-SWITCH ---
    int nVIPCount = GetLocalInt(oArea, "DSE_VIP_COUNT");
    int nMobCount = GetLocalInt(oArea, "MCT_REG_COUNT");


    if (nVIPCount <= 0 || nMobCount <= 0)
    {
        SetLocalInt(oArea, "RADAR_ACTIVE", FALSE);

        if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
        {
            SendMessageToPC(GetFirstPC(), "RADAR: Kill-Switch Engaged (Area Empty).");
        }

        return;
    }


    // --- PHASE 5.2: MANIFEST PROCESSING ---
    int m;
    for (m = 1; m <= nMobCount; m++)
    {
        string sMobKey = "MCT_REG_OBJ_" + IntToString(m);
        object oMob = GetLocalObject(oArea, sMobKey);


        if (GetIsObjectValid(oMob) && GetLocalInt(oMob, "DSE_AI_HIBERNATE"))
        {
            // --- PHASE 5.3: VIP PROXIMITY CHECK ---
            int v;
            for (v = 1; v <= nVIPCount; v++)
            {
                object oPC = GetLocalObject(oArea, "DSE_VIP_" + IntToString(v));

                if (GetIsObjectValid(oPC))
                {
                    float fDist = GetDistanceBetween(oMob, oPC);

                    // WAKE-UP RADIUS: 15.0 Meters
                    if (fDist > 0.0 && fDist <= 15.0)
                    {
                        DeleteLocalInt(oMob, "DSE_AI_HIBERNATE");
                        AssignCommand(oMob, ActionDoCommand(DetermineCombatRound(oPC)));


                        if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
                        {
                            SendMessageToPC(GetFirstPC(), "RADAR: Waking " + GetName(oMob));
                        }

                        break;
                    }
                }
            }
        }
    }


    // --- PHASE 5.4: RESCHEDULE ---
    DelayCommand(6.0, AM_Pulse_AIRadar(oArea));
}


// =============================================================================
// --- PHASE 4: VIP REMOVAL (THE CLEANUP) ---
// =============================================================================


void AM_RemoveVIP(object oVIP, object oArea)
{
    int nVIPCount = GetLocalInt(oArea, "DSE_VIP_COUNT") - 1;

    if (nVIPCount < 0) nVIPCount = 0;
    SetLocalInt(oArea, "DSE_VIP_COUNT", nVIPCount);

    MCT_CleanRegistry(oArea);
    SetLocalInt(oVIP, "DSE_IS_BUSY", FALSE);

    if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
    {
        SendMessageToPC(GetFirstPC(), "VIP EXIT: " + GetName(oVIP));
    }
}


// =============================================================================
// --- PHASE 3: VIP INITIALIZATION (THE SETUP) ---
// =============================================================================


void AM_InitializeVIP(object oVIP, object oArea)
{
    int nVIPCount = GetLocalInt(oArea, "DSE_VIP_COUNT") + 1;
    SetLocalInt(oArea, "DSE_VIP_COUNT", nVIPCount);

    string sSlot = "DSE_VIP_" + IntToString(nVIPCount);
    SetLocalObject(oArea, sSlot, oVIP);
    SetLocalInt(oVIP, "DSE_IS_BUSY", FALSE);


    if (GetIsPC(oVIP))
    {
        ExecuteScript("area_lns", oVIP);
    }


    // --- PHASE 3.1: ENGINE CONTROL (DSE BRAIN) ---
    if (GetLocalInt(oArea, "DSE_ACTIVE") == FALSE)
    {
        SetLocalInt(oArea, "DSE_ACTIVE", TRUE);
        float fStagger = 20.0 + IntToFloat(Random(26));
        DelayCommand(fStagger, ExecuteScript("area_dse", oArea));
    }


    // --- PHASE 3.2: RADAR & JANITOR CONTROL ---
    if (GetLocalInt(oArea, "RADAR_ACTIVE") == FALSE)
    {
        SetLocalInt(oArea, "RADAR_ACTIVE", TRUE);
        DelayCommand(6.0, AM_Pulse_AIRadar(oArea));
    }

    if (GetLocalInt(oArea, "JANITOR_ACTIVE") == FALSE)
    {
        SetLocalInt(oArea, "JANITOR_ACTIVE", TRUE);
        // Staggered Start: 10s delay to prevent overlap with Radar start.
        DelayCommand(10.0, AM_Pulse_ResourceJanitor(oArea));
    }


    // --- PHASE 3.3: MUD STATIC WORLD SETUP ---
    if (GetLocalInt(oArea, "MUD_INITIALIZED") == FALSE)
    {
        SetLocalInt(oArea, "MUD_INITIALIZED", TRUE);
        object oWP = GetNearestObjectByTag("WP_MUD_SPAWN", oVIP);

        if (GetIsObjectValid(oWP))
        {
            string sRes = GetLocalString(oWP, "NPC_RESREF");
            string sTag = GetLocalString(oWP, "NPC_TAG");
            MUD_SpawnStaticNPC(sRes, GetLocation(oWP), sTag);
        }
    }
}


// =============================================================================
// --- PHASE 0: MAIN ENTRY POINT (THE ARCHITECT) ---
// =============================================================================


void main()
{
    RunDebug();

    object oArea = OBJECT_SELF;
    object oEntering = GetEnteringObject();
    object oExiting  = GetExitingObject();

    object oTrigger = GetIsObjectValid(oEntering) ? oEntering : oExiting;

    string sTag      = GetTag(oTrigger);
    int bIsPC        = GetIsPC(oTrigger);
    int bIsCompanion = (sTag == "lns_npc_bill" || sTag == "lns_npc_ted");

    if (!bIsPC && !bIsCompanion) return;


    if (GetIsObjectValid(oEntering))
    {
        AM_InitializeVIP(oTrigger, oArea);
    }
    else if (GetIsObjectValid(oExiting))
    {
        AM_RemoveVIP(oTrigger, oArea);
    }
}
