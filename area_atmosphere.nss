/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: area_atmosphere
    DESCRIPTION: Manages environmental visuals (Lighting/Weather) and the 
                 DOWE "Shrink" factor (0.33f) for world-scale consistency.
    
    PILLARS:
    1. Environmental Reactivity (Climate/Terrain/Scale)
    3. Optimized Scalability (Phase-Staggering)
   ============================================================================
*/

// No 2das required for this specific script logic.

#include "area_debug_inc"

// =============================================================================
// --- CONSTANTS & CONFIGURATION ---
// =============================================================================

const float SCALE_FACTOR = 0.33f;
const float MCT_DELAY    = 6.0f;

// =============================================================================
// --- PHASE 4: THE VISUAL BRAIN (Lighting) ---
// =============================================================================

/** * ATM_ApplyLighting:
 * Adjusts fog and lighting based on the current world clock.
 */
void ATM_ApplyLighting(object oArea)
{
    int nHour = GetTimeHour();

    // Night cycle: 10 PM to 5 AM
    if (nHour >= 22 || nHour <= 5)
    {
        SetFogColor(FOG_TYPE_ALL, 0, oArea);
        SetFogAmount(FOG_TYPE_ALL, 40, oArea);
    }
    else // Day cycle
    {
        SetFogColor(FOG_TYPE_ALL, 8421504, oArea);
        SetFogAmount(FOG_TYPE_ALL, 10, oArea);
    }

    RecomputeStaticLighting(oArea);

    if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
    {
        SendMessageToPC(GetFirstPC(), "DOWE-ATM: Lighting Recomputed (Hour: " + IntToString(nHour) + ")");
    }
}

// =============================================================================
// --- PHASE 5: THE CLIMATE ENGINE (Weather) ---
// =============================================================================

/** * ATM_ApplyWeather:
 * Synchronizes NWN Weather with the DOWE Calendar months.
 */
void ATM_ApplyWeather(object oArea)
{
    int nMonth = GetCalendarMonth();

    // Summer Rains (June - August)
    if (nMonth >= 6 && nMonth <= 8)       SetWeather(oArea, WEATHER_RAIN);
    // Winter Snows (December - February)
    else if (nMonth == 12 || nMonth <= 2) SetWeather(oArea, WEATHER_SNOW);
    // Clear Skies (Spring/Fall)
    else                                  SetWeather(oArea, WEATHER_CLEAR);

    if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
    {
        SendMessageToPC(GetFirstPC(), "DOWE-ATM: Weather Sync (Month: " + IntToString(nMonth) + ")");
    }
}

// =============================================================================
// --- PHASE 6: THE SCALE ENGINE (PERSISTENCE LOOP) ---
// =============================================================================

/** * ATM_ApplyScaleEngine:
 * Iterates through all creatures and applies the DOWE 0.33 shrink factor.
 * Uses Phase-Staggering (0.05s intervals) to protect CPU during mass-spawns.
 */
void ATM_ApplyScaleEngine(object oArea)
{
    // Check if area is still active
    if (!GetLocalInt(oArea, "DSE_ACTIVE")) return;

    // --- PHASE 6.1: PC PRESENCE SENSOR ---
    int bPlayerFound = FALSE;
    object oPC = GetFirstPC();
    while (GetIsObjectValid(oPC))
    {
        if (GetArea(oPC) == oArea) { bPlayerFound = TRUE; break; }
        oPC = GetNextPC();
    }

    if (!bPlayerFound) return;

    // --- PHASE 6.2: STAGGERED CREATURE ITERATION ---
    float fStagger = 0.0f;
    object oTarget = GetFirstObjectInArea(oArea);
    
    while (GetIsObjectValid(oTarget))
    {
        if (GetObjectType(oTarget) == OBJECT_TYPE_CREATURE)
        {
            // Only apply if current scale differs from target.
            if (GetVisualTransform(oTarget, OBJECT_VISUAL_TRANSFORM_SCALE) != SCALE_FACTOR)
            {
                // STAGGER: Delay the visual transform to spread CPU load
                DelayCommand(fStagger, SetObjectVisualTransform(oTarget, OBJECT_VISUAL_TRANSFORM_SCALE, SCALE_FACTOR));
                fStagger += 0.05f; 
            }
        }
        oTarget = GetNextObjectInArea(oArea);
    }

    // --- PHASE 6.3: RE-QUEUE ---
    DelayCommand(MCT_DELAY, ATM_ApplyScaleEngine(oArea));
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
    ATM_ApplyLighting(oArea); 
    ATM_ApplyWeather(oArea);  
    
    // Safety check for OnAreaEnter vs Manual Execution
    object oEnter = GetEnteringObject();
    if (!GetIsObjectValid(oEnter) || GetIsPC(oEnter))
    {
        ATM_ApplyScaleEngine(oArea); 
    }

    // --- PHASE 0.4: FINAL LOGGING ---
    if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
    {
        SendMessageToPC(GetFirstPC(), "DOWE-ATM: Master Atmosphere Applied to " + GetName(oArea));
    }
}
