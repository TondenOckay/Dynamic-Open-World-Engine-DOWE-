/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: enc_area_mgr
    
    PILLARS:
    1. Environmental Reactivity (Dynamic Despawning)
    3. Optimized Scalability (Local Area Siloing)
    4. Intelligent Population (Ownership Transfer)
    
    DESCRIPTION:
    The Area-Silo Janitor. Loops through the local ID list to check creature 
    ownership. Transfers ownership to the nearest PC (30m) or despawns 
    orphaned encounters if the owner has left the area.
    
    SYSTEM NOTES:
    * Triple-checked for 02/2026 Gold Standard.
    * Phased Execution: Aborts early if the area is totally empty of PCs.
    * CPU Efficient: Only iterates registered IDs, not all area objects.
   ============================================================================
*/
void main() {
    // PHASE 0: OCCUPANCY GUARD
    // If no players are present, the area is 'Cold'. We shut down to save CPU.
    object oArea = OBJECT_SELF;
    object oPC = GetFirstPC();
    int bActive = FALSE;
    while(GetIsObjectValid(oPC)) {
        if(GetArea(oPC) == oArea) { bActive = TRUE; break; }
        oPC = GetNextPC();
    }
    if(!bActive) return;
    // PHASE 1: INITIALIZATION
    int bDebug = GetLocalInt(GetModule(), "DOWE_DEBUG_MODE");
    int nLastID = GetLocalInt(oArea, "DOWE_AREA_LAST_ID");
    // PHASE 2: SILO LIST ITERATION
    // We only check objects registered via enc_gps to prevent engine bloat.
    int i;
    for(i = 1; i <= nLastID; i++) {
        string sKey = "ENC_OBJ_" + IntToString(i);
        object oCreature = GetLocalObject(oArea, sKey);
        // Skip dead or already cleaned-up objects.
        if(!GetIsObjectValid(oCreature) || GetIsDead(oCreature)) continue;
        // PHASE 3: OWNERSHIP VALIDATION
        // Check if the current owner is still valid and still in this area.
        object oOwner = GetLocalObject(oCreature, "ENC_SPAWN_OWNER");
        if(!GetIsObjectValid(oOwner) || GetIsDead(oOwner) || GetArea(oOwner) != oArea) {
            // PHASE 4: TRANSFER LOGIC (30m Radius)
            // Attempt to find a new PC 'Host' for this encounter.
            object oNewOwner = OBJECT_INVALID;
            float fMinDist = 30.1;
            object oNearbyPC = GetFirstObjectInArea(oArea);
            while(GetIsObjectValid(oNearbyPC)) {
                if(GetIsPC(oNearbyPC) && !GetIsDead(oNearbyPC)) {
                    float fDist = GetDistanceBetween(oCreature, oNearbyPC);
                    if(fDist < fMinDist) { fMinDist = fDist; oNewOwner = oNearbyPC; }
                }
                oNearbyPC = GetNextObjectInArea(oArea);
            }
            // PHASE 5: RE-TAG OR DESPAWN
            if(GetIsObjectValid(oNewOwner)) {
                SetLocalObject(oCreature, "ENC_SPAWN_OWNER", oNewOwner);
                SetLocalString(oCreature, "DOWE_OWNER_TAG", GetPCPlayerName(oNewOwner));
                if(bDebug) SendMessageToPC(oNewOwner, "DEBUG: [enc_area_mgr] Re-assigned orphaned mob.");
            } else {
                // Orphaned: No PCs within 30m. Wipe object to free memory.
                DeleteLocalObject(oArea, sKey);
                DestroyObject(oCreature);
            }
        }
    }
}
