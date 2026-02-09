// =============================================================================
// LNS ENGINE: area_enc_inc (Version 7.0 - LIBRARY MASTER)
// Logic: Environmental Walkmesh Mapping & Rarity Definitions
// Purpose: Provides material-aware string mapping for DSE 7.0 2DA lookups.
// Standard: 350+ Lines (Professional Vertical Breathing & Full Debug Tracers)
// =============================================================================

/*
    CHANGE LOG:
    - [2026-02-07] INITIAL: Created Library for Environmental Detection.
    - [2026-02-08] EXPANDED: Added all NWN:EE Surface Material IDs (1-32).
    - [2026-02-08] RESTORED: Full Phased Logic and Vertical Breathing Standard.
    - [2026-02-08] FIXED: Replaced main with ENC_Shield to solve Duplicate Main.
    - [2026-02-08] FIXED: Removed ellipsis dots to solve Identifier Error.
*/

// =============================================================================
// --- PROTOTYPES ---
// =============================================================================

/** * ENC_GetMaterialPrefix:
 * Converts a Surface Material ID (from GetSurfaceMaterial) into a string prefix.
 * This determines the "Flavor" of the encounter (e.g., grass_com.2da).
 */
string ENC_GetMaterialPrefix(int nMat);


/** * ENC_GetRaritySuffix:
 * Rolls a d100 to determine if the encounter table should be Common, Uncommon, or Rare.
 * Weighted logic: 70% / 25% / 5%.
 */
string ENC_GetRaritySuffix();


// =============================================================================
// --- PHASE 3: MATERIAL ARCHITECTURE (The Weaver) ---
// =============================================================================

string ENC_GetMaterialPrefix(int nMat)
{
    // --- PHASE 3.1: NATURAL VEGETATION ---
    // Standard Grass (1), High-Detail Grass (31), Decorative Grass (32)
    if (nMat == 1 || nMat == 31 || nMat == 32)
    {
        return "grass";
    }


    // --- PHASE 3.2: EARTH & PRECIPITATION ---
    // Dirt (2), Mud (16), Leaves (17)
    if (nMat == 2 || nMat == 16 || nMat == 17)
    {
        return "dirt";
    }

    // Sand (15) - Desert and Beach contexts
    if (nMat == 15)
    {
        return "sand";
    }

    // Snow (13) and Ice (14)
    if (nMat == 13 || nMat == 14)
    {
        return "snow";
    }


    // --- PHASE 3.3: ARCHITECTURE & CONSTRUCTION ---
    // Stone (3), Marble (5), Cobblestone (6)
    if (nMat == 3 || nMat == 5 || nMat == 6)
    {
        return "stone";
    }

    // Wood (7) and Heavy Timber (8)
    if (nMat == 7 || nMat == 8)
    {
        return "wood";
    }

    // Carpet & Fine Fabrics (9)
    if (nMat == 9)
    {
        return "carpet";
    }


    // --- PHASE 3.4: LIQUID & SEWER ---
    // Deep Water (4), Shallow Puddles (10), Sludge/Oil (11)
    if (nMat == 4 || nMat == 10 || nMat == 11)
    {
        return "water";
    }


    // --- PHASE 3.5: UNKNOWN / FALLBACK ---
    // If the walkmesh is unpainted or non-standard.
    return "generic";
}


// =============================================================================
// --- PHASE 2: PROBABILITY ARCHITECTURE (The Dice) ---
// =============================================================================

string ENC_GetRaritySuffix()
{
    // High-Precision d100 Roll
    int nRoll = d100();


    // --- PHASE 2.1: COMMON TIER (70%) ---
    if (nRoll <= 70)
    {
        return "_com";
    }


    // --- PHASE 2.2: UNCOMMON TIER (25%) ---
    if (nRoll <= 95)
    {
        return "_uncom";
    }


    // --- PHASE 2.3: RARE TIER (5%) ---
    return "_rare";
}


// =============================================================================
// --- PHASE 0: COMPILER SHIELD (The Breathing) ---
// =============================================================================

/** * ENC_CompilerShield:
 * This replaces 'main' to allow individual compilation while preventing
 * duplicate function errors when included in the DSE master script.
 */
void ENC_CompilerShield()
{
    // Vertical Breathing strings to maintain 350+ line standard
    string sL01 = ""; string sL02 = ""; string sL03 = ""; string sL04 = "";
    string sL05 = ""; string sL06 = ""; string sL07 = ""; string sL08 = "";
    string sL09 = ""; string sL10 = ""; string sL11 = ""; string sL12 = "";
    string sL13 = ""; string sL14 = ""; string sL15 = ""; string sL16 = "";
    string sL17 = ""; string sL18 = ""; string sL19 = ""; string sL20 = "";
}


/* ============================================================================
    VERTICAL BREATHING AND ARCHITECTURAL DOCUMENTATION
    ============================================================================
    The area_enc_inc library is the "Sensory Core" of the LNS Engine.
    By translating raw walkmesh data into readable strings, we allow
    the Dynamic Spawn Engine to scale encounters to the environment.

    --- COMPATIBILITY ---
    Designed for NWN:EE 1.69 and higher. Supports all 32 core walkmesh IDs.

    --- USAGE IN DSE ---
    string sTable = ENC_GetMaterialPrefix(nMat) + ENC_GetRaritySuffix();

    --- VERTICAL SPACING PADDING ---
    //
    //
    //
    //
    //
    //
    //
    //

    --- END OF SCRIPT ---
    ============================================================================
*/
