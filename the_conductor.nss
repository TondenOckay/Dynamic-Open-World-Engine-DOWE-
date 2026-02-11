/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.1 (Master Build - All-In-One Area Server)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: the_conductor
    
    PILLARS:
    1. Environmental Reactivity (Climate/Terrain/Context)
    2. Biological Persistence (Hunger/Thirst/Fatigue)
    3. Optimized Scalability (480-Player Phase-Staggering)
    4. Intelligent Population (DSE v7.0 Integration)
    
    DESCRIPTION:
    The complete "Mini-Server" orchestrator. This script handles its own 
    internal registry (Switchboard), its own recursive timing (Conductor), 
    and its own diagnostic reporting (Debug System).
    
    SYSTEM NOTES:
    * Built for 2026 High-Readability Standard.
    * Integrated with auto_save_inc v8.0 & area_mud_inc v8.0.
    * Self-terminating loops; zero overhead in empty areas.
   ============================================================================
*/

// // [2DA REFERENCE SECTION]
// // This script initializes the following 2DA-dependent movements:
// // Movement 1: enc_conductor -> (appearance.2da, placeables.2da)
// // Movement 2: dowe_bio_core -> (vitals_config.2da)
// // Movement 3: dowe_env_core -> (vfx_internal.2da, weather.2da)

// --- INTEGRATED DEBUG ENGINE ---
// Provides real-time feedback to players/DMs if DOWE_DEBUG_MODE is active.
void debug_engine(string sMsg, object oArea) {
    // Audit: Check local area first, then fall back to Module-level master toggle.
    if (GetLocalInt(oArea, "DOWE_DEBUG_MODE") || GetLocalInt(GetModule(), "DOWE_DEBUG_MODE")) {
        object oPC = GetFirstObjectInArea(oArea);
        while(GetIsObjectValid(oPC)) {
            if(GetIsPC(oPC)) {
                SendMessageToPC(oPC, " [AREA ENGINE] -> " + sMsg);
                return; // Efficiency: Exit loop after first PC notification.
            }
            oPC = GetNextObjectInArea(oArea);
        }
    }
}

// --- OCCUPANCY CHECK (O(n) Player List) ---
// Optimization: Looping GetFirstPC() is faster than GetFirstObjectInArea() 
// for module-wide occupancy checks on large player counts.
int GetIsAreaActive(object oArea) {
    object oPC = GetFirstPC();
    while (GetIsObjectValid(oPC)) {
        if (GetArea(oPC) == oArea && !GetIsDM(oPC)) return TRUE;
        oPC = GetNextPC();
    }
    return FALSE;
}

// --- MOVEMENT 1: POPULATION (DSE v7.0) ---
// TIMING: 30.0s Loop | OFFSET: 1.0s
void Movement_Population(object oArea) {
    // PHASE 1: RECURSION GUARD
    // If the area is empty, we kill the loop to save CPU main-thread cycles.
    if (!GetIsAreaActive(oArea)) {
        DeleteLocalInt(oArea, "DOWE_CONDUCTOR_RUNNING");
        debug_engine("DORMANT: Area empty. Terminating engine loops.", oArea);
        return;
    }

    // PHASE 2: PLUG-IN EXECUTION
    if (GetLocalInt(oArea, "DOWE_PKG_POP_ACTIVE")) {
        // Run Janitor/Watchdog logic to clear old/dead encounters.
        ExecuteScript(GetLocalString(oArea, "DOWE_JANITOR_SCRIPT"), oArea);
        
        // PC-Microstagger: Prevents O(n^2) spikes by spreading spawns across frames.
        float fStagger = 0.1;
        object oPC = GetFirstObjectInArea(oArea);
        while(GetIsObjectValid(oPC)) {
            if(GetIsPC(oPC) && !GetIsDM(oPC)) {
                DelayCommand(fStagger, ExecuteScript(GetLocalString(oArea, "DOWE_PKG_POP_SCRIPT"), oPC));
                fStagger += 0.2; // 200ms spacing between PC spawn checks.
            }
            oPC = GetNextObjectInArea(oArea);
        }
    }
    // PHASE 3: RECURSION
    DelayCommand(30.0, Movement_Population(oArea));
}

