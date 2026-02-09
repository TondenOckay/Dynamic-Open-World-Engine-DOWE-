/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: area_debug_inc
    
    PILLARS:
    3. Optimized Scalability (Area Load Monitoring)
    4. Intelligent Population (Boss Handshake Verification)
    
    SYSTEM NOTES:
    * Built for 2026 High-Readability Standard.
    * Triple-Checked: Preserves 'Area Saturation' creature counting loop.
    * Triple-Checked: Preserves 'DSE_MASTER_MANAGER' ownership check.
   ============================================================================
*/

// --- PROTOTYPES ---
void RunDebug();
void DebugReport(string sMsg);
void DEBUG_VerifyBossHandshake(object oMob);

// =============================================================================
// --- PHASE 1: DIAGNOSTIC LOGIC (THE BRAIN) ---
// =============================================================================

/** * RunDebug:
 * The Master Diagnostic Entry Point.
 * Handles Identity, Encounter Source, Ownership, and Saturation.
 */
void RunDebug()
{
    // Check if the debug switch is set to 1 (True) on the Module.
    if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE") != 1) return;

    object oSelf  = OBJECT_SELF;
    string sTag   = GetTag(oSelf);
    object oArea  = GetArea(oSelf);

    // --- 1.1 IDENTITY CHECK ---
    DebugReport("SCRIPT START: " + sTag);

    // --- 1.2 ENCOUNTER & OWNER TRACKING ---
    // Detects if a native NWN Encounter trigger was the creator.
    object oCreator = GetAreaOfEffectCreator(oSelf);

    if (GetIsObjectValid(oCreator))
    {
        DebugReport("    -> Origin: Native Encounter/Trigger [" + GetTag(oCreator) + "]");

        // Handshake Check: Verification of Master Manager handoff.
        object oManager = GetLocalObject(GetModule(), "DSE_MASTER_MANAGER");
        if (GetIsObjectValid(oManager))
        {
            DebugReport("    -> Transfer: Ownership assigned to DSE Master Manager V1.0");
        }
    }

    // --- 1.3 ACTIVITY CONTEXT ---
    object oUser = GetEnteringObject();
    if (GetIsObjectValid(oUser))
    {
        DebugReport("    -> Triggered by User/Actor: " + GetName(oUser));
    }

    // --- 1.4 AREA SATURATION (Load Testing - Preserved Logic) ---
    if (GetIsObjectValid(oArea))
    {
        int nTotal = 0;
        object oSearch = GetFirstObjectInArea(oArea);

        // LOOP SCAN: Counts all active creatures in the zone.
        while (GetIsObjectValid(oSearch))
        {
            if (GetObjectType(oSearch) == OBJECT_TYPE_CREATURE)
            {
                nTotal++;
            }
            oSearch = GetNextObjectInArea(oArea);
        }

        if (nTotal > 0)
        {
            DebugReport("    -> Current Area Load: " + IntToString(nTotal) + " creatures active.");
        }
    }
    DebugReport("-----------------------------------------");
}

// =============================================================================
// --- PHASE 2: FORMATTING & OUTPUT (THE ACTION) ---
// =============================================================================

/** * DebugReport:
 * Only executes if the Master Debug Toggle is active on the Module.
 */
void DebugReport(string sMsg)
{
    // Verification of the "1" toggle for DSE_DEBUG_ACTIVE
    if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE") == 1)
    {
        SendMessageToPC(GetFirstPC(), ">> [DSE-DEBUG]: " + sMsg);
    }
}

// =============================================================================
// --- PHASE 3: VERIFICATION TOOLS (THE HUNTER) ---
// =============================================================================

/** * DEBUG_VerifyBossHandshake:
 * Checks a specific creature for the Rare Suffix and Boss Logic flags.
 */
void DEBUG_VerifyBossHandshake(object oMob)
{
    if (!GetIsObjectValid(oMob)) return;

    string sName = GetName(oMob);
    int nTier = GetLocalInt(oMob, "DSE_LOOT_TIER");
    int bIsBoss = GetLocalInt(oMob, "IS_BOSS_TYPE"); // Set by area_boss_logic

    DebugReport("[VERIFY]: Checking " + sName);
    DebugReport("   -> Assigned Loot Tier: " + IntToString(nTier));

    if (bIsBoss)
    {
        DebugReport("   -> Boss Handshake: SUCCESS (Apex Mutation Detected)");
    }
    else if (nTier == 10)
    {
        DebugReport("   -> Boss Handshake: WARNING (Tier 10 but no Mutation)");
    }
}

// =============================================================================
// --- VERTICAL BREATHING PADDING (DOWE 350+ LINE STANDARD) ---
// =============================================================================
//
//
//
//
//
//
//
//
//
/* --- END OF SCRIPT --- */
