// =============================================================================
// DSE ENGINE: area_dse (Version 7.0 - FULL ANNOTATED MASTER)
// Logic: High-Level Population Architect (Phased & Staggered)
// Purpose: Material-Aware PC Optimization with Heatmap CPU Throttling
// Standard: 350+ Lines (Professional Vertical Breathing & Full Debug Tracers)
// =============================================================================

/*
    CHANGE LOG:
    - [2026-02-07] FIXED: Duplicate main error by using area_enc_inc (Cleaned).
    - [2026-02-07] INTEGRATED: Material-based 2DA lookup via ENC_ handshake.
    - [2026-02-08] INTEGRATED: area_heatmap Throttling (CPU Load Flattening).
    - [2026-02-08] INTEGRATED: Phase 7 Loot Handshake (area_loot).
    - [2026-02-08] INTEGRATED: area_boss_logic Handshake for Rare Tier spawns.
    - [2026-02-08] RESTORED: Full 350+ Line Vertical Breathing and Documentation.
*/

#include "nw_i0_generic"
#include "area_mct"       // Swarm Registry (MCT_Register / MCT_Clean)
#include "area_debug_inc"   // Master Debugger
#include "area_enc_inc"     // New Library Handshake (Ensure main() is removed from library)


// --- CONSTANTS ---
const string VAR_HEAT_VAL = "DSE_AREA_HEAT_LEVEL";


// =============================================================================
// --- PHASE 7: POST-MORTEM (The Inheritance) ---
// =============================================================================

/** * DSE_Phase7_TriggerLoot:
 * Executed via OnDeath hook. Signals area_loot to roll from 2DAs.
 */
void DSE_Phase7_TriggerLoot(object oKilled)
{
    // --- PHASE 7.1: TIER RETRIEVAL ---
    // Pull the tier assigned during the Birth Action (Phase 5).
    int nTier = GetLocalInt(oKilled, "DSE_LOOT_TIER");


    if (nTier > 0)
    {
        // --- PHASE 7.2: LOOT HANDSHAKE ---
        // We set the target table ID on the corpse itself.
        SetLocalInt(oKilled, "LOOT_TABLE_TO_ROLL", nTier);


        // Execute the master loot script (Alpha-architecture: area_loot)
        ExecuteScript("area_loot", oKilled);


        if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
        {
            SendMessageToPC(GetFirstPC(), "DSE DEATH: Tier " + IntToString(nTier) + " dropped for " + GetName(oKilled));
        }
    }
}


// =============================================================================
// --- PHASE 6: PERFORMANCE UTILS (The Governor) ---
// =============================================================================

/** * DSE_GetHeatMultiplier:
 * Queries the area_heatmap data to determine spawn density.
 */
float DSE_GetHeatMultiplier(object oArea)
{
    int nHeat = GetLocalInt(oArea, VAR_HEAT_VAL);


    // CRITICAL HEAT: Emergency shutdown to save Home PC thread.
    if (nHeat > 100)
    {
        return 0.0;
    }


    // HIGH HEAT: Throttling spawns by 50%
    if (nHeat > 50)
    {
        return 0.5;
    }


    // OPTIMAL HEAT: Standard flow
    return 1.0;
}


// =============================================================================
// --- PHASE 5: THE BIRTH ACTION (The Executioner) ---
// =============================================================================

void DSE_Phase5_DoSpawn(object oPC, object oArea, string sResRef, int nSlot, string sSuffix)
{
    if (!GetIsObjectValid(oPC) || GetIsDead(oPC) || GetArea(oPC) != oArea)
    {
        return;
    }


    // --- PHASE 5.1: POSITION CALCULATION ---
    vector vPos = GetPosition(oPC);
    vPos.x += (Random(13) - 6.0);
    vPos.y += (Random(13) - 6.0);
    location lLoc = Location(oArea, vPos, 0.0);


    // --- PHASE 5.2: OBJECT CREATION ---
    object oMob = CreateObject(OBJECT_TYPE_CREATURE, sResRef, lLoc);


    // --- PHASE 5.3: BOSS HANDSHAKE (THE CROWN) ---
    // If the library roll was Rare, we transform the creature into a Boss.
    if (sSuffix == "_rare")
    {
        ExecuteScript("area_boss_logic", oMob);
    }


    // --- PHASE 5.4: HIBERNATION SETUP ---
    // Set AI to low until player engagement to save cycles.
    SetAILevel(oMob, AI_LEVEL_VERY_LOW);
    SetLocalInt(oMob, "DSE_AI_HIBERNATE", TRUE);


    // --- PHASE 5.5: TIER ASSIGNMENT ---
    // Logic: Assigns a Loot Tier (1-10) based on monster power.
    int nHD = GetHitDice(oMob);
    int nTier = 1;


    if (nHD > 20 || sSuffix == "_rare")
    {
        nTier = 10; // Boss/Epic/Rare
    }
    else if (nHD > 12)
    {
        nTier = 5;  // Elite
    }
    else if (nHD > 5)
    {
        nTier = 2;  // Standard
    }
    else
    {
        nTier = 1;  // Fodder
    }


    SetLocalInt(oMob, "DSE_LOOT_TIER", nTier);


    // --- PHASE 5.6: REGISTRY HANDSHAKE ---
    MCT_Register(oMob, oArea, oPC);
    SetLocalObject(oPC, "DSE_MOB_" + IntToString(nSlot), oMob);


    ApplyEffectAtLocation(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_UNSUMMON), lLoc);


    if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
    {
        SendMessageToPC(GetFirstPC(), "DSE BIRTH: " + sResRef + " [" + sSuffix + "]");
    }
}


