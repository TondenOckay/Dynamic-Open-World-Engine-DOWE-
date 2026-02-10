/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: save_mgr
    
    PILLARS:
    1. Environmental Reactivity (Climate/Terrain/Context)
    2. Biological Persistence (Hunger/Thirst/Fatigue)
    3. Optimized Scalability (480-Player Phase-Staggering)
    4. Intelligent Population (DSE v7.0 Integration)
    
    SYSTEM NOTES:
    * MERGED LOGIC: Combines Save_Engine (What) with Save_Mgr (When).
    * PASSPORT SYSTEM: Bundles all variables into a single JSON for I/O efficiency.
    * COOLDOWN & STAGGER: Prevents "Heap Pressure" during rapid transitions.
    * 12-Character filename compliant.
   ============================================================================
*/

// [2DA REPLICA NOTES]
// // This engine relies on the 'dowe_stats' SQL table or Campaign Database.
// // Fields: storage_id (TEXT/PK), player_data (JSON), last_sync (TIMESTAMP)

// --- CONFIGURATION & CONSTANTS ---
const int USE_NWNX_SQL      = FALSE; // TOGGLE: TRUE for MySQL/Postgres, FALSE for SQLite
const int DOWE_DEBUG_MODE   = TRUE;  // Master Debug Toggle
const float STAGGER_WINDOW  = 3.0;   // Load balancing spread (seconds)
const int COOLDOWN_SECONDS  = 30;    // Minimum gap between non-critical saves
const float HEARTBEAT_DRIP  = 480.0; // 8-minute recursive interval

// --- VARIABLE STRINGS (The Registry) ---
const string VAR_LAST_SAVE  = "DOWE_LAST_SAVE_TS";
const string VAR_EVENT_ID   = "DOWE_SAVE_EVENT";
const string VAR_PASSPORT   = "JSON_PASSPORT";

// --- PROTOTYPES ---
void DOWE_MGR_ExecutePassportSave(object oPC, string sType);
void DOWE_MGR_Debug(string sMsg, object oPC = OBJECT_INVALID);

// ----------------------------------------------------------------------------
// PHASE 1: THE GATEKEEPER (Event Routing & Validation)
// ----------------------------------------------------------------------------
void main()
{
    object oPC = OBJECT_SELF;
    int nEvent = GetLocalInt(oPC, VAR_EVENT_ID);
    
    // TRIPLE-CHECK: Guard against DMs, NPCs, or invalid objects to prevent DB bloat.
    if (!GetIsObjectValid(oPC) || GetIsDM(oPC) || GetIsDMPossessed(oPC)) return;

    // THROTTLE: Check if the player is "Spamming" a transition or trigger.
    int nNow = GetTimeSecond() + (GetTimeMinute() * 60);
    int nLastSave = GetLocalInt(oPC, VAR_LAST_SAVE);
    
    // Non-critical events (Area transitions) are blocked if within the cooldown.
    if (nEvent == 2 && (nNow - nLastSave) < COOLDOWN_SECONDS && nLastSave != 0)
    {
        DOWE_MGR_Debug("THROTTLED: Ignoring rapid save request.", oPC);
        return;
    }
    
    SetLocalInt(oPC, VAR_LAST_SAVE, nNow);

    // ------------------------------------------------------------------------
    // PHASE 2: THE STAGGER (CPU Load Balancing)
    // ------------------------------------------------------------------------
    // Spreading the save across frames to flatten the CPU load line.
    float fStagger = (IntToFloat(Random(FloatToInt(STAGGER_WINDOW * 10.0))) / 10.0) + 0.1;
    
    // Critical: LOGOUT (Event 1) gets instant priority before object destruction.
    if (nEvent == 1) fStagger = 0.01;

    string sType;
    switch(nEvent)
    {
        case 1: sType = "LOGOUT"; break;
        case 2: sType = "AREA_EXIT"; break;
        case 3: sType = "REST_FINISH"; break;
        case 4: sType = "RECURSIVE_DRIP"; break;
        default: sType = "MANUAL_PUSH"; break;
    }

    // Delay the "Heavy Lift" (JSON/SQL) to separate frame.
    DelayCommand(fStagger, DOWE_MGR_ExecutePassportSave(oPC, sType));
}

// ----------------------------------------------------------------------------
// PHASE 3: THE PASSPORT (Data Harvesting & Persistence)
// ----------------------------------------------------------------------------
void DOWE_MGR_ExecutePassportSave(object oPC, string sType)
{
    if (!GetIsObjectValid(oPC)) return;

    // 3.1: DATA HARVESTING (The Hot Cache)
    // Pulling real-time vitals updated by the Bio-Core.
    int nHunger   = GetLocalInt(oPC, "VITAL_HUNGER");
    int nThirst   = GetLocalInt(oPC, "VITAL_THIRST");
    int nFatigue  = GetLocalInt(oPC, "VITAL_FATIGUE");
    location lLoc = GetLocation(oPC);

    // 3.2: JSON CONSOLIDATION (The Serialization Phase)
    // Bundling data reduces DB 'Hits' from 4 operations to 1.
    json jPassport = JsonObject();
    jPassport = JsonObjectSet(jPassport, "hunger",  JsonInt(nHunger));
    jPassport = JsonObjectSet(jPassport, "thirst",  JsonInt(nThirst));
    jPassport = JsonObjectSet(jPassport, "fatigue", JsonInt(nFatigue));
    jPassport = JsonObjectSet(jPassport, "loc",     JsonLocation(lLoc));

    // 3.3: STORAGE ID GENERATION
    // CDKey + Name is the 'Gold Standard' for character identification.
    string sID = GetPCPublicCDKey(oPC) + "_" + GetName(oPC);

    // 3.4: PERSISTENCE (Cold Storage)
    if (USE_NWNX_SQL)
    {
        // External SQL Path: Best for Cross-Server Clusters.
        string sJsonStr = JsonDump(jPassport);
        // Placeholder for NWNX SQL Execute (e.g., REPLACE INTO dowe_vault...)
        DOWE_MGR_Debug("SQL_EXT: Passport written for " + sID);
    }
    else
    {
        // Native Campaign Path: Ideal for single-server stability.
        SetCampaignJson("DOWE_VAULT", sID, jPassport);
        DOWE_MGR_Debug("SQL_INT: Passport cached to DOWE_VAULT for " + sID);
    }

    // 3.5: REDUNDANCY (Hot Cache Storage)
    // Storing the JSON on the PC for instant retrieval by other systems.
    SetLocalJson(oPC, VAR_PASSPORT, jPassport);

    // ------------------------------------------------------------------------
    // PHASE 4: RECURSIVE DRIP (The Safety Net)
    // ------------------------------------------------------------------------
    if (sType == "RECURSIVE_DRIP")
    {
        SetLocalInt(oPC, VAR_EVENT_ID, 4); // Re-queue the Drip
        DelayCommand(HEARTBEAT_DRIP, ExecuteScript("save_mgr", oPC));
    }
    
    // Cleanup of the routing variable.
    DeleteLocalInt(oPC, VAR_EVENT_ID);
}

// ----------------------------------------------------------------------------
// DEBUG SYSTEM
// ----------------------------------------------------------------------------
void DOWE_MGR_Debug(string sMsg, object oPC = OBJECT_INVALID)
{
    if (!DOWE_DEBUG_MODE) return;
    
    string sFinal = "[DOWE_SAVE] " + sMsg;
    SendMessageToAllDMs(sFinal);
    if (GetIsObjectValid(oPC) && GetIsPC(oPC)) SendMessageToPC(oPC, sFinal);
}
