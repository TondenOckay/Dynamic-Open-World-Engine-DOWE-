/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: area_death_sys

    PILLARS:
    1. Environmental Reactivity (Climate/Terrain/Context)
    2. Biological Persistence (Hunger/Thirst/Fatigue)
    3. Optimized Scalability (480-Player Phase-Staggering)
    4. Intelligent Population (DSE v7.0 Integration)

    LOGIC FLOW:
    [Death Event] -> [120s Downed State] -> {Player Rescue?}
                                               |-- YES: Revive + Savior XP
                                               |-- NO:  [ResolveDeathFate]

    FATE ROLL TABLE (d100):
    1-40   : KNOCKOUT  (20% XP Loss, No Gold Loss, Wake at Site)
    41-65  : RESCUE    (40% XP Loss, 10% Gold Loss, WP_SAFE_SPOT)
    66-85  : INFIRMARY (60% XP Loss, 10% Gold Loss, WP_INFIRMARY)
    86-95  : ENSLAVED  (80% XP Loss, 10% Gold Loss, Strip Gear, WP_SLAVE_PEN)
    96-100 : THE GRAY  (100% XP Loss, 10% Gold Loss, Ghost State, WP_FUGUE)

    SYSTEM NOTES:
    * Integrated with Cleric XP Reserve (90% recovery logic on Resurrection).
    * Built for 2026 High-Readability Standard.
   ============================================================================
*/

#include "area_death_inc"
#include "area_mud_inc"

// Internal prototype for the Fate Engine
void ResolveDeathFate(object oPC);

void main() {
    // --- PHASE 1: INITIALIZATION & SAFETY ---
    object oPC = GetLastPlayerDied();
    if (!GetIsObjectValid(oPC)) return;

    // Set state tracking to prevent fate engine from firing if rescued
    SetLocalInt(oPC, "IS_DOWNED", TRUE);

    // --- PHASE 2: THE "DOWNED" SIMULATION ---
    // Resurrect at 1HP to keep the PC object interactive in the game world
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectResurrection(), oPC);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(1), oPC);

    // Lock character in Knockdown (Supernatural to prevent easy dispel)
    effect eDown = SupernaturalEffect(EffectKnockdown());
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eDown, oPC);

    SendMessageToPC(oPC, "You have been brought low! You will bleed out in 2 minutes unless rescued.");

    // --- PHASE 3: THE RESCUE WINDOW TIMER ---
    // Offload the fate check to the 120s delay to allow player intervention
    DelayCommand(120.0, ResolveDeathFate(oPC));
}

void ResolveDeathFate(object oPC) {
    // ABORT if the player was rescued (IS_DOWNED cleared by area_death_revive)
    if (!GetLocalInt(oPC, "IS_DOWNED")) return;

    // Remove knockdown for the upcoming transition/teleport
    effect eLoop = GetFirstEffect(oPC);
    while (GetIsEffectValid(eLoop)) {
        if (GetEffectType(eLoop) == EFFECT_TYPE_KNOCKDOWN) RemoveEffect(oPC, eLoop);
        eLoop = GetNextEffect(oPC);
    }

    // --- PHASE 4: THE BRANCHING FATE ENGINE ---
    int nRoll = d100();

    // BRANCH A: KNOCKOUT (1-40)
    if (nRoll <= 40) {
        ApplyBranchPenalty(oPC, 0.2, FALSE);
        SendMessageToPC(oPC, "Your head hurts... you must have taken a hard blow that knocked you out.");
    }

    // BRANCH B: NPC FIELD RESCUE (41-65)
    else if (nRoll <= 65) {
        ApplyBranchPenalty(oPC, 0.4, TRUE);
        object oSafe = GetNearestObjectByTag("WP_SAFE_SPOT", oPC);
        AssignCommand(oPC, JumpToLocation(GetLocation(oSafe)));

        object oNPC = CreateObject(OBJECT_TYPE_CREATURE, "npc_rescuer", GetLocation(oSafe));
        AssignCommand(oNPC, SpeakString("You're really lucky I found you. Rest up."));
        DestroyObject(oNPC, 60.0);
    }

    // BRANCH C: INFIRMARY (66-85)
    else if (nRoll <= 85) {
        ApplyBranchPenalty(oPC, 0.6, TRUE);
        AssignCommand(oPC, JumpToLocation(GetLocation(GetWaypointByTag("WP_INFIRMARY"))));
        SendMessageToPC(oPC, "Healer: 'Thank goodness you woke up, we thought you were a goner!'");
    }

    // BRANCH D: ENSLAVED (86-95)
    else if (nRoll <= 95) {
        ApplyBranchPenalty(oPC, 0.8, TRUE);
        object oPen = GetWaypointByTag("WP_SLAVE_PEN");
        StripPCInventory(oPC, GetNearestObjectByTag("SLAVE_CHEST", oPen));
        AssignCommand(oPC, JumpToLocation(GetLocation(oPen)));
        SendMessageToPC(oPC, "You have been enslaved! Escape and recover your gear.");
    }

    // BRANCH E: THE GRAY (96-100)
    else {
        ApplyBranchPenalty(oPC, 1.0, TRUE);
        AssignCommand(oPC, JumpToLocation(GetLocation(GetWaypointByTag("WP_FUGUE_PLANE"))));
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, EffectVisualEffect(VFX_DUR_GHOSTLY_VISAGE), oPC);
        SendMessageToPC(oPC, "A voice echoes: 'It is not your time yet.' Return to your body.");
    }

    // Final state cleanup
    DeleteLocalInt(oPC, "IS_DOWNED");
}
