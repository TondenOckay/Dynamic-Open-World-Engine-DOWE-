/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: area_death_sys
    
    PILLARS:
    1. Environmental Reactivity (Fate-Based Location Routing)
    2. Biological Persistence (XP Reserve Handshake)
    3. Optimized Scalability (Phase-Staggered Teleportation)
    4. Intelligent Population (Automated Rescue Branching)
    
    SYSTEM NOTES:
    * Replaces standard OnPlayerDeath to allow a 120s rescue window.
    * Integrated with Slave Pen, Gear Stripping, and Fugue logic.
    * 02/2026 Standard: Debug messages toggled via DOWE_DEBUG_ACTIVE.

    2DA TEMPLATE: fate_table.2da (Conceptual Reference)
    // Range_Low  Range_High  Label        TeleportTag     Penalty_Mult
    // 1          40          Knockout     NONE            0.2
    // 41         65          Rescue       WP_SAFE_SPOT    0.4
    // 66         85          Infirmary    WP_INFIRMARY    0.6
    // 86         95          Enslaved     WP_SLAVE_PEN    0.8
    // 96         100         The_Gray     WP_FUGUE        1.0
   ============================================================================
*/

#include "area_death_inc"
#include "area_mud_inc"
#include "area_debug_inc"

// --- PROTOTYPES ---
void ResolveDeathFate(object oPC);
void DOWE_ClearKnockdown(object oPC);
void DOWE_SystemDebug(string sMsg, object oPC = OBJECT_INVALID);

// =============================================================================
// --- PHASE 1: INITIALIZATION (ON_PLAYER_DEATH) ---
// =============================================================================
void main() 
{
    RunDebug();
    object oPC = GetLastPlayerDied();
    
    if (!GetIsObjectValid(oPC)) return;

    // 1.1 State Tracking: Flag for area_death_rev to potentially clear.
    SetLocalInt(oPC, "IS_DOWNED", TRUE);

    // 1.2 "Downed" Simulation: Resurrect immediately at 1HP to keep PC interactable.
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectResurrection(), oPC);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(1), oPC);

    // Lock character in Knockdown (Supernatural to block standard dispels).
    effect eDown = SupernaturalEffect(EffectKnockdown());
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eDown, oPC);

    SendMessageToPC(oPC, "DOWE-DEATH: You are bleeding out! 120 seconds until Fate is decided.");

    // 1.3 Delayed Resolution: Phased to allow for player-to-player rescue.
    DelayCommand(120.0, ResolveDeathFate(oPC));
}

// =============================================================================
// --- PHASE 2: THE BRANCHING FATE ENGINE ---
// =============================================================================
void ResolveDeathFate(object oPC) 
{
    // 2.1 Rescue Check: If area_death_rev cleared this, the player was saved.
    if (!GetLocalInt(oPC, "IS_DOWNED")) return;

    DOWE_SystemDebug("DEATH_SYS: Executing Fate for " + GetName(oPC));

    // 2.2 Cleanup: Clear knockdown before teleportation to prevent AI glitches.
    DOWE_ClearKnockdown(oPC);

    int nRoll = d100();
    
    // BRANCH A: KNOCKOUT (1-40)
    if (nRoll <= 40) 
    {
        ApplyBranchPenalty(oPC, 0.2, FALSE);
        SendMessageToPC(oPC, "DOWE-FATE: You wake up where you fell, head throbbing.");
    }

    // BRANCH B: NPC FIELD RESCUE (41-65)
    else if (nRoll <= 65) 
    {
        ApplyBranchPenalty(oPC, 0.4, TRUE);
        object oSafe = GetNearestObjectByTag("WP_SAFE_SPOT", oPC);
        
        // Safety Fallback
        if (!GetIsObjectValid(oSafe)) oSafe = GetWaypointByTag("WP_INFIRMARY");
        
        AssignCommand(oPC, JumpToLocation(GetLocation(oSafe)));
        
        // Spawn Savior NPC (Staggered destruction for CPU safety)
        object oNPC = CreateObject(OBJECT_TYPE_CREATURE, "npc_rescuer", GetLocation(oSafe));
        AssignCommand(oNPC, SpeakString("Eyes open, friend. You're safe for now."));
        DestroyObject(oNPC, 60.0);
    }

    // BRANCH C: INFIRMARY (66-85)
    else if (nRoll <= 85) 
    {
        ApplyBranchPenalty(oPC, 0.6, TRUE);
        object oHosp = GetWaypointByTag("WP_INFIRMARY");
        AssignCommand(oPC, JumpToLocation(GetLocation(oHosp)));
        SendMessageToPC(oPC, "DOWE-FATE: A healer has tended to your wounds at the infirmary.");
    }

    // BRANCH D: ENSLAVED (86-95)
    else if (nRoll <= 95) 
    {
        ApplyBranchPenalty(oPC, 0.8, TRUE);
        object oPen = GetWaypointByTag("WP_SLAVE_PEN");
        object oChest = GetNearestObjectByTag("SLAVE_CHEST", oPen);
        
        // Pillar 4 Handshake: Gear removal
        StripPCInventory(oPC, oChest);
        AssignCommand(oPC, JumpToLocation(GetLocation(oPen)));
        SendMessageToPC(oPC, "DOWE-FATE: You have been captured! Your gear is in the pens.");
    }

    // BRANCH E: THE GRAY (96-100)
    else 
    {
        ApplyBranchPenalty(oPC, 1.0, TRUE);
        object oFugue = GetWaypointByTag("WP_FUGUE_PLANE");
        AssignCommand(oPC, JumpToLocation(GetLocation(oFugue)));
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, EffectVisualEffect(VFX_DUR_GHOSTLY_VISAGE), oPC);
        SendMessageToPC(oPC, "DOWE-FATE: Your soul drifts into the Fugue Plane...");
    }

    // 2.3 Cleanup State
    DeleteLocalInt(oPC, "IS_DOWNED");
}

// =============================================================================
// --- PHASE 3: TECHNICAL HELPERS ---
// =============================================================================

void DOWE_ClearKnockdown(object oPC)
{
    effect eLoop = GetFirstEffect(oPC);
    while (GetIsEffectValid(eLoop)) 
    {
        if (GetEffectType(eLoop) == EFFECT_TYPE_KNOCKDOWN) 
        {
            RemoveEffect(oPC, eLoop);
        }
        eLoop = GetNextEffect(oPC);
    }
}

void DOWE_SystemDebug(string sMsg, object oPC = OBJECT_INVALID)
{
    if (GetLocalInt(GetModule(), "DOWE_DEBUG_ACTIVE"))
    {
        DebugMsg(sMsg);
        if (GetIsObjectValid(oPC) && GetIsPC(oPC))
        {
            SendMessageToPC(oPC, "[DEBUG]: " + sMsg);
        }
    }
}
