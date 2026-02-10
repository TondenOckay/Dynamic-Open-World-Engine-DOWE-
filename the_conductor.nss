/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: the_conductor
    
    PILLARS:
    1. Environmental Reactivity (Movement 3 Slot)
    2. Biological Persistence (Movement 2 Slot)
    3. Optimized Scalability (480-Player Phase-Staggering)
    4. Intelligent Population (Movement 1 Slot)
    
    SYSTEM NOTES:
    * THE CONDUCTOR: Master 30.0s timing socket.
    * 2026 MASTER BUILD: Replaces heavy Heartbeats with staggered DelayCommands.
    * PLUG-AND-PLAY: Logic is decoupled via the 'the_switchboard' Registry.
    * CPU EFFICIENCY: Self-terminating loops; zero overhead in empty areas.
    * SOFT-LAUNCH: 1.0s buffer on entry to prevent "Loading Screen Lag" collisions.
   ============================================================================
*/

// [2DA REFERENCE SECTION]
// This script acts as the Orchestrator. 2DA lookups are delegated to the 
// specific movement scripts as defined in 'the_switchboard'.
// // Movement 1: dse_engine_v7 -> (appearance.2da, placeables.2da)
// // Movement 2: dowe_bio_core -> (vitals_config.2da)
// // Movement 3: dowe_env_core -> (vfx_internal.2da, weather.2da)

// --- DOWE DEBUG SYSTEM ---
// PHASING: Integrated debug tracer that only broadcasts if "DOWE_DEBUG_MODE" 
// is enabled on the Module object. Essential for finding script collisions.
void DOWE_Debug(string sMsg, object oArea) {
    if (GetLocalInt(GetModule(), "DOWE_DEBUG_MODE") == TRUE) {
        // Optimization: Locate the most relevant PC to receive the technical log.
        object oPC = GetFirstObjectInArea(oArea);
        while(GetIsObjectValid(oPC)) {
            if(GetIsPC(oPC)) {
                SendMessageToPC(oPC, " [CONDUCTOR] -> " + sMsg);
                return; // Efficiency: Exit loop after the first notification.
            }
            oPC = GetNextObjectInArea(oArea);
        }
    }
}

// --- OCCUPANCY CHECK (1,000 AREA OPTIMIZATION) ---
// LOGIC: Looping the global player list is significantly faster than 
// GetFirstObjectInArea for modules with thousands of areas. 
// If no players (excluding DMs) are present, the symphony stops.
int GetIsAreaActive(object oArea) {
    object oPC = GetFirstPC();
    while (GetIsObjectValid(oPC)) {
        if (GetArea(oPC) == oArea && !GetIsDM(oPC)) return TRUE;
        oPC = GetNextPC();
    }
    return FALSE;
}

// --- MOVEMENT 1: POPULATION (DSE v7.0) ---
// TIMING: 30.0s Loop | OFFSET: 0.0s (Delayed to 1.0s on first entry)
void Movement_Population(object oArea) {
    // PHASE 1: ACTIVE ENGINE CHECK
    // If the area is deserted, we kill the recursion to free up the CPU.
    if (!GetIsAreaActive(oArea)) {
        DeleteLocalInt(oArea, "DOWE_CONDUCTOR_RUNNING");
        DOWE_Debug("DORMANT: Area empty. Terminating conductor loop.", oArea);
        return;
    }

    object oMod = GetModule();
    // PHASE 2: PLUG-IN EXECUTION
    // Look up the active script name from 'the_switchboard' registry.
    if (GetLocalInt(oMod, "DOWE_PKG_POP_ACTIVE")) {
        string sScript = GetLocalString(oMod, "DOWE_PKG_POP_SCRIPT");
        DOWE_Debug("Movement 1: Population Pulse [" + sScript + "]", oArea);
        ExecuteScript(sScript, oArea);
    }

    // PHASE 3: RECURSION
    DelayCommand(30.0, Movement_Population(oArea));
}

