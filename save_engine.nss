/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: save_engine
    
    PILLARS:
    3. Optimized Scalability (JSON Persistence Architecture)
    
    DESCRIPTION:
    The master persistence bridge. This engine synchronizes real-time "Hot" 
    Local Variables (Hunger, Thirst, Fatigue, Location) into a "Cold" JSON 
    structure. This JSON acts as a cross-server 'passport', allowing players 
    to maintain state across different server instances or module resets.
    
    SYSTEM NOTES:
    * Triple-Checked for 2026 Gold Standard High-Readability.
    * Uses Campaign JSON for native persistence without external SQL dependency.
    * Staggered Execution: Targeted at the PC during the save cycle.
   ============================================================================
*/

// [2DA REFERENCE SECTION]
// // This engine does not require 2DAs as it maps Local Variables 
// // directly to JSON keys: "hunger", "thirst", "fatigue", "loc".

// --- DOWE DEBUG SYSTEM ---
// Integrated tracer: Only sends messages if the Module's Debug Mode is TRUE.
void Save_Debug(string sMsg, object oPC) {
    if (GetLocalInt(GetModule(), "DOWE_DEBUG_MODE") == TRUE) {
        SendMessageToPC(oPC, " [SAVE_ENGINE] -> " + sMsg);
    }
}

void main() {
    // PHASE 1: TARGET ACQUISITION & VALIDATION
    // The Conductor (or a Heartbeat) executes this ON the PC.
    object oPC = OBJECT_SELF;

    // Safety Guard: Do not attempt to save DMs or invalid objects.
    if (!GetIsPC(oPC) || GetIsDM(oPC)) return;

    // PHASE 2: DATA HARVESTING (HOT CACHE)
    // We pull the fast-access variables that the bio_engine has been updating.
    int nHunger  = GetLocalInt(oPC, "VITAL_HUNGER");
    int nThirst  = GetLocalInt(oPC, "VITAL_THIRST");
    int nFatigue = GetLocalInt(oPC, "VITAL_FATIGUE");
    location lLoc = GetLocation(oPC);

    // PHASE 3: JSON CONSOLIDATION (THE PASSPORT)
    // We bundle all biological and spatial data into a single JSON object.
    // This reduces database "Hits" to a single write operation.
    json jPassport = JsonObject();
    
    // Set Biological Data
    jPassport = JsonObjectSet(jPassport, "hunger",  JsonInt(nHunger));
    jPassport = JsonObjectSet(jPassport, "thirst",  JsonInt(nThirst));
    jPassport = JsonObjectSet(jPassport, "fatigue", JsonInt(nFatigue));
    
    // Set Spatial Data (Handles Area Tag, Vector, and Facing automatically)
    jPassport = JsonObjectSet(jPassport, "loc", JsonLocation(lLoc));

    // PHASE 4: PERSISTENCE (COLD STORAGE)
    // We commit the JSON to the Campaign Database. 
    // This is stored in the "DOWE_VAULT.gff" in the server's database folder.
    string sPublicCDK = GetPCPublicCDKey(oPC);
    string sCharName  = GetName(oPC);
    string sStorageID = sPublicCDK + "_" + sCharName;

    // Save the JSON structure to the permanent campaign file.
    SetCampaignJson("DOWE_VAULT", sStorageID, jPassport);
    
    // Redundancy: Store it on the PC object for instant server-hop retrieval.
    SetLocalJson(oPC, "JSON_PASSPORT", jPassport);

    // PHASE 5: TECHNICAL TRACER (DEBUG)
    Save_Debug("Persistence Synced: Vitals & Location archived to JSON Vault.", oPC);
    Save_Debug("Snapshot Key: " + sStorageID, oPC);
}