// =============================================================================
// --- PHASE 4: ENCOUNTER SELECTION (The Brain) ---
// =============================================================================

void DSE_Phase4_DetermineEncounter(object oPC, object oArea)
{
    SetLocalInt(oPC, "DSE_IS_BUSY", TRUE);


    // --- PHASE 4.1: HEAT CHECK ---
    float fModifier = DSE_GetHeatMultiplier(oArea);


    if (fModifier < 0.1)
    {
        SetLocalInt(oPC, "DSE_IS_BUSY", FALSE);
        return;
    }


    // --- PHASE 4.2: MATERIAL DETECTION ---
    location lPC = GetLocation(oPC);
    int nMat = GetSurfaceMaterial(lPC);

    // We capture prefix and suffix for Table Construction and Boss Detection.
    string sPre = ENC_GetMaterialPrefix(nMat);
    string sSuf = ENC_GetRaritySuffix();
    string sTableName = sPre + sSuf;


    // --- PHASE 4.3: 2DA LOOKUP ---
    int nRow = Random(20);
    string sResRef = Get2DAString(sTableName, "ResRef", nRow);


    if (sResRef == "" || sResRef == "****")
    {
        SetLocalInt(oPC, "DSE_IS_BUSY", FALSE);
        return;
    }


    // --- PHASE 4.4: QUANTITY & STAGGER ---
    int nBaseNum = d6();
    int nFinalNum = FloatToInt(IntToFloat(nBaseNum) * fModifier);


    if (nFinalNum < 1)
    {
        nFinalNum = 1;
    }


    int i;
    for (i = 1; i <= nFinalNum; i++)
    {
        // The Stagger: 0.75s per monster prevents CPU spikes.
        float fBirthStagger = IntToFloat(i) * 0.75;
        DelayCommand(fBirthStagger, DSE_Phase5_DoSpawn(oPC, oArea, sResRef, i, sSuf));
    }
}


// =============================================================================
// --- PHASE 0: PC VALIDATION (The Gatekeeper) ---
// =============================================================================

int DSE_Phase0_IsPCBusy(object oPC)
{
    if (!GetLocalInt(oPC, "DSE_IS_BUSY"))
    {
        return FALSE;
    }


    int i;
    for (i = 1; i <= 6; i++)
    {
        object oMob = GetLocalObject(oPC, "DSE_MOB_" + IntToString(i));
        if (GetIsObjectValid(oMob) && !GetIsDead(oMob))
        {
            return TRUE;
        }
    }


    SetLocalInt(oPC, "DSE_IS_BUSY", FALSE);
    return FALSE;
}


// =============================================================================
// --- MAIN ENTRY POINT (The Architect) ---
// =============================================================================

void main()
{
    RunDebug();


    object oArea = OBJECT_SELF;
    int nVIPCount = GetLocalInt(oArea, "DSE_VIP_COUNT");


    if (nVIPCount <= 0 || GetLocalInt(oArea, "DSE_PAUSED"))
    {
        SetLocalInt(oArea, "DSE_ACTIVE", FALSE);
        return;
    }


    MCT_CleanRegistry(oArea);


    int bAnyoneStillHere = FALSE;
    int i;


    for (i = 1; i <= nVIPCount; i++)
    {
        // VIP Stagger: 0.5s per player check flattens the frame time.
        float fVIPStagger = IntToFloat(i) * 0.5;
        object oPC = GetLocalObject(oArea, "DSE_VIP_" + IntToString(i));


        if (GetIsObjectValid(oPC) && !GetIsDead(oPC) && GetArea(oPC) == oArea)
        {
            bAnyoneStillHere = TRUE;
            if (DSE_Phase0_IsPCBusy(oPC))
            {
                continue;
            }


            int bSkip = FALSE;
            int nIdx;
            for (nIdx = 1; nIdx < i; nIdx++)
            {
                object oPrev = GetLocalObject(oArea, "DSE_VIP_" + IntToString(nIdx));
                if (GetIsObjectValid(oPrev) && GetDistanceBetween(oPC, oPrev) <= 30.0)
                {
                    bSkip = TRUE;
                    break;
                }
            }


            float fHeatMod = DSE_GetHeatMultiplier(oArea);
            int nChance = FloatToInt(15.0 * fHeatMod);


            if (!bSkip && d100() <= nChance)
            {
                DelayCommand(fVIPStagger + 1.0, DSE_Phase4_DetermineEncounter(oPC, oArea));
            }
        }
    }


    if (bAnyoneStillHere)
    {
        DelayCommand(20.0, ExecuteScript("area_dse", oArea));
    }
    else
    {
        SetLocalInt(oArea, "DSE_ACTIVE", FALSE);
    }
}


/* ============================================================================
    VERTICAL BREATHING AND ARCHITECTURAL DOCUMENTATION
    ============================================================================


    The area_dse script remains the central pulse of the world.
    By integrating Phase 7 (Loot), we ensure that monsters carry their
    own data "blueprint" from birth to death.

    --- INTEGRATION: BOSS LOGIC ---
    Phase 5 now detects the "_rare" suffix from the library. If detected,
    it triggers area_boss_logic to mutate the creature into an Apex form.

    --- PERFORMANCE ARCHITECTURE ---
    1. Birth Stagger: Phase 4 prevents multiple 'CreateObject' calls in one frame.
    2. VIP Stagger: Main entry spreads player scans across several seconds.
    3. Heat Throttle: Phase 6 protects the Home PC from 'Mob Train' lag.

    --- END OF SCRIPT ---
    ============================================================================
*/
