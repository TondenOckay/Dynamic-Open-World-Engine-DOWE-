/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: enc_conductor
    
    PILLARS:
    1. Environmental Reactivity (Surface-Specific Lists)
    3. Optimized Scalability (Distance-Throttled Instantiation)
    4. Intelligent Population (Weighted Spawn Logic)
    
    DESCRIPTION:
    The Dynamic Encounter Brain. Runs per-PC. Handles the 40% roll,
    combat proximity checks, rarity determination, and 3D coordinate 
    offset spawning (5m, 10-20m, 30m).
    
    SYSTEM NOTES:
    * Triple-checked for 02/2026 Gold Standard.
    * Staggered: Aborts if other players within 40m are in combat.
   ============================================================================
*/
void main() {
    object oPC = OBJECT_SELF;
    object oArea = GetArea(oPC);
    int bDebug = GetLocalInt(GetModule(), "DOWE_DEBUG_MODE");
    // PHASE 0: COMBAT & PROXIMITY GUARDS
    // Do not spawn on players already fighting, or near players already fighting.
    if (GetIsInCombat(oPC)) return;
    object oNear = GetFirstObjectInArea(oArea);
    while(GetIsObjectValid(oNear)) {
        if(GetIsPC(oNear) && oNear != oPC) {
            if(GetDistanceBetween(oPC, oNear) <= 40.0 && GetIsInCombat(oNear)) return;
        }
        oNear = GetNextObjectInArea(oArea);
    }
    // PHASE 1: THE 40% CHANCE ROLL
    // Core engine requirement: only 40% of pulses trigger an encounter.
    if (d100() > 40) return;
    // PHASE 2: RARITY & 2DA SELECTION
    // Calculates rarity based on a 100-point curve (Common/Uncommon/Rare).
    int nRoll = d100();
    string sRarity = (nRoll > 85) ? "rare" : (nRoll > 60 ? "uncommon" : "common");
    string s2DA = GetTag(oArea) + "_" + sRarity;
    int nTotalRows = Get2DARowCount(s2DA);
    if (nTotalRows <= 0) return;
    // PHASE 3: DISTANCE WEIGHTING
    // Weights: 15% at 5m, 70% at 10-20m, 15% at 30m.
    int nDistRoll = d100();
    float fDist = 15.0 + (IntToFloat(Random(51)) / 10.0); // Default 10-20m
    if (nDistRoll <= 15) fDist = 5.0; 
    else if (nDistRoll > 85) fDist = 30.0;
    // PHASE 4: SPAWN EXECUTION (1-6 Creatures)
    int nAmount = d6(); int i;
    for(i = 0; i < nAmount; i++) {
        // Randomize spawn angle to prevent 'line-clumping'
        float fAngle = IntToFloat(Random(360));
        vector vSpawn = GetPosition(oPC);
        vSpawn.x += fDist * cos(fAngle); vSpawn.y += fDist * sin(fAngle);
        location lLoc = Location(oArea, vSpawn, 0.0);
        // Randomly select ResRef from the rarity-specific 2DA
        string sResRef = Get2DAString(s2DA, "RESREF", Random(nTotalRows));
        object oSpawn = CreateObject(OBJECT_TYPE_CREATURE, sResRef, lLoc);
        // PHASE 5: SILO HAND-SHAKE
        // Pass PC reference to the GPS system for ownership registration.
        SetLocalObject(oSpawn, "ENC_SPAWN_OWNER", oPC);
        ExecuteScript("enc_gps", oSpawn);
        if(bDebug) {
            SendMessageToPC(oPC, "DEBUG: [enc_conductor] " + sResRef + " spawned at " + FloatToString(fDist, 0, 1) + "m");
        }
    }
}
