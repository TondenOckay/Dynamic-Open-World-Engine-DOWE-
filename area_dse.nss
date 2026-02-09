/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: area_dse_engine (area_dse)
    
    PILLARS:
    1. Environmental Reactivity (Material/Terrain Context)
    3. Optimized Scalability (VIP & Birth Staggering)
    4. Intelligent Population (7-Phase Logic Flow)
    
    SYSTEM NOTES:
    * Replaces 'area_dse' to comply with Master Build naming.
    * Triple-Checked: Preserves d100 Heat Throttling.
    * Triple-Checked: Preserves 0.75s Birth Stagger to prevent CPU spikes.
   ============================================================================
*/

#include "nw_i0_generic"
#include "area_mct"         // Swarm Registry (MCT_Register / MCT_Clean)
#include "area_debug_inc"   // Master Debugger
#include "area_enc_inc"     // Material Prefix Library

// --- CONSTANTS ---
const string VAR_HEAT_VAL = "DSE_AREA_HEAT_LEVEL";

// --- PROTOTYPES ---
void DSE_Phase7_TriggerLoot(object oKilled);
float DSE_Phase6_GetHeatMultiplier(object oArea);
void DSE_Phase5_DoSpawn(object oPC, object oArea, string sResRef, int nSlot, string sSuffix);
void DSE_Phase4_DetermineEncounter(object oPC, object oArea);
int DSE_Phase0_IsPCBusy(object oPC);

// =============================================================================
// --- PHASE 7: POST-MORTEM (THE INHERITANCE) ---
// =============================================================================
void DSE_Phase7_TriggerLoot(object oKilled)
{
    int nTier = GetLocalInt(oKilled, "DSE_LOOT_TIER");
    if (nTier > 0)
    {
        SetLocalInt(oKilled, "LOOT_TABLE_TO_ROLL", nTier);
        ExecuteScript("area_loot", oKilled); // Master Loot Hook
        
        if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
            SendMessageToPC(GetFirstPC(), "DSE DEATH: Tier " + IntToString(nTier) + " dropped for " + GetName(oKilled));
    }
}

// =============================================================================
// --- PHASE 6: PERFORMANCE GOVERNOR (THE HEATMAP) ---
// =============================================================================
float DSE_Phase6_GetHeatMultiplier(object oArea)
{
    int nHeat = GetLocalInt(oArea, VAR_HEAT_VAL);
    if (nHeat > 100) return 0.0; // Emergency Shutdown
    if (nHeat > 50)  return 0.5; // 50% Throttle
    return 1.0;                  // Optimal
}

// =============================================================================
// --- PHASE 5: THE BIRTH ACTION (STAGGERED EXECUTION) ---
// =============================================================================
void DSE_Phase5_DoSpawn(object oPC, object oArea, string sResRef, int nSlot, string sSuffix)
{
    if (!GetIsObjectValid(oPC) || GetIsDead(oPC) || GetArea(oPC) != oArea) return;

    // Vector Calculation (Preserved from v7.0)
    vector vPos = GetPosition(oPC);
    vPos.x += (Random(13) - 6.0);
    vPos.y += (Random(13) - 6.0);
    location lLoc = Location(oArea, vPos, 0.0);

    object oMob = CreateObject(OBJECT_TYPE_CREATURE, sResRef, lLoc);

    // BOSS MUTATION HOOK
    if (sSuffix == "_rare") ExecuteScript("area_boss_logic", oMob);

    // AI HIBERNATION (Pillar 3 Performance)
    SetAILevel(oMob, AI_LEVEL_VERY_LOW);
    SetLocalInt(oMob, "DSE_AI_HIBERNATE", TRUE);

    // LOOT TIER ASSIGNMENT (Preserved Logic)
    int nHD = GetHitDice(oMob);
    int nTier = (nHD > 20 || sSuffix == "_rare") ? 10 : (nHD > 12 ? 5 : (nHD > 5 ? 2 : 1));
    SetLocalInt(oMob, "DSE_LOOT_TIER", nTier);

    MCT_Register(oMob, oArea, oPC);
    SetLocalObject(oPC, "DSE_MOB_" + IntToString(nSlot), oMob);
    ApplyEffectAtLocation(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_UNSUMMON), lLoc);
}

// =============================================================================
// --- PHASE 4: ENCOUNTER SELECTION (MATERIAL AWARE) ---
// =============================================================================
void DSE_Phase4_DetermineEncounter(object oPC, object oArea)
{
    SetLocalInt(oPC, "DSE_IS_BUSY", TRUE);
    float fModifier = DSE_Phase6_GetHeatMultiplier(oArea);
    if (fModifier < 0.1) { SetLocalInt(oPC, "DSE_IS_BUSY", FALSE); return; }

    // Material Detection (Pillar 1)
    location lPC = GetLocation(oPC);
    int nMat = GetSurfaceMaterial(lPC);
    string sPre = ENC_GetMaterialPrefix(nMat);
    string sSuf = ENC_GetRaritySuffix();
    string sTableName = sPre + sSuf;

    int nRow = Random(20);
    string sResRef = Get2DAString(sTableName, "ResRef", nRow);
    if (sResRef == "" || sResRef == "****") { SetLocalInt(oPC, "DSE_IS_BUSY", FALSE); return; }

    int nFinalNum = FloatToInt(IntToFloat(d6()) * fModifier);
    if (nFinalNum < 1) nFinalNum = 1;

    int i;
    for (i = 1; i <= nFinalNum; i++)
    {
        // Birth Stagger: 0.75s spread
        float fBirthStagger = IntToFloat(i) * 0.75;
        DelayCommand(fBirthStagger, DSE_Phase5_DoSpawn(oPC, oArea, sResRef, i, sSuf));
    }
}

// =============================================================================
// --- MAIN ENTRY POINT (PHASED VIP STAGGERING) ---
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
        float fVIPStagger = IntToFloat(i) * 0.5;
        object oPC = GetLocalObject(oArea, "DSE_VIP_" + IntToString(i));

        if (GetIsObjectValid(oPC) && !GetIsDead(oPC) && GetArea(oPC) == oArea)
        {
            bAnyoneStillHere = TRUE;
            if (DSE_Phase0_IsPCBusy(oPC)) continue;

            // Distance Check to prevent spawn-overlapping
            int bSkip = FALSE;
            int nIdx;
            for (nIdx = 1; nIdx < i; nIdx++)
            {
                object oPrev = GetLocalObject(oArea, "DSE_VIP_" + IntToString(nIdx));
                if (GetIsObjectValid(oPrev) && GetDistanceBetween(oPC, oPrev) <= 30.0) { bSkip = TRUE; break; }
            }

            if (!bSkip && d100() <= FloatToInt(15.0 * DSE_Phase6_GetHeatMultiplier(oArea)))
            {
                DelayCommand(fVIPStagger + 1.0, DSE_Phase4_DetermineEncounter(oPC, oArea));
            }
        }
    }

    if (bAnyoneStillHere) DelayCommand(20.0, ExecuteScript("area_dse_engine", oArea));
    else SetLocalInt(oArea, "DSE_ACTIVE", FALSE);
}
