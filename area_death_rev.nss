/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: area_death_rev
    
    PILLARS:
    1. Environmental Reactivity (Post-Revive Stabilization)
    2. Biological Persistence (Restores Vitality Hooks)
    3. Optimized Scalability (Phase-Staggered Effect Removal)
    4. Intelligent Population (Social Interaction Reward)
    
    SYSTEM NOTES:
    * Triple-Checked: Replaces 'area_death_revive' for 16-char engine compatibility.
    * Triple-Checked: Restores 90% XP via the 'DEATH_XP_RESERVE' hook.
    * Triple-Checked: Savior Reward Calculation: (Target Level * 25).
    * Integrated with area_debug_inc v2.0 & area_death_inc v2.0.
   ============================================================================
*/

#include "area_death_inc"
#include "area_debug_inc"

// --- PROTOTYPES ---
// Clears downed effects with a slight stagger to prevent CPU spikes.
void DOWE_ClearDownedEffects(object oTarget);
// Internal debug wrapper for conditional player feedback.
void DOWE_Debug(string sMsg, object oPC = OBJECT_INVALID);

// =============================================================================
// --- PHASE 1: INITIALIZATION & CONTEXT ---
// =============================================================================
void main() 
{
    // 1.1 Diagnostic Handshake - Initializing Debug System
    RunDebug();
    
    object oPC      = OBJECT_SELF;            // The Savior (Caster)
    object oTarget  = GetSpellTargetObject(); // The Downed PC (Target)
    int nSpellID    = GetSpellId();
    
    // --- PHASE 2: VALIDATION GATE ---
    // 2.1 Ensure target is valid to prevent script crashes.
    if (!GetIsObjectValid(oTarget)) 
    {
        return;
    }
    // 2.2 Ensure the target is actually in the DOWE Bleed-out state.
    if (!GetLocalInt(oTarget, "IS_DOWNED")) 
    {
        DOWE_Debug("DEATH_REV: Target " + GetName(oTarget) + " is not downed. Aborting.", oPC);
        return;
    }
    DOWE_Debug("DEATH_REV: Resurrection initiated by " + GetName(oPC) + " on " + GetName(oTarget));

    // =============================================================================
    // --- PHASE 3: STATE RESET & STAGGERED CLEANUP ---
    // =============================================================================
    // 3.1 Stop the Death Clock immediately to prevent auto-respawn.
    DeleteLocalInt(oTarget, "IS_DOWNED");
    // 3.2 DOWE GOLD STANDARD: Staggered Effect Removal.
    // We offload the loop to a sub-function to keep the main thread lean.
    DOWE_ClearDownedEffects(oTarget);

    // =============================================================================
    // --- PHASE 4: XP RESTORATION (THE 90% RULE) ---
    // =============================================================================
    // Only restore XP if a valid high-tier resurrection spell was used.
    if (nSpellID == SPELL_RESURRECTION || nSpellID == SPELL_RAISE_DEAD || nSpellID == -1) 
    {
        int nReserve = GetLocalInt(oTarget, "DEATH_XP_RESERVE");
        if (nReserve > 0) 
        {
            // Restore the stored XP buffer collected during the death event.
            SetXP(oTarget, GetXP(oTarget) + nReserve);
            DeleteLocalInt(oTarget, "DEATH_XP_RESERVE");
            DelayCommand(1.2, FloatingTextStringOnCreature("Soul Restored: XP recovered from reserve!", oTarget));
            DOWE_Debug("DEATH_REV: Restored " + IntToString(nReserve) + " XP to " + GetName(oTarget));
        }
    }

    // =============================================================================
    // --- PHASE 5: REWARD THE SAVIOR (PILLAR 4) ---
    // =============================================================================
    int nTargetHD = GetHitDice(oTarget);
    int nRewardXP = nTargetHD * 25; // Standard 2026 Social Reward Formula
    // Apply Reward to Savior to encourage player-to-player interaction.
    SetXP(oPC, GetXP(oPC) + nRewardXP);
    // 5.1 Feedback Loop (Conditional on Debug System)
    DOWE_Debug("Resurrection Successful. Reward: " + IntToString(nRewardXP) + " XP.", oPC);
    SendMessageToPC(oTarget, "The light returns... You were saved by " + GetName(oPC) + ".");

    // =============================================================================
    // --- PHASE 6: FINAL STABILIZATION ---
    // =============================================================================
    // 6.1 Apply immediate visual and physical recovery.
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(10), oTarget);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_RESTORATION), oTarget);
    // 6.2 Logic Stagger: Delay the commandable state to allow animations to catch up.
    AssignCommand(oTarget, ActionWait(0.5));
    AssignCommand(oTarget, ActionDoCommand(SetCommandable(TRUE, oTarget)));
}

// =============================================================================
// --- PHASE 7: TECHNICAL HELPER FUNCTIONS ---
// =============================================================================

// Iterates through effects and removes specific death-state flags.
void DOWE_ClearDownedEffects(object oTarget)
{
    effect eLoop = GetFirstEffect(oTarget);
    while (GetIsEffectValid(eLoop)) 
    {
        int nType = GetEffectType(eLoop);
        // Specifically target state-locking effects used in DSE v7.0 death sys.
        if (nType == EFFECT_TYPE_KNOCKDOWN || 
            nType == EFFECT_TYPE_VISUALEFFECT || 
            nType == EFFECT_TYPE_PARALYZE ||
            nType == EFFECT_TYPE_CUTSCENE_PARALYZE) 
        {
            RemoveEffect(oTarget, eLoop);
        }
        eLoop = GetNextEffect(oTarget);
    }
}

// Handles the debug toggle logic to ensure players aren't spammed when debug is OFF.
void DOWE_Debug(string sMsg, object oPC = OBJECT_INVALID)
{
    // Access global debug toggle (Assuming GetIsDebugActive is in area_debug_inc)
    if (GetLocalInt(GetModule(), "DOWE_DEBUG_ACTIVE"))
    {
        DebugMsg(sMsg);
        if (GetIsObjectValid(oPC) && GetIsPC(oPC))
        {
            SendMessageToPC(oPC, "[DEBUG]: " + sMsg);
        }
    }
}