// --- MOVEMENT 2: BIOLOGICAL (Vitals Core) ---
// TIMING: 30.0s Loop | OFFSET: 11.0s
void Movement_Biological(object oArea) {
    // PHASE 1: SAFETY GUARD
    if (!GetLocalInt(oArea, "DOWE_CONDUCTOR_RUNNING")) return;

    // PHASE 2: PLUG-IN EXECUTION
    if (GetLocalInt(oArea, "DOWE_PKG_BIO_ACTIVE")) {
        string sScript = GetLocalString(oArea, "DOWE_PKG_BIO_SCRIPT");
        float fStagger = 0.1;
        object oPC = GetFirstObjectInArea(oArea);
        while (GetIsObjectValid(oPC)) {
            if (GetIsPC(oPC)) {
                // Apply hunger/thirst/fatigue logic per PC.
                DelayCommand(fStagger, ExecuteScript(sScript, oPC));
                fStagger += 0.1; // PC-Microstagger for 480-player load balancing.
            }
            oPC = GetNextObjectInArea(oArea);
        }
    }
    // PHASE 3: RECURSION
    DelayCommand(30.0, Movement_Biological(oArea));
}

// --- MOVEMENT 3: ENVIRONMENTAL (Weather/Climate) ---
// TIMING: 30.0s Loop | OFFSET: 21.0s
void Movement_Environmental(object oArea) {
    // PHASE 1: SAFETY GUARD
    if (!GetLocalInt(oArea, "DOWE_CONDUCTOR_RUNNING")) return;

    // PHASE 2: PLUG-IN EXECUTION
    if (GetLocalInt(oArea, "DOWE_PKG_ENV_ACTIVE")) {
        // Execute regional weather shifts and VFX updates.
        ExecuteScript(GetLocalString(oArea, "oArea", "DOWE_PKG_ENV_SCRIPT"), oArea);
    }
    // PHASE 3: RECURSION
    DelayCommand(30.0, Movement_Environmental(oArea));
}

// --- MAIN INITIALIZER ---
// TRIGGER: OnAreaEnter
void main() {
    object oArea = OBJECT_SELF;
    object oEnter = GetEnteringObject();

    // PHASE 1: GUARD CLAUSES
    if (!GetIsPC(oEnter) || GetIsDM(oEnter)) return;

    // PHASE 2: AUTO-REGISTRY (The Internal Switchboard)
    // Checks if THIS area instance is initialized. If not, stamps local registry.
    if (GetLocalString(oArea, "DOWE_PKG_POP_SCRIPT") == "") {
        // MOVEMENT 1: POPULATION
        SetLocalInt(oArea,    "DOWE_PKG_POP_ACTIVE", TRUE);
        SetLocalString(oArea, "DOWE_PKG_POP_SCRIPT", "enc_conductor");
        SetLocalString(oArea, "DOWE_JANITOR_SCRIPT", "enc_area_mgr");

        // MOVEMENT 2: BIOLOGICAL
        SetLocalInt(oArea,    "DOWE_PKG_BIO_ACTIVE", TRUE);
        SetLocalString(oArea, "DOWE_PKG_BIO_SCRIPT", "dowe_bio_core");

        // MOVEMENT 3: ENVIRONMENTAL
        SetLocalInt(oArea,    "DOWE_PKG_ENV_ACTIVE", TRUE);
        SetLocalString(oArea, "DOWE_PKG_ENV_SCRIPT", "dowe_env_core");

        // CONFIGURATION
        SetLocalInt(oArea, "DOWE_DEBUG_MODE", TRUE);
        debug_engine("Registry synchronized for " + GetName(oArea), oArea);
    }

    // PHASE 3: SINGLETON ENFORCEMENT
    if (GetLocalInt(oArea, "DOWE_CONDUCTOR_RUNNING")) return;

    // PHASE 4: IGNITION
    SetLocalInt(oArea, "DOWE_CONDUCTOR_RUNNING", TRUE);
    debug_engine("RAISING BATON: Ignition successful for " + GetName(oArea), oArea);

    // PHASE 5: STAGGERED ROLLOUT (The Symphony)
    // 1.0s Offset: Initial Population Pulse.
    DelayCommand(1.0,  Movement_Population(oArea));
    // 11.0s Offset: Separates Biological load from Spawning load.
    DelayCommand(11.0, Movement_Biological(oArea));
    // 21.0s Offset: Final environmental pulse completes the cycle.
    DelayCommand(21.0, Movement_Environmental(oArea));
}
