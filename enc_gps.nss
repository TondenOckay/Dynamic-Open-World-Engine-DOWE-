/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: enc_gps
    
    PILLARS:
    3. Optimized Scalability (Area-Specific ID Tracking)
    4. Intelligent Population (Automated List Management)
    
    DESCRIPTION:
    The "Eye in the Sky" Registration. Assigns a unique ID to every creature
    within its specific area silo. This allows the Area Manager to index 
    creatures by integer rather than using expensive "GetNearest" loops.
    
    SYSTEM NOTES:
    * Triple-checked for 02/2026 High-Readability Standard.
    * No GetLocalObject on Module; uses local Area variables only.
    * Phased execution: Assign ID -> Register -> Inherit Owner.
   ============================================================================
*/
void main() {
    // PHASE 0: INITIALIZATION
    // We isolate the object and area to ensure the script only affects its local silo.
    object oSelf = OBJECT_SELF;
    object oArea = GetArea(oSelf);
    int bDebug = GetLocalInt(GetModule(), "DOWE_DEBUG_MODE");
    // PHASE 1: AREA-ID ASSIGNMENT
    // We increment a local counter on the area itself. This creates a virtual 
    // database of every mob in this specific map. Zero global cross-talk.
    int nAreaID = GetLocalInt(oArea, "DOWE_AREA_LAST_ID") + 1;
    SetLocalInt(oArea, "DOWE_AREA_LAST_ID", nAreaID);
    SetLocalInt(oSelf, "DOWE_ID", nAreaID);
    // PHASE 2: AREA LIST REGISTRATION
    // Store the object reference on the area using the ID as the unique key.
    // This allows the Janitor (enc_area_mgr) to find this mob instantly.
    SetLocalObject(oArea, "ENC_OBJ_" + IntToString(nAreaID), oSelf);
    // PHASE 3: OWNERSHIP INHERITANCE
    // If the conductor spawned this mob, it carries a temporary owner reference.
    // We convert this to a persistent tag for the ownership transfer system.
    object oOwner = GetLocalObject(oSelf, "ENC_SPAWN_OWNER");
    if(GetIsObjectValid(oOwner)) {
        SetLocalString(oSelf, "DOWE_OWNER_TAG", GetPCPlayerName(oOwner));
    }
    // PHASE 4: DEBUG TELEMETRY
    // Only fires if the debug system is active; provides GPS registration feedback.
    if(bDebug) {
        SendMessageToPC(GetFirstPC(), "DEBUG: [enc_gps] ID " + IntToString(nAreaID) + " Registered in " + GetTag(oArea));
    }
}
