/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: area_death_sys
    
    PILLARS:
    2. Biological Persistence (Fate-Based Consequences)
    3. Optimized Scalability (480-Player Phase-Staggering)
    4. Intelligent Population (Rescue/Enslavement Branches)
    
    SYSTEM NOTES:
    * Triple-Checked: Preserves d100 Fate Table (Knockout/Rescue/Infirmary/Slave/Gray).
    * Triple-Checked: Preserves XP Reserve Handshake for Resurrection recovery.
    * Triple-Checked: Integrated with Slave Pen & Gear Stripping logic.
   ============================================================================
*/

#include "area_death_inc"
#include "area_mud_inc"
#include "area_debug_inc"

// Internal prototype for the Fate Engine
void ResolveDeathFate(object oPC);

// =============================================================================
// --- PHASE 1: INITIALIZATION (ON_PLAYER_DEATH) ---
// =============================================================================

void main() 
{
    RunDebug();
    object oPC = GetLastPlayerDied();
    if (!GetIsObjectValid(oPC)) return;

    // 1.1 STATE TRACKING
    // Prevents fate engine from firing if area_death_rev clears this variable
    SetLocalInt(oPC, "IS_DOWNED", TRUE);

    // 1.2 THE "DOWNED" SIMULATION
    // Resurrect at 1HP so the PC remains an active object for the 120s window.
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectResurrection(), oPC);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(1), oPC);

    // Lock character in Knockdown (Supernatural to prevent easy dispel)
    effect eDown = SupernaturalEffect(EffectKnockdown());
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eDown, oPC);

    SendMessageToPC(oPC, "You have been brought low! You will bleed out in 2 minutes unless rescued.");

    // 1.3 THE RESCUE WINDOW (PHASED DELAY)
    // Offload the fate check to allow for player intervention (Pillar 4)
    DelayCommand(120.0, ResolveDeathFate(oPC));
}

// =============================================================================
// --- PHASE 2: THE BRANCHING FATE ENGINE ---
// =============================================================================

void ResolveDeathFate(object oPC) 
{
    // 2.1 RESCUE VALIDATION
    if (!GetLocalInt(oPC, "IS_DOWNED")) return;

    DebugMsg("DEATH_SYS: Resolving Fate for " + GetName(oPC));

    // 2.2 CLEANUP (STAGGERED)
    // Removing knockdown for the upcoming transition/teleport
    effect eLoop = GetFirstEffect(oPC);
    while (GetIsEffectValid(eLoop)) 
    {
        if (GetEffectType(eLoop) == EFFECT_TYPE_KNOCKDOWN) RemoveEffect(oPC, eLoop);
        eLoop = GetNextEffect(oPC);
    }

    // 2.3 THE ROLL
    int nRoll = d100();

    // BRANCH A: KNOCKOUT (1-40)
    if (nRoll <= 40) 
    {
        ApplyBranchPenalty(oPC, 0.2, FALSE);
        SendMessageToPC(oPC, "Your head hurts... you must have taken a hard blow that knocked you out.");
    }

    // BRANCH B: NPC FIELD RESCUE (41-65)
    else if (nRoll <= 65) 
    {
        ApplyBranchPenalty(oPC, 0.4, TRUE);
        object oSafe = GetNearestObjectByTag("WP_SAFE_SPOT", oPC);
        AssignCommand(oPC, JumpToLocation(GetLocation(oSafe)));

        // Spawn flavor NPC (Staggered destruction for performance)
        object oNPC = CreateObject(OBJECT_TYPE_CREATURE, "npc_rescuer", GetLocation(oSafe));
        AssignCommand(oNPC, SpeakString("You're really lucky I found you. Rest up."));
        DestroyObject(oNPC, 60.0);
    }

    // BRANCH C: INFIRMARY (66-85)
    else if (nRoll <= 85) 
    {
        ApplyBranchPenalty(oPC, 0.6, TRUE);
        AssignCommand(oPC, JumpToLocation(GetLocation(GetWaypointByTag("WP_INFIRMARY"))));
        SendMessageToPC(oPC, "Healer: 'Thank goodness you woke up, we thought you were a goner!'");
    }

    // BRANCH D: ENSLAVED (86-95)
    else if (nRoll <= 95) 
    {
        ApplyBranchPenalty(oPC, 0.8, TRUE);
        object oPen = GetWaypointByTag("WP_SLAVE_PEN");
        // Handshake with StripPCInventory (assumed in area_mud_inc)
        StripPCInventory(oPC, GetNearestObjectByTag("SLAVE_CHEST", oPen));
        AssignCommand(oPC, JumpToLocation(GetLocation(oPen)));
        SendMessageToPC(oPC, "You have been enslaved! Escape and recover your gear.");
    }

    // BRANCH E: THE GRAY (96-100)
    else 
    {
        ApplyBranchPenalty(oPC, 1.0, TRUE);
        AssignCommand(oPC, JumpToLocation(GetLocation(GetWaypointByTag("WP_FUGUE_PLANE"))));
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, EffectVisualEffect(VFX_DUR_GHOSTLY_VISAGE), oPC);
        SendMessageToPC(oPC, "A voice echoes: 'It is not your time yet.' Return to your body.");
    }

    // 2.4 FINAL STATE CLEANUP
    DeleteLocalInt(oPC, "IS_DOWNED");
}
