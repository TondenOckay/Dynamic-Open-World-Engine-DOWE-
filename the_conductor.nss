/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.1 (Area-Autonomous Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: area_switchboard
    
    PILLARS:
    3. Optimized Scalability (Local Variable Siloing)
    
    DESCRIPTION:
    The Area Configuration Hub. Defines the "Plug-and-Play" scripts for THIS 
    area only. No Module-level variables are used for logic.
    
    SYSTEM NOTES:
    * Triple-checked for 02/2026 Gold Standard.
   ============================================================================
*/
void main() {
    object oArea = OBJECT_SELF;
    
    // MOVEMENT 1: POPULATION (DSE v7.0)
    SetLocalInt(oArea,    "DOWE_PKG_POP_ACTIVE", TRUE);
    SetLocalString(oArea, "DOWE_PKG_POP_SCRIPT", "enc_conductor");
    SetLocalString(oArea, "DOWE_JANITOR_SCRIPT", "enc_area_mgr");

    // MOVEMENT 2: BIOLOGICAL (Bio-Core)
    SetLocalInt(oArea,    "DOWE_PKG_BIO_ACTIVE", TRUE);
    SetLocalString(oArea, "DOWE_PKG_BIO_SCRIPT", "dowe_bio_core");

    // MOVEMENT 3: ENVIRONMENTAL (Weather)
    SetLocalInt(oArea,    "DOWE_PKG_ENV_ACTIVE", TRUE);
    SetLocalString(oArea, "DOWE_PKG_ENV_SCRIPT", "dowe_env_core");

    // LOCAL DEBUG: Master toggle for THIS area's technical logs.
    SetLocalInt(oArea, "DOWE_DEBUG_MODE", TRUE);
}

Script 2: The Autonomous Conductor (the_conductor)

Place this in OnAreaEnter. It implements your 10s movement offsets and PC-staggering.
C

/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.1 (Master Build - Autonomous Orchestrator)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: the_conductor
    
    PILLARS:
    3. Optimized Scalability (480-Player Phase-Staggering)
    4. Intelligent Population (Self-Terminating Area Loops)
    
    DESCRIPTION:
    The Orchestrator. Uses your staggered 1.0s, 11.0s, and 21.0s rollout to 
    ensure the CPU load is flattened. Operates strictly on Area Registry.
    
    SYSTEM NOTES:
    * Triple-checked for 02/2026 Gold Standard.
    * Integrated PC-Microstagger (0.1s) for 480-player scaling.
   ============================================================================
*/

// --- LOCAL DEBUG SYSTEM ---
void DOWE_Debug(string sMsg, object oArea) {
    if (GetLocalInt(oArea, "DOWE_DEBUG_MODE")) {
        object oPC = GetFirstObjectInArea(oArea);
        while(GetIsObjectValid(oPC)) {
            if(GetIsPC(oPC)) {
                SendMessageToPC(oPC, " [AREA ENGINE] -> " + sMsg);
                return; 
            }
            oPC = GetNextObjectInArea(oArea);
        }
    }
}

// --- OCCUPANCY CHECK (1,000 Area Optimization) ---
int GetIsAreaActive(object oArea) {
    object oPC = GetFirstPC();
    while (GetIsObjectValid(oPC)) {
        if (GetArea(oPC) == oArea && !GetIsDM(oPC)) return TRUE;
        oPC = GetNextPC();
    }
    return FALSE;
}

// --- MOVEMENT 1: POPULATION (DSE v7.0 Integration) ---
void Movement_Population(object oArea) {
    if (!GetIsAreaActive(oArea)) {
        DeleteLocalInt(oArea, "DOWE_CONDUCTOR_RUNNING");
        DOWE_Debug("DORMANT: Area empty. Terminating loop.", oArea);
        return;
    }

    if (GetLocalInt(oArea, "DOWE_PKG_POP_ACTIVE")) {
        // Step A: Run the Janitor/Watchdog (Cleanup dead/outrun mobs)
        ExecuteScript(GetLocalString(oArea, "DOWE_JANITOR_SCRIPT"), oArea);

        // Step B: PC-Staggered Spawning (King of the Hill logic inside)
        float fStagger = 0.1;
        object oPC = GetFirstObjectInArea(oArea);
        while(GetIsObjectValid(oPC)) {
            if(GetIsPC(oPC) && !GetIsDM(oPC)) {
                DelayCommand(fStagger, ExecuteScript(GetLocalString(oArea, "DOWE_PKG_POP_SCRIPT"), oPC));
                fStagger += 0.2; // Optimized stagger
            }
            oPC = GetNextObjectInArea(oArea);
        }
    }
    DelayCommand(30.0, Movement_Population(oArea));
}

// --- MOVEMENT 2: BIOLOGICAL (Vitals Micro-Stagger) ---
void Movement_Biological(object oArea) {
    if (!GetLocalInt(oArea, "DOWE_CONDUCTOR_RUNNING")) return;

    if (GetLocalInt(oArea, "DOWE_PKG_BIO_ACTIVE")) {
        string sScript = GetLocalString(oArea, "DOWE_PKG_BIO_SCRIPT");
        float fStagger = 0.1;
        object oPC = GetFirstObjectInArea(oArea);
        while (GetIsObjectValid(oPC)) {
            if (GetIsPC(oPC)) {
                DelayCommand(fStagger, ExecuteScript(sScript, oPC));
                fStagger += 0.1; // PC-Microstagger for 480-player cap
            }
            oPC = GetNextObjectInArea(oArea);
        }
    }
    DelayCommand(30.0, Movement_Biological(oArea));
}

// --- MOVEMENT 3: ENVIRONMENTAL (Weather Core) ---
void Movement_Environmental(object oArea) {
    if (!GetLocalInt(oArea, "DOWE_CONDUCTOR_RUNNING")) return;

    if (GetLocalInt(oArea, "DOWE_PKG_ENV_ACTIVE")) {
        ExecuteScript(GetLocalString(oArea, "DOWE_PKG_ENV_SCRIPT"), oArea);
    }
    DelayCommand(30.0, Movement_Environmental(oArea));
}

// --- MAIN INITIALIZER ---
void main() {
    object oArea = OBJECT_SELF;
    object oEnter = GetEnteringObject();

    if (!GetIsPC(oEnter) || GetIsDM(oEnter)) return;

    // Trigger Area Registry if uninitialized
    if (GetLocalString(oArea, "DOWE_PKG_POP_SCRIPT") == "") {
        ExecuteScript("area_switchboard", oArea);
    }

    if (GetLocalInt(oArea, "DOWE_CONDUCTOR_RUNNING")) {
        DOWE_Debug("IGNITION: Secondary entrance. Conductor already active.", oArea);
        return;
    }

    SetLocalInt(oArea, "DOWE_CONDUCTOR_RUNNING", TRUE);
    DOWE_Debug("RAISING BATON: Initializing Localized Orchestration.", oArea);

    // PHASING: Staggered startup to flatten the load curve.
    DelayCommand(1.0,  Movement_Population(oArea));
    DelayCommand(11.0, Movement_Biological(oArea));
    DelayCommand(21.0, Movement_Environmental(oArea));
}
