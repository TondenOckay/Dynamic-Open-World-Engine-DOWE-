/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.1 (Area-Autonomous Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: area_switchboard
    
    PILLARS:
    1. Environmental Reactivity (Local Weather Config)
    2. Biological Persistence (Local Vitals Config)
    3. Optimized Scalability (Local Variable Siloing)
    4. Intelligent Population (Local DSE v7.0 Config)
    
    DESCRIPTION:
    The Area Configuration Hub. This script defines the "Registry" for THIS 
    specific area. By moving these from the Module to the Area, each area 
    functions as its own independent server instance.
    
    SYSTEM NOTES:
    * Triple-checked for 02/2026 Gold Standard.
    * NO Module-level dependencies for engine logic.
    * Add new "Movements" here to expand the local engine.
   ============================================================================
*/

// --- DOWE DEBUG SYSTEM ---
// Dense Annotation: This tracer targets the first PC in the specific area
// to verify that the local registry has initialized correctly.
void DOWE_Debug(string sMsg, object oArea) {
    if (GetLocalInt(oArea, "DOWE_DEBUG_MODE") == TRUE) {
        object oPC = GetFirstObjectInArea(oArea);
        if (GetIsObjectValid(oPC)) {
            SendMessageToPC(oPC, " [AREA SWITCHBOARD] -> " + sMsg);
        }
    }
}

void main() {
    // We target the Area Object as our "Local Registry Database."
    object oArea = OBJECT_SELF;

    // ========================================================================
    // MOVEMENT 1: POPULATION (DSE v7.0 Integration)
    // ========================================================================
    // LOGIC: Toggles spawning logic for THIS area only.
    SetLocalInt(oArea,    "DOWE_PKG_POP_ACTIVE", TRUE);
    // POINTER: The actual spawner/conductor logic script.
    SetLocalString(oArea, "DOWE_PKG_POP_SCRIPT", "enc_conductor");
    // JANITOR: The cleanup script for dead/outrun mobs.
    SetLocalString(oArea, "DOWE_JANITOR_SCRIPT", "enc_area_mgr");
    
    DOWE_Debug("Movement 1 [Population] Registered Locally.", oArea);


    // ========================================================================
    // MOVEMENT 2: BIOLOGICAL (VITALS / BIO-CORE)
    // ========================================================================
    // LOGIC: Toggle Hunger/Thirst/Fatigue logic for players in this area.
    SetLocalInt(oArea,    "DOWE_PKG_BIO_ACTIVE", TRUE);
    // POINTER: The biological engine script filename.
    SetLocalString(oArea, "DOWE_PKG_BIO_SCRIPT", "dowe_bio_core");
    
    DOWE_Debug("Movement 2 [Biological] Registered Locally.", oArea);


    // ========================================================================
    // MOVEMENT 3: ENVIRONMENTAL (WEATHER / CLIMATE)
    // ========================================================================
    // LOGIC: Controls regional weather/VFX shifts for this area.
    SetLocalInt(oArea,    "DOWE_PKG_ENV_ACTIVE", TRUE);
    // POINTER: The environmental core script.
    SetLocalString(oArea, "DOWE_PKG_ENV_SCRIPT", "dowe_env_core");
    
    DOWE_Debug("Movement 3 [Environmental] Registered Locally.", oArea);


    // ========================================================================
    // MOVEMENT 4: SOCIAL (FACT_ENGINE / REPUTATION)
    // ========================================================================
    // LOGIC: Toggle reputation processing for this zone.
    SetLocalInt(oArea,    "DOWE_PKG_FACT_ACTIVE", TRUE);
    SetLocalString(oArea, "DOWE_PKG_FACT_SCRIPT", "fact_engine");
    
    DOWE_Debug("Movement 4 [Social] Registered Locally.", oArea);


    // ========================================================================
    // LOCAL ENGINE CONFIGURATION
    // ========================================================================
    
    // DOWE_DEBUG_MODE: Master toggle for this specific area's debug logs.
    SetLocalInt(oArea, "DOWE_DEBUG_MODE", TRUE);
    
    // DOWE_VERSION: Tracking for local save compatibility.
    SetLocalFloat(oArea, "DOWE_VERSION", 2.1);

    DOWE_Debug("Synchronization Complete. Area Engine is CONFIGURED.", oArea);
}
