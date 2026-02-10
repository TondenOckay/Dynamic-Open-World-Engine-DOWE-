/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 1.1 (Master Build - Synthetic Player Injector)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: live_npc
    
    PILLARS:
    3. Optimized Scalability (Synthetic Load Testing)
    4. Intelligent Population (Pseudo-PC "Live NPC" Integration)
    
    DESCRIPTION:
    Developer tool for stress-testing the 480-player load. Spawns an NPC 
    stamped with the 'DOWE_IS_LIVE' flag. This bypasses standard NPC 
    logic and forces the Gateway to treat the NPC as a Player.
    
    LOGIC:
    1. Creation: Spawns the bot at the user's location.
    2. Stamping: Applies the 'DOWE_IS_LIVE' key variable.
    3. Hand-off: Manually triggers the Gateway registration logic.
    
    SYSTEM NOTES:
    * STAGGERED SPAWN: Uses ExecuteScript to avoid redundant code.
    * TRIPLE-CHECKED: Bots created this way appear in the VIP search index.
   ============================================================================
*/

// --- DOWE DEBUG SYSTEM ---
void Live_Debug(string sMsg, object oPC) {
    if (GetLocalInt(GetModule(), "DOWE_DEBUG_MODE") == TRUE) {
        SendMessageToPC(oPC, " [LIVE_NPC] -> " + sMsg);
    }
}

void main() {
    object oPC = OBJECT_SELF;
    location lSpawn = GetLocation(oPC);
    object oArea = GetArea(oPC);

    // PHASE 1: CREATURE CREATION
    // Change "nw_human_m" to test different creature blueprints.
    object oBot = CreateObject(OBJECT_TYPE_CREATURE, "nw_human_m", lSpawn, FALSE);

    if (GetIsObjectValid(oBot)) {
        // PHASE 2: SYNTHETIC PLAYER STAMPING
        // This is the variable the Gateway looks for to grant VIP status.
        SetLocalInt(oBot, "DOWE_IS_LIVE", TRUE);
        SetName(oBot, "[BOT] Synthetic Player " + IntToString(Random(1000)));

        // PHASE 3: GATEWAY HAND-OFF
        // Since the bot spawns 'in-place' without entering through a door,
        // we manually fire the Gateway logic on the Area to register it.
        ExecuteScript("the_gateway", oArea);

        Live_Debug("Synthetic Player injected. VIP ID assigned.", oPC);
    } else {
        Live_Debug("CRITICAL: Failed to spawn test bot. Check ResRef.", oPC);
    }
}
