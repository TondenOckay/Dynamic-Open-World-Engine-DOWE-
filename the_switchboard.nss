/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: the_switchboard
    
    PILLARS:
    1. Environmental Reactivity (Movement 3 Slot)
    2. Biological Persistence (Movement 2 Slot)
    3. Optimized Scalability (Virtual Array / Plug-and-Play Architecture)
    4. Intelligent Population (Movement 1 Slot)
    
    DESCRIPTION:
    The Switchboard is the central "wiring" script for the DOWE Engine. It 
    populates the Global Variable Array on the Module object. This allows 
    the_conductor to remain a generic timing engine that looks here to 
    see which specific scripts it should "plug into" its 30-second cycle.
    
    INSTRUCTIONS:
    * Execute this script ONCE in the OnModuleLoad event.
    * To "Pull the Plug" on a system, set the PKG_ACTIVE variable to FALSE.
    * To "Hot-Swap" a system, change the PKG_SCRIPT string to a new filename.
   ============================================================================
*/

// [2DA REFERENCE SECTION]
// This script acts as a pointer and does not require specific 2DA data.
// It points to scripts like dse_engine_v7 which may utilize:
// appearances.2da, vfx_internal.2da, etc.

// --- DOWE DEBUG SYSTEM ---
// Dense Annotation: This is a standalone debug for the initialization phase.
// It confirms that the "Virtual Array" has been correctly populated.
void DOWE_Debug(string sMsg) {
    if (GetLocalInt(GetModule(), "DOWE_DEBUG_MODE") == TRUE) {
        // Broadcasts to the first available PC/DM during the loading/test phase.
        SendMessageToPC(GetFirstPC(), " [THE SWITCHBOARD] -> " + sMsg);
    }
}

void main() {
    // We target the Module Object as our "Registry Database."
    object oMod = GetModule();

    // ========================================================================
    // MOVEMENT 1: POPULATION (DSE v7.0)
    // TIMING: Starts at 0.0s in the Conductor Cycle.
    // ========================================================================
    // LOGIC: Determines if the spawn engine is operational.
    SetLocalInt(oMod,    "DOWE_PKG_POP_ACTIVE", TRUE);
    // POINTER: The actual script filename to be called by the Conductor.
    SetLocalString(oMod, "DOWE_PKG_POP_SCRIPT", "dse_engine_v7");
    
    DOWE_Debug("Movement 1 [Population] wired to: " + GetLocalString(oMod, "DOWE_PKG_POP_SCRIPT"));


    // ========================================================================
    // MOVEMENT 2: BIOLOGICAL (VITALS / BIO-CORE)
    // TIMING: Starts at 10.0s in the Conductor Cycle (Phase-Staggered).
    // ========================================================================
    // LOGIC: Set to FALSE to pause Hunger/Thirst/Fatigue globally.
    SetLocalInt(oMod,    "DOWE_PKG_BIO_ACTIVE", TRUE);
    // POINTER: The biological engine script (e.g., dowe_bio_core).
    SetLocalString(oMod, "DOWE_PKG_BIO_SCRIPT", "dowe_bio_core");
    
    DOWE_Debug("Movement 2 [Biological] wired to: " + GetLocalString(oMod, "DOWE_PKG_BIO_SCRIPT"));


    // ========================================================================
    // MOVEMENT 3: ENVIRONMENTAL (WEATHER / CLIMATE)
    // TIMING: Starts at 20.0s in the Conductor Cycle.
    // ========================================================================
    // LOGIC: Toggles regional weather and environmental VFX.
    SetLocalInt(oMod,    "DOWE_PKG_ENV_ACTIVE", TRUE);
    // POINTER: The environmental engine script (e.g., dowe_env_core).
    SetLocalString(oMod, "DOWE_PKG_ENV_SCRIPT", "dowe_env_core");
    
    DOWE_Debug("Movement 3 [Environmental] wired to: " + GetLocalString(oMod, "DOWE_PKG_ENV_SCRIPT"));


    // ========================================================================
    // GLOBAL ENGINE CONFIGURATION
    // ========================================================================
    
    // DOWE_DEBUG_MODE: The master toggle for all "DOWE_Debug" calls.
    // Set this to TRUE during development. Set to FALSE for the live 480-player release.
    SetLocalInt(oMod, "DOWE_DEBUG_MODE", TRUE);
    
    // DOWE_VERSION: Tracking the Master Build version.
    SetLocalFloat(oMod, "DOWE_VERSION", 2.0);

    DOWE_Debug("All virtual plugs are hot. DOWE v2.0 Initialization Complete.");
}
