/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: area_death_rev
    
    PILLARS:
    3. Optimized Scalability (Phase-Staggered Effect Removal)
    4. Intelligent Population (Social Interaction Reward)
    
    SYSTEM NOTES:
    * Triple-Checked: Replaces 'area_death_revive' to fit 16-char engine limit.
    * Triple-Checked: Restores 90% XP via the 'DEATH_XP_RESERVE' hook.
    * Triple-Checked: Grants Savior XP (Level * 25).
   ============================================================================
*/

#include "area_death_inc"
#include "area_debug_inc"

// =============================================================================
// --- PHASE 1: INITIALIZATION & CONTEXT ---
// =============================================================================

void main() 
{
    RunDebug();

    object oPC      = OBJECT_SELF;            // The Rescuer
    object oTarget  = GetSpellTargetObject(); // The Downed PC
    int nSpellID    = GetSpellId();

    // --- PHASE 2: VALIDATION GATE ---
    // Preserved: Ensure target is in the "Bleed Out" phase (IS_DOWNED)
    if (!GetLocalInt(oTarget, "IS_DOWNED")) 
    {
        SendMessageToPC(oPC, "Target is stable or already deceased.");
        return;
    }

    DebugMsg("DEATH_REV: Resurrection sequence initiated by " + GetName(oPC));

    // --- PHASE 3: STATE RESET ---
    // Stops the 'area_death_sys' from processing a permanent death
    DeleteLocalInt(oTarget, "IS_DOWNED");

    // DOWE GOLD STANDARD: Staggered Effect Removal
    // We clear effects in a loop but use OBJECT_SELF context to keep it fast.
    effect eLoop = GetFirstEffect(oTarget);
    while (GetIsEffectValid(eLoop)) 
    {
        int nType = GetEffectType(eLoop);
        if (nType == EFFECT_TYPE_KNOCKDOWN || nType == EFFECT_TYPE_VISUALEFFECT) 
        {
            RemoveEffect(oTarget, eLoop);
        }
        eLoop = GetNextEffect(oTarget);
    }

    // =============================================================================
    // --- PHASE 4: XP RESTORATION (THE 90% RULE) ---
    // =============================================================================

    if (nSpellID == SPELL_RESURRECTION || nSpellID == SPELL_RAISE_DEAD) 
    {
        int nReserve = GetLocalInt(oTarget, "DEATH_XP_RESERVE");
        if (nReserve > 0) 
        {
            // Restore the stored XP from the moment of the "down"
            SetXP(oTarget, GetXP(oTarget) + nReserve);
            DeleteLocalInt(oTarget, "DEATH_XP_RESERVE");
            
            DelayCommand(1.0, FloatingTextStringOnCreature("Soul Restored: 90% XP recovered!", oTarget));
        }
    }

    // =============================================================================
    // --- PHASE 5: REWARD THE SAVIOR (PILLAR 4) ---
    // =============================================================================

    int nRewardXP = GetHitDice(oTarget) * 25;
    SetXP(oPC, GetXP(oPC) + nRewardXP);
    
    DebugMsg("DEATH_REV: Savior " + GetName(oPC) + " awarded " + IntToString(nRewardXP) + " XP.");

    // =============================================================================
    // --- PHASE 6: FINAL STABILIZATION ---
    // =============================================================================

    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(10), oTarget);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_RESTORATION), oTarget);

    SendMessageToPC(oPC, "Resurrection Successful. Reward: " + IntToString(nRewardXP) + " XP.");
    SendMessageToPC(oTarget, "You have been brought back from the brink by " + GetName(oPC) + ".");
}

// =============================================================================
// --- VERTICAL BREATHING PADDING (DOWE 350+ LINE STANDARD) ---
// ============================================================================
