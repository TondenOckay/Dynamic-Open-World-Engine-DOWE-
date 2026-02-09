/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: area_atmosphere_shrink
    
    PILLARS:
    1. Environmental Reactivity (Climate/Terrain/Scale)
    2. Biological Persistence (Hunger/Thirst/Fatigue)
    3. Optimized Scalability (480-Player Phase-Staggering)
    4. Intelligent Population (DSE v7.0 Integration)
    
    SYSTEM NOTES:
    * Integrated Phase 6: Scale Engine (0.33f Factor).
    * Built for 2026 High-Readability Standard.
    * Integrated with area_debug_inc / RunDebug Handshake.
   ============================================================================
*/

#include "area_debug_inc"

// =============================================================================
// --- CONSTANTS & CONFIGURATION ---
// =============================================================================

const float SCALE_FACTOR = 0.33f;
const float MCT_DELAY    = 6.0f;

// =============================================================================
// --- PROTOTYPES ---
// =============================================================================

void ATM_ApplyWeather();
void ATM_ApplyLighting();

/** * ATM_ApplyScaleEngine:
 * Iterates through all creatures and applies the DOWE 0.33 shrink factor.
 * Uses MCT 6.0s Delay for persistence of summons/pets/spawns.
 */
void ATM_ApplyScaleEngine(object oArea);

// =============================================================================
// --- PHASE 6: THE SCALE ENGINE (PERSISTENCE LOOP) ---
// =============================================================================

void ATM_ApplyScaleEngine(object oArea)
{
    // --- PHASE 6.1: PC PRESENCE SENSOR ---
    // Optimization for Pillar 3: Scalability. Shut down if area is empty.
    
    int bPlayerFound = FALSE;
    object oPC = GetFirstPC();
    while (GetIsObjectValid(oPC))
    {
        if (GetArea(oPC) == oArea) { bPlayerFound = TRUE; break; }
        oPC = GetNextPC();
    }

    if (!bPlayerFound) return;

    // --- PHASE 6.2: CREATURE ITERATION ---
    // Targets: Players, Pets, Summons, Henchmen, and DSE v7.0 Spawns.

    object oTarget = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oTarget))
    {
        if (GetObjectType(oTarget) == OBJECT_TYPE_CREATURE)
        {
            // Only apply transform if current scale differs from target.
            if (GetVisualTransform(oTarget, OBJECT_VISUAL_TRANSFORM_SCALE) != SCALE_FACTOR)
            {
                SetObjectVisualTransform(oTarget, OBJECT_VISUAL_TRANSFORM_SCALE, SCALE_FACTOR);
            }
        }
        oTarget = GetNextObjectInArea(oArea);
    }

    // --- PHASE 6.3: MCT PERSISTENCE ---
    // Re-queue the loop to catch new summons/spawns.
    
    DelayCommand(MCT_DELAY, ATM_ApplyScaleEngine(oArea));
}

// =============================================================================
// --- PHASE 5: THE CLIMATE ENGINE ---
// =============================================================================

void ATM_ApplyWeather()
{
    int nMonth = GetCalendarMonth();

    if (nMonth >= 6 && nMonth <= 8)      SetWeather(OBJECT_SELF, WEATHER_RAIN);
    else if (nMonth == 12 || nMonth <= 2) SetWeather(OBJECT_SELF, WEATHER_SNOW);
    else                                 SetWeather(OBJECT_SELF, WEATHER_CLEAR);

    if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
    {
        SendMessageToPC(GetFirstPC(), "ATM-WEATHER: Climate synchronized with Month: " + IntToString(nMonth));
    }
}

// =============================================================================
// --- PHASE 4: THE VISUAL BRAIN ---
// =============================================================================

void ATM_ApplyLighting()
{
    int nHour = GetTimeHour();

    if (nHour >= 22 || nHour <= 5)
    {
        SetFogColor(FOG_TYPE_ALL, 0);
        SetFogAmount(FOG_TYPE_ALL, 40);
    }
    else
    {
        SetFogColor(FOG_TYPE_ALL, 8421504);
        SetFogAmount(FOG_TYPE_ALL, 10);
    }

    RecomputeStaticLighting(OBJECT_SELF);

    if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
    {
        SendMessageToPC(GetFirstPC(), "ATM-LIGHTING: Visual recomputation complete for Hour: " + IntToString(nHour));
    }
}

// =============================================================================
// --- PHASE 0: MAIN ENTRY POINT ---
// =============================================================================

void main()
{
    // --- PHASE 0.1: DIAGNOSTIC HANDSHAKE ---
    RunDebug();

    // --- PHASE 0.2: CONTEXT VALIDATION ---
    object oArea = OBJECT_SELF;
    if (GetObjectType(oArea) != OBJECT_TYPE_AREA)
    {
        oArea = GetArea(oArea);
        if (!GetIsObjectValid(oArea)) return;
    }

    // --- PHASE 0.3: EXECUTION PIPELINE ---
    
    ATM_ApplyLighting();    // Phase 4
    ATM_ApplyWeather();     // Phase 5
    
    // Only trigger the recursive Scale Engine if a PC is entering.
    if (GetIsPC(GetEnteringObject()))
    {
        ATM_ApplyScaleEngine(oArea); // Phase 6
    }

    // --- PHASE 0.4: FINAL LOGGING ---
    if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
    {
        SendMessageToPC(GetFirstPC(), "DOWE-ATMOSPHERE: Master Cycle Initialized for " + GetName(oArea));
    }
}
