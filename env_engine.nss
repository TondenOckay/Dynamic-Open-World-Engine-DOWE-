/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: env_engine (10 Chars)
    
    PILLARS:
    1. Environmental Reactivity (Climate/Terrain/Context)
    2. Biological Persistence (Modifier Injection)
    3. Optimized Scalability (Area-Wide Batch Processing)
    
    DESCRIPTION:
    The master climate processor for the DOWE system. This script identifies 
    the area's climate type and scans all players within to determine if 
    their equipment (e.g., Sun Hats) protects them. It then injects 
    modifier variables (MOD_DECAY_X) into the PC for the bio_engine to read.
    
    PHASE-STAGGERING:
    * Executed by 'the_conductor' Movement 3 (20s offset from start).
    * OBJECT_SELF is the AREA object.
   ============================================================================
*/

// [2DA REFERENCE / CONSTANTS]
// // This script utilizes the following Local Variable on the Area:
// // AREA_CLIMATE_TYPE: 0=Normal, 1=Desert (Heat), 2=Arctic (Cold)
// // This script utilizes the following Item Tag:
// // SUN_HAT: Protects against thirst acceleration in Desert climates.

// --- DOWE DEBUG SYSTEM ---
// Integrated tracer: Broadcasts environmental telemetry if DEBUG_MODE is TRUE.
void Env_Debug(string sMsg, object oArea) {
    if (GetLocalInt(GetModule(), "DOWE_DEBUG_MODE") == TRUE) {
        object oPC = GetFirstObjectInArea(oArea);
        if(GetIsObjectValid(oPC)) {
            SendMessageToPC(oPC, " [ENV_ENGINE] -> " + sMsg);
        }
    }
}

void main() {
    // PHASE 1: AREA IDENTIFICATION
    object oArea = OBJECT_SELF;
    
    // Retrieve the climate zone from the area variable.
    int nClimate = GetLocalInt(oArea, "AREA_CLIMATE_TYPE");

    // PHASE 2: BATCH PC PROCESSING
    // We iterate through all objects in the area once per 30 seconds.
    object oPC = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oPC)) {
        // We only care about valid players (ignore DMs and NPCs for survival).
        if (GetIsPC(oPC) && !GetIsDM(oPC)) {
            
            // RESET MODIFIERS: Start from zero each pulse to allow for gear changes.
            int nThirstMod = 0;
            int nFatigueMod = 0;
            int nHungerMod = 0;

            // PHASE 3: CLIMATE LOGIC - DESERT (HEAT)
            if (nClimate == 1) { 
                // CONTEXTUAL CHECK: Is the player wearing a "Sun Hat"?
                object oHat = GetItemInSlot(INVENTORY_SLOT_HEAD, oPC);
                
                if (GetTag(oHat) != "SUN_HAT") {
                    // NO PROTECTION: Apply heat-based attrition modifiers.
                    nThirstMod = 5;  // Desert sun dries you out +5% faster.
                    nFatigueMod = 2; // Heat exhaustion +2%.
                    
                    if(GetLocalInt(GetModule(), "DOWE_DEBUG_MODE"))
                        SendMessageToPC(oPC, " [ENV] The sun beats down on your unprotected head.");
                } else {
                    // PROTECTED: The hat mitigates the heat modifiers.
                    Env_Debug(GetName(oPC) + " is shielded by a sun hat.", oArea);
                }
            }
            
            // PHASE 4: CLIMATE LOGIC - ARCTIC (COLD)
            else if (nClimate == 2) {
                // Cold environments burn calories and stamina faster.
                nHungerMod = 2;   // Shivering burns food.
                nFatigueMod = 5;  // Freezing winds cause exhaustion.
                
                Env_Debug(GetName(oPC) + " is struggling against the arctic cold.", oArea);
            }

            // PHASE 5: MODIFIER INJECTION (MOD_DECAY_X)
            // We pass these values to the 'bio_engine' via Local Variables on the PC.
            // The bio_engine (Movement 2) will pick these up 10 seconds later.
            SetLocalInt(oPC, "MOD_DECAY_HUNGER",  nHungerMod);
            SetLocalInt(oPC, "MOD_DECAY_THIRST",  nThirstMod);
            SetLocalInt(oPC, "MOD_DECAY_FATIGUE", nFatigueMod);
        }
        
        // Move to the next object in the area.
        oPC = GetNextObjectInArea(oArea);
    }

    // PHASE 6: FINAL TRACER
    Env_Debug("Climate Pulse Complete for: " + GetName(oArea), oArea);
}
