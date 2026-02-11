/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: enc_conductor
    
    PILLARS:
    1. Environmental Reactivity (Surface-Specific Lists & Wake Ripple)
    3. Optimized Scalability (King of the Hill ID Guard & 1-Enc Limit)
    4. Intelligent Population (Mob-Stacking Prevention)
    
    DESCRIPTION:
    The Central Brain. This script manages both dynamic spawning and the 
    stasis-wake logic for static GPS creatures. It ensures only one player 
    in a group triggers spawns by using the Lowest Object ID Gate.
    
    SYSTEM NOTES:
    * Triple-checked for 02/2026 Gold Standard.
    * Phase-Staggered: Terminates early if player is a 'Follower' or in Combat.
    * Integrated with GPS Stasis: Wakes static mobs within 40m.
   ============================================================================
*/

// // 2DA REFERENCE: [AreaTag]_[Rarity].2da
// // ---------------------------------------------------------------------------
// // RESREF (String) | WEIGHT (Optional)
// // ---------------------------------------------------------------------------

void main() {
    // PHASE 0: INITIALIZATION & DEBUG
    object oPC = OBJECT_SELF;
    object oArea = GetArea(oPC);
    int bDebug = GetLocalInt(GetModule(), "DOWE_DEBUG_MODE");
    int nCurrentTime = GetTimeSecond() + (GetTimeMinute() * 60);

    // PHASE 1: THE "KING OF THE HILL" & COMBAT GATE
    // We check if this PC is the 'Leader' of their immediate 30m circle.
    // We also check for nearby combat to prevent "Mob Stacking" on a fight.
    object oNearPC = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oNearPC)) {
        if (GetIsPC(oNearPC) && oNearPC != oPC && !GetIsDM(oNearPC)) {
            float fPCDist = GetDistanceBetween(oPC, oNearPC);
            if (fPCDist <= 30.0) {
                // STACKING GUARD: If a nearby PC has a lower ID, they are the Leader.
                // This PC becomes a 'Follower' and stops execution to save CPU.
                if (ObjectToInt(oNearPC) < ObjectToInt(oPC)) {
                    if (bDebug) SendMessageToPC(oPC, "DEBUG: Follower Mode. Leader: " + GetName(oNearPC));
                    return; 
                }
                // COMBAT GUARD: If the neighbor is already fighting, don't add more heat.
                if (GetIsInCombat(oNearPC)) return;
            }
        }
        oNearPC = GetNextObjectInArea(oArea);
    }

    // Self-Combat Check: Leaders don't spawn while fighting.
    if (GetIsInCombat(oPC)) return;

    // PHASE 2: PROXIMITY WAKE-UP RIPPLE
    // Even if the 40% roll fails later, the Leader's presence wakes up static guards.
    // We loop the Area's GPS list (O(n)) rather than a sphere search (CPU Heavy).
    int nLastID = GetLocalInt(oArea, "DOWE_AREA_LAST_ID");
    int j;
    for(j = 1; j <= nLastID; j++) {
        object oC = GetLocalObject(oArea, "ENC_OBJ_" + IntToString(j));
        if(GetIsObjectValid(oC)) {
            // Wake up static guards within 40m.
            if(GetDistanceBetween(oPC, oC) <= 40.0) {
                SetLocalInt(oC, "DOWE_WAKE_TIME", nCurrentTime);
                if(bDebug) SendMessageToPC(oPC, "DEBUG: Waking static GPS ID: " + IntToString(j));
            }
        }
    }

    // PHASE 3: ENCOUNTER LIMIT & CHANCE ROLL
    // Limit: One active encounter per PC.
    if (GetLocalInt(oPC, "DOWE_ACTIVE_ENC")) return;
    
    // Chance: Only 40% of pulses trigger a new spawn.
    if (d100() > 40) return;

    // PHASE 4: RARITY & 2DA SELECTION
    // Determine rarity bucket: Rare (15%), Uncommon (25%), Common (60%).
    int nRoll = d100();
    string sRarity = (nRoll > 85) ? "rare" : (nRoll > 60 ? "uncommon" : "common");
    string s2DA = GetTag(oArea) + "_" + sRarity;
    
    int nTotalRows = Get2DARowCount(s2DA);
    if (nTotalRows <= 0) {
        if(bDebug) SendMessageToPC(oPC, "DEBUG: 2DA " + s2DA + " not found or empty.");
        return;
    }

    // PHASE 5: DISTANCE WEIGHTING
    // Weights: 15% at 5m, 70% at 15-25m, 15% at 30m.
    int nDistRoll = d100();
    float fDist = 15.0 + (IntToFloat(Random(101)) / 10.0); // Default 15-25m
    if (nDistRoll <= 15) fDist = 5.0; 
    else if (nDistRoll > 85) fDist = 30.0;

    // PHASE 6: SPAWN EXECUTION (1-4 Creatures)
    int nAmount = d4(); 
    int i;
    for(i = 0; i < nAmount; i++) {
        // Offset math to prevent clumping
        float fAngle = IntToFloat(Random(360));
        vector vSpawn = GetPosition(oPC);
        vSpawn.x += fDist * cos(fAngle); 
        vSpawn.y += fDist * sin(fAngle);
        location lLoc = Location(oArea, vSpawn, 0.0);
        
        string sResRef = Get2DAString(s2DA, "RESREF", Random(nTotalRows));
        object oSpawn = CreateObject(OBJECT_TYPE_CREATURE, sResRef, lLoc);
        
        // Ownership stamp for the Watchdog system
        SetLocalObject(oSpawn, "ENC_SPAWN_OWNER", oPC);
        SetLocalInt(oSpawn, "IS_PLAYER_ENCOUNTER", TRUE);
        
        // Run the Zero-Heartbeat Push AI and GPS registration
        ExecuteScript("enc_gps", oSpawn); 
        
        if(bDebug) SendMessageToPC(oPC, "DEBUG: Spawned " + sResRef + " at " + FloatToString(fDist, 1) + "m");
    }

    // Lock the PC's encounter slot. This is freed by enc_mob_check or enc_on_death.
    SetLocalInt(oPC, "DOWE_ACTIVE_ENC", TRUE);
}