// --- MOVEMENT 2: BIOLOGICAL (VITALS / BIO-CORE) ---
// TIMING: 30.0s Loop | OFFSET: 10.0s
void Movement_Biological(object oArea) {
    // PHASE 1: SAFETY GUARD
    if (!GetLocalInt(oArea, "DOWE_CONDUCTOR_RUNNING")) return;

    object oMod = GetModule();
    // PHASE 2: PLUG-IN EXECUTION
    if (GetLocalInt(oMod, "DOWE_PKG_BIO_ACTIVE")) {
        string sScript = GetLocalString(oMod, "DOWE_PKG_BIO_SCRIPT");
        DOWE_Debug("Movement 2: Biological Pulse [" + sScript + "]", oArea);

        // PHASE 3: PC-MICROSTAGGER (SCALABILITY PILLAR)
        // To support 480 players, we do not run all vitals in the same frame.
        // We stagger each PC check by 0.1s to flatten the CPU load line.
        float fStagger = 0.0;
        object oTarget = GetFirstObjectInArea(oArea);
        while (GetIsObjectValid(oTarget)) {
            if (GetIsPC(oTarget)) {
                fStagger += 0.1; 
                DelayCommand(fStagger, ExecuteScript(sScript, oTarget));
            }
            oTarget = GetNextObjectInArea(oArea);
        }
    }

    // PHASE 4: RECURSION
    DelayCommand(30.0, Movement_Biological(oArea));
}

// --- MOVEMENT 3: ENVIRONMENTAL (WEATHER / VFX) ---
// TIMING: 30.0s Loop | OFFSET: 20.0s
void Movement_Environmental(object oArea) {
    // PHASE 1: SAFETY GUARD
    if (!GetLocalInt(oArea, "DOWE_CONDUCTOR_RUNNING")) return;

    object oMod = GetModule();
    // PHASE 2: PLUG-IN EXECUTION
    if (GetLocalInt(oMod, "DOWE_PKG_ENV_ACTIVE")) {
        string sScript = GetLocalString(oMod, "DOWE_PKG_ENV_SCRIPT");
        DOWE_Debug("Movement 3: Environmental Pulse [" + sScript + "]", oArea);
        ExecuteScript(sScript, oArea);
    }

    // PHASE 3: RECURSION
    DelayCommand(30.0, Movement_Environmental(oArea));
}

// --- MAIN INITIALIZER ---
// TRIGGER: OnAreaEnter (The only place the Conductor is summoned)
void main() {
    object oArea = OBJECT_SELF;
    object oEnter = GetEnteringObject();

    // PHASE 1: GUARD CLAUSES
    // We only initiate for real players; DMs and NPCs are ignored by the Conductor.
    if (!GetIsPC(oEnter) || GetIsDM(oEnter)) return;

    // SINGLETON ENFORCEMENT: Ensure only one timing loop runs per area.
    if (GetLocalInt(oArea, "DOWE_CONDUCTOR_RUNNING")) {
        DOWE_Debug("Engine already active. No secondary ignition required.", oArea);
        return;
    }

    // PHASE 2: INITIALIZATION
    SetLocalInt(oArea, "DOWE_CONDUCTOR_RUNNING", TRUE);
    DOWE_Debug("RAISING BATON: Initializing Soft-Launch Phase.", oArea);

    // PHASE 3: STAGGERED STARTUP (ROLLING LAUNCH)
    // 1.0s Offset: Allows the Entering Object to finish the loading screen.
    DelayCommand(1.0,  Movement_Population(oArea));
    
    // 11.0s Offset: Separates Vitals from Spawning logic.
    DelayCommand(11.0, Movement_Biological(oArea));
    
    // 21.0s Offset: Final environmental pulse completes the 30s orchestration.
    DelayCommand(21.0, Movement_Environmental(oArea));
}
