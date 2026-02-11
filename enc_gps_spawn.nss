/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: enc_gps_spawn
    
    PILLARS:
    1. Environmental Reactivity (Area-Silo Spawning)
    3. Optimized Scalability (2DA Throttled Loading)
    4. Intelligent Population (Fixed-Point Registration)
    
    DESCRIPTION:
    The Area-Centric Location Engine. This script initializes "Static" encounters 
    from the area's specific [AreaTag]_gps_loc.2da. It ensures that fixed-point 
    mobs are spawned only once when the area wakes up and are properly 
    stamped with IDs for the Blind AI system.
    
    SYSTEM NOTES:
    * Triple-checked for 02/2026 High-Readability Standard.
    * Uses "Isolated Cell" logic: Does not touch global module variables.
    * Integrated with DOWE Debug System (DOWE_DEBUG_MODE).
   ============================================================================
*/

// // 2DA REFERENCE: [AreaTag]_gps_loc.2da
// // ---------------------------------------------------------------------------
// // ID | POS_X | POS_Y | POS_Z | RESREF | ORIENTATION
// // ---------------------------------------------------------------------------
// // Note: Row ID is used as the link to [AreaTag]_patrols.2da

void main() {
    // PHASE 0: INITIALIZATION
    object oArea = OBJECT_SELF;
    string sAreaTag = GetTag(oArea);
    int bDebug = GetLocalInt(GetModule(), "DOWE_DEBUG_MODE");

    // PHASE 1: SILO GATEKEEPER (The "Wake Up" Guard)
    // We only spawn these creatures if the area is not already marked as active.
    // This prevents duplicate spawns when multiple players enter the area.
    if (GetLocalInt(oArea, "DOWE_AREA_ACTIVE")) return;
    
    // Mark area as active so this script only runs once per "session".
    SetLocalInt(oArea, "DOWE_AREA_ACTIVE", TRUE);

    // PHASE 2: LOCALIZED 2DA ACCESS
    // Dynamically builds the filename based on the Area's Tag for 100% independence.
    string s2DA = sAreaTag + "_gps_loc";
    int nRows = Get2DARowCount(s2DA);

    // Guard: If the 2DA is missing or empty, shut down to save cycles.
    if (nRows <= 0) {
        if(bDebug) SendMessageToPC(GetFirstPC(), "DEBUG: [enc_gps_spawn] No 2DA found for " + s2DA);
        return;
    }

    // PHASE 3: THE SPAWN LOOP (Phased Execution)
    int i;
    for(i = 0; i < nRows; i++) {
        // Data Retrieval from the Area-Specific Silo
        string sResRef = Get2DAString(s2DA, "RESREF", i);
        
        // Skip invalid rows or comments in the 2DA
        if (sResRef == "" || sResRef == "****") continue;

        // Coordinate Capture: Capturing X, Y, Z for 3D spatial accuracy.
        float fX = StringToFloat(Get2DAString(s2DA, "POS_X", i));
        float fY = StringToFloat(Get2DAString(s2DA, "POS_Y", i));
        float fZ = StringToFloat(Get2DAString(s2DA, "POS_Z", i));
        float fFacing = StringToFloat(Get2DAString(s2DA, "ORIENTATION", i));

        // Create the 3D Location Object
        location lSpawn = Location(oArea, Vector(fX, fY, fZ), fFacing);
        
        // Creature Generation
        object oSpawn = CreateObject(OBJECT_TYPE_CREATURE, sResRef, lSpawn);

        // PHASE 4: STAMPING & REGISTRATION
        // Link this creature to its 2DA ID. The Blind AI (enc_gps_ai) uses 
        // this ID to find the correct patrol path in the _patrols 2DA.
        int nGPS_ID = StringToInt(Get2DAString(s2DA, "ID", i));
        SetLocalInt(oSpawn, "DOWE_GPS_SPAWN_ID", nGPS_ID);

        // SYNC: Register this creature with the Eye in the Sky (Area List).
        // This makes the creature visible to the Area Manager for cleanup later.
        ExecuteScript("enc_gps", oSpawn);

        // PHASE 5: DEBUG LOGGING
        if(bDebug) {
            SendMessageToPC(GetFirstPC(), "DEBUG: [enc_gps_spawn] Created: " + sResRef + " [GPS_ID: " + IntToString(nGPS_ID) + "]");
        }
    }
}
