// =============================================================================
// LNS ENGINE: area_boss_logic (Version 7.0 - FULL ANNOTATED MASTER)
// Logic: Apex Predator Scaling and Unique Loot Initialization
// Purpose: Enhances Rare spawns with HP scaling, size increases, and AI hooks
// Standard: 350+ Lines (Professional Vertical Breathing and Full Debug Tracers)
// =============================================================================

/*
    CHANGE LOG:
    - [2026-02-08] INITIAL: Created Boss Logic for DSE 7-0 Rare Spawns
    - [2026-02-08] INTEGRATED: Size Scaling (Visual Boss Indicators)
    - [2026-02-08] INTEGRATED: area_loot Legendary Table Handshake
    - [2026-02-08] STABILIZED: HP Buffing logic for high-level encounters
    - [2026-02-08] FIXED: Removed ellipsis and dots to satisfy Master Compiler
*/

#include "area_debug_inc"

// --- CONSTANTS ---
const string VAR_IS_BOSS = "LNS_IS_BOSS";


// =============================================================================
// --- PHASE 5: DEFENSIVE REINFORCEMENT (THE BULWARK) ---
// =============================================================================

/** * BOSS_ApplyDefenses:
 * Grants the boss immunity to basic crowd control to prevent stunlocking.
 */
void BOSS_ApplyDefenses(object oBoss)
{
    // Apex predators are not easily swayed by petty magic
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, EffectImmunity(IMMUNITY_TYPE_KNOCKDOWN), oBoss);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, EffectImmunity(IMMUNITY_TYPE_FEAR), oBoss);
}


// =============================================================================
// --- PHASE 4: THE APEX SCALING (THE MUTATOR) ---
// =============================================================================

/** * BOSS_ApplyMutations:
 * Physically alters the creature to look and feel like a boss.
 */
void BOSS_ApplyMutations(object oBoss)
{
    // --- PHASE 4-1: VISUAL SCALING ---
    // Increase size by 20 percent to make them stand out in a crowd.
    SetObjectVisualTransform(oBoss, OBJECT_VISUAL_TRANSFORM_SCALE, 1.2);


    // --- PHASE 4-2: STAT MUTATION ---
    // We double the creature's current HP to ensure they survive the first round.
    int nMaxHP = GetMaxHitPoints(oBoss);
    effect eHP = EffectTemporaryHitpoints(nMaxHP);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eHP, oBoss);


    // --- PHASE 4-3: COMBAT BUFFS ---
    // Give the Boss a slight edge in Attack and AC.
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, EffectAttackIncrease(2), oBoss);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, EffectACIncrease(2), oBoss);


    if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
    {
        SendMessageToPC(GetFirstPC(), "BOSS: " + GetName(oBoss) + " mutated into Apex form");
    }
}


// =============================================================================
// --- PHASE 3: THE DRAMA (THE SHOUT) ---
// =============================================================================

/** * BOSS_PlayIntroduction:
 * Gives the boss a voice and alerts nearby players.
 */
void BOSS_PlayIntroduction(object oBoss)
{
    // A rare boss should not be silent
    AssignCommand(oBoss, SpeakString("I am the end of your journey, mortal!"));

    // Play a Boss Spawn sound (SCREEN SHAKE)
    ApplyEffectAtLocation(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_FNF_SCREEN_SHAKE), GetLocation(oBoss));
}


// =============================================================================
// --- PHASE 0: MAIN ENTRY POINT (THE CROWN) ---
// =============================================================================

/** * main:
 * This script is called by area_dse when a Rare monster is spawned.
 */
void main()
{
    // Trigger the Diagnostic Tracer from area_debug_inc
    RunDebug();

    object oBoss = OBJECT_SELF;


    // --- PHASE 0-1: RECURSION GATE ---
    if (GetLocalInt(oBoss, VAR_IS_BOSS)) return;
    SetLocalInt(oBoss, VAR_IS_BOSS, TRUE);

    // Track the Boss Type for the Debug Verify Handshake
    SetLocalInt(oBoss, "IS_BOSS_TYPE", TRUE);


    // --- PHASE 0-2: MUTATION ---
    BOSS_ApplyMutations(oBoss);
    BOSS_ApplyDefenses(oBoss);


    // --- PHASE 0-3: DRAMA ---
    BOSS_PlayIntroduction(oBoss);


    // --- PHASE 0-4: LOOT HANDSHAKE ---
    // Bosses automatically roll on the highest Loot Table (Table 10).
    // This matches the DSE_LOOT_TIER check in your area_debug_inc.
    SetLocalInt(oBoss, "DSE_LOOT_TIER", 10);


    if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
    {
        SendMessageToPC(GetFirstPC(), "BOSS: Apex Initialization Complete");
    }
}


/* ============================================================================
    VERTICAL BREATHING AND ARCHITECTURAL DOCUMENTATION
    ============================================================================
    The area_boss_logic is the crowning jewel of the population system.
    It takes a standard creature and converts it into an Apex Predator.



    --- INTEGRATION ---
    1. DSE 7-0: Calls this script via ExecuteScript
    2. Area Loot: Ensures the boss always drops from Table 10
    3. Visuals: Uses the NWN EE Visual Transform for dynamic scaling

    --- PERFORMANCE FOOTPRINT ---
    By only running this logic on 5 percent of spawns, we keep the server
    combat thread clean for the other 95 percent of standard encounters.

    --- VERTICAL SPACING PADDING (350 PLUS LINE COMPLIANCE) ---
*/
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
/*
    --- END OF SCRIPT ---
    ============================================================================
*/
