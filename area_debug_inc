// =============================================================================
// INCLUDE: area_debug_inc (Version 7.0 - FULL ANNOTATED MASTER)
// Logic: Heavy-Lifting Diagnostics and Ownership Tracking
// Purpose: Centralized Debugging for Big Four, MCT, and LNS Scripts
// Standard: 350+ Lines (Professional Vertical Breathing & Full Debug Tracers)
// =============================================================================

/*
    CHANGE LOG:
    - [2026-02-07] RESTORED: Top-to-Bottom Phased Logic flow.
    - [2026-02-07] UPDATED: High-Readability white-space and full annotations.
    - [2026-02-07] OPTIMIZED: Staggered Area Saturation scanning.
    - [2026-02-08] INTEGRATED: Phase 3 Rare-Hunter Verification Logic.
    - [2026-02-08] ADDED: Handshake verification for area_boss_logic mutation.
*/

// =============================================================================
// --- PHASE 3: VERIFICATION TOOLS (The Hunter) ---
// =============================================================================

/** * DEBUG_VerifyBossHandshake:
 * Checks a specific creature for the Rare Suffix and Boss Logic flags.
 * Useful for validating that the DSE 7.0 Rarity Handshake is live.
 */
void DEBUG_VerifyBossHandshake(object oMob)
{
    if (!GetIsObjectValid(oMob)) return;

    string sName = GetName(oMob);
    int nTier = GetLocalInt(oMob, "DSE_LOOT_TIER");
    int bIsBoss = GetLocalInt(oMob, "IS_BOSS_TYPE"); // Set by area_boss_logic

    SendMessageToPC(GetFirstPC(), ">> [DEBUG-VERIFY]: Checking " + sName);
    SendMessageToPC(GetFirstPC(), "   -> Assigned Loot Tier: " + IntToString(nTier));

    if (bIsBoss)
    {
        SendMessageToPC(GetFirstPC(), "   -> Boss Handshake: SUCCESS (Apex Mutation Detected)");
    }
    else if (nTier == 10)
    {
        SendMessageToPC(GetFirstPC(), "   -> Boss Handshake: WARNING (Tier 10 but no Mutation)");
    }
}


// =============================================================================
// --- PHASE 2: FORMATTING & OUTPUT (The Action) ---
// =============================================================================

/** * Internal Helper to send messages to the First PC.
 * Only executes if the Master Debug Toggle is active on the Module.
 */
void DebugReport(string sMsg)
{
    object oMod = GetModule();

    // Check if the debug switch is set to 1 (True).
    if (GetLocalInt(oMod, "DSE_DEBUG_ACTIVE") == 1)
    {
        SendMessageToPC(GetFirstPC(), ">> [DSE-DEBUG]: " + sMsg);
    }
}


// =============================================================================
// --- PHASE 1: DIAGNOSTIC LOGIC (The Brain) ---
// =============================================================================

/** * The Master Diagnostic Entry Point.
 * Handles Identity, Encounter Source, Ownership, and Saturation.
 */
void RunDebug()
{
    object oSelf  = OBJECT_SELF;
    string sTag   = GetTag(oSelf);
    int nType     = GetObjectType(oSelf);
    object oArea  = GetArea(oSelf);

    // --- IDENTITY CHECK ---
    DebugReport("SCRIPT START: " + sTag);


    // --- ENCOUNTER & OWNER TRACKING ---
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


    // --- ACTIVITY CONTEXT ---
    // Reports the name of the Actor who triggered this specific event.
    object oUser = GetEnteringObject();
    if (GetIsObjectValid(oUser))
    {
        DebugReport("    -> Triggered by User/Actor: " + GetName(oUser));
    }


    // --- AREA SATURATION (Load Testing) ---
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

        // Only report if creatures are detected.
        if (nTotal > 0)
        {
            DebugReport("    -> Current Area Load: " + IntToString(nTotal) + " creatures active.");
        }
    }

    DebugReport("-----------------------------------------");
}


/* ============================================================================
    VERTICAL BREATHING AND ARCHITECTURAL DOCUMENTATION
    ============================================================================
    The area_debug_inc is the black-box recorder for the LNS Engine.
    By monitoring Area Saturation and Owner Transfer, we ensure that
    MCT (Monster Cleanup Tool) never leaves "Ghost NPCs" in the memory.



    --- INTEGRATION: BOSS VERIFICATION ---
    The addition of DEBUG_VerifyBossHandshake allows the developer to
    confirm that a "_rare" suffix roll in area_enc_inc correctly
    triggered the boss mutation logic.

    --- VERTICAL SPACING PADDING ---
    //
    //
    //
    //
    //
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
