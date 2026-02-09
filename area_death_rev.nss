/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: area_death_rev

    PILLARS:
    1. Environmental Reactivity (Climate/Terrain/Context)
    3. Optimized Scalability (480-Player Phase-Staggering)
    4. Intelligent Population (Social Interaction Reward)

    LOGIC FLOW:
    [Target: IS_DOWNED] -> [Clear State/Timer] -> [Remove VFX] -> [Restore XP]

    SYSTEM NOTES:
    * Replaces the 17-char 'area_death_revive' to fit 16-char engine limit.
    * Restores 90% of the XP reserve if a Resurrection/Raise spell is used.
    * Grants the Savior XP based on Target Level * 25.
   ============================================================================
*/

#include "area_death_inc"

void main() {
    // --- PHASE 1: INITIALIZATION ---
    object oPC      = OBJECT_SELF;           // The Rescuer
    object oTarget  = GetSpellTargetObject(); // The Downed PC
    int nSpellID    = GetSpellId();

    // --- PHASE 2: VALIDATION ---
    // Ensure the target is actually in the "Bleed Out" phase
    if (!GetLocalInt(oTarget, "IS_DOWNED")) {
        SendMessageToPC(oPC, "Target is stable or already deceased.");
        return;
    }

    // --- PHASE 3: STATE RESET ---
    // Deleting this variable stops ResolveDeathFate from firing in area_death_sys
    DeleteLocalInt(oTarget, "IS_DOWNED");

    // Remove Knockdown and any "Gray" or "Death" visual effects
    effect eLoop = GetFirstEffect(oTarget);
    while (GetIsEffectValid(eLoop)) {
        int nType = GetEffectType(eLoop);
        if (nType == EFFECT_TYPE_KNOCKDOWN || nType == EFFECT_TYPE_VISUALEFFECT) {
            RemoveEffect(oTarget, eLoop);
        }
        eLoop = GetNextEffect(oTarget);
    }

    // --- PHASE 4: XP RESTORATION (The 90% Rule) ---
    // If a high-tier Cleric spell was used, we return the stored XP reserve.
    if (nSpellID == SPELL_RESURRECTION || nSpellID == SPELL_RAISE_DEAD) {
        int nReserve = GetLocalInt(oTarget, "DEATH_XP_RESERVE");
        if (nReserve > 0) {
            SetXP(oTarget, GetXP(oTarget) + nReserve);
            DeleteLocalInt(oTarget, "DEATH_XP_RESERVE");
            FloatingTextStringOnCreature("Soul Restored: 90% XP recovered!", oTarget);
        }
    }

    // --- PHASE 5: REWARD THE SAVIOR ---
    // Reward based on target power to encourage saving high-level players.
    int nRewardXP = GetHitDice(oTarget) * 25;
    SetXP(oPC, GetXP(oPC) + nRewardXP);

    // --- PHASE 6: FINAL STABILIZATION ---
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(10), oTarget);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_RESTORATION), oTarget);

    SendMessageToPC(oPC, "Resurrection Successful. Reward: " + IntToString(nRewardXP) + " XP.");
    SendMessageToPC(oTarget, "You have been brought back from the brink by " + GetName(oPC) + ".");
}
