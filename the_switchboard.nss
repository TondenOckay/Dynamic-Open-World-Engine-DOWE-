/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.1 (Master Build - Faction/Social Integration)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: the_switchboard
    
    PILLARS:
    1. Environmental Reactivity (Movement 3 - Climate/Weather)
    2. Biological Persistence (Movement 2 - Vitals/Bio)
    3. Optimized Scalability (Virtual Array / Plug-and-Play Architecture)
    4. Intelligent Population (Movement 1 - Spawning | Movement 4 - Factions)
    
    DESCRIPTION:
    The Switchboard is the master configuration hub for the DOWE Engine. It 
    defines the "Global Variable Array" on the Module object. This decoupling 
    allows 'the_conductor' to remain a generic timing engine—it simply looks 
    here to see which specific scripts are currently "plugged in" for each 
    7.5-second phase (Movement) of the 30-second master cycle.
    
    PHASE-STAGGERING (480-Player Target):
    * Movement 1: 0.0s
    * Movement 2: 7.5s
    * Movement 3: 15.0s
    * Movement 4: 22.5s
    
    INSTRUCTIONS:
    * Execute this script ONCE in the OnModuleLoad event.
    * To "Pull the Plug" on a system, set the PKG_ACTIVE variable to FALSE.
    * To "Hot-Swap" a system, change the PKG_SCRIPT string to a new filename.
   ============================================================================
*/

// --- DOWE DEBUG SYSTEM ---
// Dense Annotation: This is the primary initialization tracer. It verifies 
// that the Virtual Array is correctly populated before players login.
void DOWE_Debug(string sMsg) {
    if (GetLocalInt(GetModule(), "DOWE_DEBUG_MODE") == TRUE) {
        // Broadcasts to the first available PC/DM during the initialization phase.
        SendMessageToPC(GetFirstPC(), " [THE SWITCHBOARD] -> " + sMsg);
    }
}

void main() {
    // We target the Module Object as our central "Registry Database."
    object oMod = GetModule();

    // ========================================================================
    // MOVEMENT 1: POPULATION (DSE v7.0 Integration)
    // TIMING: Starts at 0.0s in the Conductor Cycle.
    // ========================================================================
    // LOGIC: Toggles the entire Dynamic Spawn Engine (DSE).
    SetLocalInt(oMod,    "DOWE_PKG_POP_ACTIVE", TRUE);
    // POINTER: The actual script filename (DSE v7.0 Annotated Master).
    SetLocalString(oMod, "DOWE_PKG_POP_SCRIPT", "dse_engine_v7");
    
    DOWE_Debug("Movement 1 [Population] wired to: " + GetLocalString(oMod, "DOWE_PKG_POP_SCRIPT"));


    // ========================================================================
    // MOVEMENT 2: BIOLOGICAL (VITALS / BIO-CORE)
    // TIMING: Starts at 7.5s in the Conductor Cycle (Phase-Staggered).
    // ========================================================================
    // LOGIC: Set to FALSE to globally freeze Hunger, Thirst, and Fatigue.
    SetLocalInt(oMod,    "DOWE_PKG_BIO_ACTIVE", TRUE);
    // POINTER: The biological engine script filename.
    SetLocalString(oMod, "DOWE_PKG_BIO_SCRIPT", "dowe_bio_core");
    
    DOWE_Debug("Movement 2 [Biological] wired to: " + GetLocalString(oMod, "DOWE_PKG_BIO_SCRIPT"));


    // ========================================================================
    // MOVEMENT 3: ENVIRONMENTAL (WEATHER / CLIMATE)
    // TIMING: Starts at 15.0s in the Conductor Cycle.
    // ========================================================================
    // LOGIC: Controls regional weather shifts and environmental VFX triggers.
    SetLocalInt(oMod,    "DOWE_PKG_ENV_ACTIVE", TRUE);
    // POINTER: The environmental core script (weather_inc v8.0 compatible).
    SetLocalString(oMod, "DOWE_PKG_ENV_SCRIPT", "dowe_env_core");
    
    DOWE_Debug("Movement 3 [Environmental] wired to: " + GetLocalString(oMod, "DOWE_PKG_ENV_SCRIPT"));


    // ========================================================================
    // MOVEMENT 4: SOCIAL (FACT_ENGINE / REPUTATION)
    // TIMING: Starts at 22.5s in the Conductor Cycle.
    // ========================================================================
    // LOGIC: Processes the -1000/+1000 Reputation math and Rank caching.
    // This provides the data needed for mud_store and mud_quest.
    SetLocalInt(oMod,    "DOWE_PKG_FACT_ACTIVE", TRUE);
    // POINTER: The Social Engine script (fact_engine Master Build).
    SetLocalString(oMod, "DOWE_PKG_FACT_SCRIPT", "fact_engine");
    
    DOWE_Debug("Movement 4 [Social] wired to: " + GetLocalString(oMod, "DOWE_PKG_FACT_SCRIPT"));


    // ========================================================================
    // GLOBAL ENGINE CONFIGURATION
    // ========================================================================
    
    // DOWE_DEBUG_MODE: The master toggle for all "DOWE_Debug" calls.
    // Set to TRUE for development; FALSE for performance-critical production.
    SetLocalInt(oMod, "DOWE_DEBUG_MODE", TRUE);
    
    // DOWE_VERSION: Tracks the current engine iteration for save-compatibility.
    SetLocalFloat(oMod, "DOWE_VERSION", 2.1);

    DOWE_Debug("Switchboard Synchronization Complete. DOWE v2.1 is LIVE.");
}
