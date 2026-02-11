/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: enc_conductor
    
    PILLARS:
    1. Environmental Reactivity (Surface-Specific Lists)
    3. Optimized Scalability (Distance-Throttled Instantiation)
    4. Intelligent Population (Proximity Wake-up Ripple)
    
    DESCRIPTION:
    The Dynamic Encounter Brain. Runs per-PC via Switchboard.
    Phase 1-5: Handles dynamic spawning (40% chance).
    Phase 6: The "Ripple" - Updates nearby GPS creatures' wake-up timers.
    
    SYSTEM NOTES:
    * Triple-checked for 02/2026 Gold Standard.
    * Staggered: PC-centric logic prevents global search lag.
   ============================================================================
*/
void main() {
    object oPC = OBJECT_SELF;
    object oArea = GetArea(oPC);
    int bDebug = GetLocalInt(GetModule(), "DOWE_DEBUG_MODE");

    // PHASE 0: COMBAT & PROXIMITY GUARDS
    // Abort if PC is fighting or near another PC in combat.
    if (GetIsInCombat(oPC)) return;
    object oNear = GetFirstObjectInArea(oArea);
    while(GetIsObjectValid(oNear)) {
        if(GetIsPC(oNear) && oNear != oPC) {
            if(GetDistanceBetween(oPC, oNear) <= 40.0 && GetIsInCombat(oNear)) return;
        }
        oNear = GetNextObjectInArea(oArea);
    }

    // PHASE 1: PROXIMITY WAKE-UP RIPPLE (The "Metronome")
    // Instead of a global eye, the PC wakes everything within 40m.
    // We use the GPS list (Eye in the Sky) for O(n) efficiency.
    int nLastID = GetLocalInt(oArea, "DOWE_AREA_LAST_ID");
    int j;
    for(j = 1; j <= nLastID; j++) {
        object oC = GetLocalObject(oArea, "ENC_OBJ_" + IntToString(j));
        if(GetIsObjectValid(oC)) {
            if(GetDistanceBetween(oPC, oC) <= 40.0) {
                // Set the wake-up timestamp to current session time.
                SetLocalInt(oC, "DOWE_WAKE_TIME", GetTimeSecond() + (GetTimeMinute() * 60));
                if(bDebug) SendMessageToPC(oPC, "DEBUG: [Ripple] Waking GPS ID: " + IntToString(j));
            }
        }
    }

    // PHASE 2: THE 40% CHANCE ROLL
    if (d100() > 40) return;

    // PHASE 3: RARITY & 2DA SELECTION
    int nRoll = d100();
    string sRarity = (nRoll > 85) ? "rare" : (nRoll > 60 ? "uncommon" : "common");
    string s2DA = GetTag(oArea) + "_" + sRarity;
    int nTotalRows = Get2DARowCount(s2DA);
    if (nTotalRows <= 0) return;

    // PHASE 4: DISTANCE WEIGHTING
    int nDistRoll = d100();
    float fDist = 15.0 + (IntToFloat(Random(51)) / 10.0);
    if (nDistRoll <= 15) fDist = 5.0; 
    else if (nDistRoll > 85) fDist = 30.0;

    // PHASE 5: SPAWN EXECUTION (1-6 Creatures)
    int nAmount = d6(); int i;
    for(i = 0; i < nAmount; i++) {
        float fAngle = IntToFloat(Random(360));
        vector vSpawn = GetPosition(oPC);
        vSpawn.x += fDist * cos(fAngle); vSpawn.y += fDist * sin(fAngle);
        location lLoc = Location(oArea, vSpawn, 0.0);
        string sResRef = Get2DAString(s2DA, "RESREF", Random(nTotalRows));
        object oSpawn = CreateObject(OBJECT_TYPE_CREATURE, sResRef, lLoc);
        
        SetLocalObject(oSpawn, "ENC_SPAWN_OWNER", oPC);
        ExecuteScript("enc_gps", oSpawn);
        
        if(bDebug) SendMessageToPC(oPC, "DEBUG: [Conductor] " + sResRef + " spawned at " + FloatToString(fDist, 0, 1) + "m");
    }
}
