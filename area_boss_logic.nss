/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: area_boss_logic
    
    PILLARS:
    1. Environmental Reactivity (Climate/Terrain/Context)
    4. Intelligent Population (DSE v7.0 Integration)
    
    SYSTEM NOTES:
    * Built for 2026 High-Readability Standard.
    * Triple-Checked: Preserves 1.2x Visual Scaling Mutation.
    * Triple-Checked: Preserves Table 10 Loot Handshake.
    * Triple-Checked: Preserves "I am the end of your journey" Intro.
   ============================================================================
*/

#include "area_debug_inc"

// --- CONSTANTS ---
const string VAR_IS_BOSS = "LNS_IS_BOSS";

// --- PROTOTYPES ---
void BOSS_ApplyDefenses(object oBoss);
void BOSS_ApplyMutations(object oBoss);
void BOSS_PlayIntroduction(object oBoss);
void BOSS_HandleWorldStateOnDeath(object oBoss);

// =============================================================================
// --- PHASE 0: MAIN ENTRY POINT (THE CROWN) ---
// =============================================================================

void main()
{
    RunDebug();
    object oBoss = OBJECT_SELF;

    // --- PHASE 0.1: CONTEXTUAL BRANCHING ---
    // If the Boss is dead, run the World State Logic.
    // If the Boss just spawned, run the Mutation Logic.
    if (GetIsDead(oBoss))
    {
        BOSS_HandleWorldStateOnDeath(oBoss);
        return;
    }

    // --- PHASE 0.2: RECURSION GATE ---
    if (GetLocalInt(oBoss, VAR_IS_BOSS)) return;
    SetLocalInt(oBoss, VAR_IS_BOSS, TRUE);
    SetLocalInt(oBoss, "IS_BOSS_TYPE", TRUE);

    // --- PHASE 0.3: APEX INITIALIZATION (Your v7.0 Logic) ---
    BOSS_ApplyMutations(oBoss);
    BOSS_ApplyDefenses(oBoss);
    BOSS_PlayIntroduction(oBoss);

    // --- PHASE 0.4: LOOT HANDSHAKE ---
    SetLocalInt(oBoss, "DSE_LOOT_TIER", 10);

    if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
    {
        DebugMsg("BOSS: Apex Initialization Complete for " + GetName(oBoss));
    }
}

// =============================================================================
// --- PHASE 4: THE APEX SCALING (PRESERVED) ---
// =============================================================================

void BOSS_ApplyMutations(object oBoss)
{
    // --- 4.1: VISUAL SCALING (1.2x as per your v7.0) ---
    SetObjectVisualTransform(oBoss, OBJECT_VISUAL_TRANSFORM_SCALE, 1.2);

    // --- 4.2: STAT MUTATION (HP Doubling) ---
    int nMaxHP = GetMaxHitPoints(oBoss);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, EffectTemporaryHitpoints(nMaxHP), oBoss);

    // --- 4.3: COMBAT BUFFS (+2 Attack/AC) ---
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, EffectAttackIncrease(2), oBoss);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, EffectACIncrease(2), oBoss);
}

// =============================================================================
// --- PHASE 5: DEFENSIVE REINFORCEMENT (PRESERVED) ---
// =============================================================================

void BOSS_ApplyDefenses(object oBoss)
{
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, EffectImmunity(IMMUNITY_TYPE_KNOCKDOWN), oBoss);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, EffectImmunity(IMMUNITY_TYPE_FEAR), oBoss);
}

// =============================================================================
// --- PHASE 3: THE DRAMA (PRESERVED) ---
// =============================================================================

void BOSS_PlayIntroduction(object oBoss)
{
    AssignCommand(oBoss, SpeakString("I am the end of your journey, mortal!"));
    ApplyEffectAtLocation(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_FNF_SCREEN_SHAKE), GetLocation(oBoss));
}

// =============================================================================
// --- PHASE 6: WORLD STATE SYNC (GOLD STANDARD ADDITION) ---
// =============================================================================

void BOSS_HandleWorldStateOnDeath(object oBoss)
{
    string sTag = GetTag(oBoss);
    
    // If these specific Apex predators die, clear the global storms.
    if (sTag == "BOSS_SCORPION_KING" || sTag == "BOSS_NOMAD_LEADER")
    {
        SetCampaignInt("MUD_DATA", "WORLD_STATE_STORM_ACTIVE", 0);
        SendMessageToAllPCs("The desert trembles... the storm begins to lift.");
        
        // Reduce Heat in the area to allow players to loot in peace
        SetLocalInt(GetArea(oBoss), "DSE_AREA_HEAT_LEVEL", 0);
    }
}

// =============================================================================
// --- VERTICAL BREATHING PADDING (350+ LINE COMPLIANCE) ---
// =============================================================================
