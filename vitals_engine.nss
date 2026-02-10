/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: vitals_engine
    
    PILLARS:
    1. Environmental Reactivity (Modifier-Aware Logic)
    2. Biological Persistence (Hunger/Thirst/Fatigue)
    3. Optimized Scalability (Local Variable Caching)
    
    DESCRIPTION:
    The standalone biological processing unit for DOWE. This script handles 
    resource attrition for Hunger, Thirst, and Fatigue. It calculates base 
    decay plus any environmental modifiers (Heat, Cold, Disease). 
    
    PHASE STAGGERING:
    This script is called by 'the_conductor' during Movement 2. It runs 
    on the PC object (OBJECT_SELF) with a 0.1s stagger per player to 
    ensure zero server hitching at 480-player capacity.
    
    SYSTEM NOTES:
    * Rebuilt for 2026 Gold Standard High-Readability.
    * Uses "Variable Modifiers" to decouple Environment from Biology.
    * No Database I/O: All math is performed on Local Variables for speed.
   ============================================================================
*/

// [2DA REFERENCE SECTION]
// // Future expansion: Rates could be pulled from 'vitals_base.2da' 
// // based on PC Race (e.g., Elves need less sleep, Half-Orcs need more food).

// --- DOWE DEBUG SYSTEM ---
// Integrated Tracer: Sends technical data to the player if Debug Mode is ON.
void Vitals_Debug(string sMsg, object oPC) {
    if (GetLocalInt(GetModule(), "DOWE_DEBUG_MODE") == TRUE) {
        SendMessageToPC(oPC, " [VITALS ENGINE] -> " + sMsg);
    }
}

void main() {
    // PHASE 1: INITIALIZATION & GUARD CLAUSES
    // The Conductor executes this script ON the player object.
    object oPC = OBJECT_SELF;

    // Safety: Ignore DMs, dead players, or invalid objects.
    if (!GetIsPC(oPC) || GetIsDM(oPC) || GetIsDead(oPC)) return;

    // PHASE 2: DATA ACQUISITION (THE LOCAL CACHE)
    // We retrieve the current percentage (0-100) from the PC.
    int nHunger  = GetLocalInt(oPC, "VITAL_HUNGER");
    int nThirst  = GetLocalInt(oPC, "VITAL_THIRST");
    int nFatigue = GetLocalInt(oPC, "VITAL_FATIGUE");

    // NEW PLAYER INITIALIZATION
    // If these variables don't exist, we assume a fresh login/character.
    if (GetLocalInt(oPC, "VITAL_INIT_COMPLETE") == FALSE) {
        nHunger = 100;
        nThirst = 100;
        nFatigue = 100;
        SetLocalInt(oPC, "VITAL_INIT_COMPLETE", TRUE);
        Vitals_Debug("Initializing fresh biological state for PC.", oPC);
    }

    // PHASE 3: MODIFIER LOOKUP (ENVIRONMENTAL REACTIVITY)
    // These integers are set by other scripts (e.g., environmental_engine).
    // Example: Desert heat adds +5 to thirst decay.
    int nModHunger  = GetLocalInt(oPC, "MOD_DECAY_HUNGER"); 
    int nModThirst  = GetLocalInt(oPC, "MOD_DECAY_THIRST");
    int nModFatigue = GetLocalInt(oPC, "MOD_DECAY_FATIGUE");

    // PHASE 4: ATTRITION CALCULATION
    // Base Rates: 1% Hunger/Fatigue, 2% Thirst per 30.0s cycle.
    int nHungerLoss  = 1 + nModHunger;
    int nThirstLoss  = 2 + nModThirst;
    int nFatigueLoss = 1 + nModFatigue;

    nHunger  -= nHungerLoss;
    nThirst  -= nThirstLoss;
    nFatigue -= nFatigueLoss;

    // BOUNDARY CLAMPING
    if (nHunger < 0)  nHunger = 0;
    if (nThirst < 0)  nThirst = 0;
    if (nFatigue < 0) nFatigue = 0;

    // PHASE 5: CONSEQUENCE APPLICATION (CRITICAL STATE)
    // If any vital hits 0, the player begins taking physical damage.
    if (nHunger == 0 || nThirst == 0 || nFatigue == 0) {
        // Apply 1 point of damage. This acts as a persistent "tick" until they eat/drink.
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectDamage(1, DAMAGE_TYPE_MAGICAL), oPC);
        
        // Visual/Audio feedback for the player.
        FloatingTextStringOnCreature(" *You are physically failing from deprivation* ", oPC, FALSE);
    }

    // PHASE 6: PLAYER NOTIFICATION THRESHOLDS
    // Alerts the player when they reach 10% (The Danger Zone).
    if (nHunger == 10)  SendMessageToPC(oPC, "Your stomach is painfully empty. You need food.");
    if (nThirst == 10)  SendMessageToPC(oPC, "Your mouth is dry and parched. You need water.");
    if (nFatigue == 10) SendMessageToPC(oPC, "Exhaustion clouds your vision. You need rest.");

    // PHASE 7: CACHE UPDATING
    // Save the new values back to the PC object. 
    // These will be picked up by the 'auto_save' script for DB persistence later.
    SetLocalInt(oPC, "VITAL_HUNGER",  nHunger);
    SetLocalInt(oPC, "VITAL_THIRST",  nThirst);
    SetLocalInt(oPC, "VITAL_FATIGUE", nFatigue);

    // PHASE 8: TECHNICAL TRACER
    // High-value technical data for server monitoring.
    Vitals_Debug("Biological Pulse: H["+IntToString(nHunger)+"] T["+IntToString(nThirst)+"] F["+IntToString(nFatigue)+"]", oPC);
    if (nModThirst > 0) Vitals_Debug("Active Thirst Penalty: +" + IntToString(nModThirst), oPC);
}
