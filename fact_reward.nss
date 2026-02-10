/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.1 (Master Build - Faction Reward System)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: fact_reward
    
    PILLARS:
    1. Environmental Reactivity (Social Logic)
    3. Optimized Scalability (Event-Driven Execution)
    
    DESCRIPTION:
    The "Social Accountant" for DOWE. This script modifies a player's reputation 
    score within the JSON Passport. It handles the mathematical addition/subtraction 
    and then triggers the 'fact_engine' to refresh the player's Rank/Price mods.
    
    PHASE LOGIC:
    1. Retrieval: Pulls the existing JSON_REPUTATION from the PC's memory.
    2. Calculation: Updates the specific Faction ID with the reward amount (+/-).
    3. Serialization: Saves the updated JSON back to the PC object.
    4. Synchronization: Forces 'fact_engine' to refresh Ranks and Pricing instantly.
    
    SYSTEM NOTES:
    * TRIPLE-CHECKED: Renamed to 'fact_reward' to maintain alphabetical grouping.
    * JSON COMPLIANT: Uses high-speed JsonObject functions for 480-player efficiency.
    * DEBUG: Fully integrated with the DOWE_DEBUG_MODE module toggle.
   ============================================================================
*/

#include "save_mgr"

// --- DOWE DEBUG SYSTEM ---
// Integrated tracer: Broadcasts internal logic to PCs if DOWE_DEBUG_MODE is TRUE.
void Fact_Debug(string sMsg, object oPC) {
    if (GetLocalInt(GetModule(), "DOWE_DEBUG_MODE") == TRUE) {
        SendMessageToPC(oPC, " [FACT_REWARD] -> " + sMsg);
    }
}

void main() {
    // PHASE 1: INITIALIZATION & CONTEXT
    object oPC = OBJECT_SELF;
    
    // We retrieve the "Input" variables set by the calling script.
    int nFactID = GetLocalInt(oPC, "DOWE_REWARD_FACT"); // Target Faction (e.g., 1 for City Watch)
    int nAmount = GetLocalInt(oPC, "DOWE_REWARD_AMT");  // Delta value (e.g., +50 or -100)
    
    // TRIPLE-CHECK: Optimization gate. If there is no reward, exit immediately.
    if (nAmount == 0) {
        Fact_Debug("IDLE: Reward value is 0. Operation aborted.", oPC);
        return;
    }

    // PHASE 2: DATA RETRIEVAL (JSON PASSPORT)
    // We grab the master reputation object stored on the PC.
    json jReps = GetLocalJson(oPC, "JSON_REPUTATION");
    string sFactKey = IntToString(nFactID);
    
    // PHASE 3: CALCULATION & UPDATING
    // 1. Get current score. 2. Apply change. 3. Update the JSON structure.
    int nCurrentRep = JsonIntPtr(JsonObjectGet(jReps, sFactKey));
    int nNewRep = nCurrentRep + nAmount;
    
    jReps = JsonObjectSet(jReps, sFactKey, JsonInt(nNewRep));

    // PHASE 4: SERIALIZATION (Saving to Object)
    // We write the new JSON object back to the player.
    SetLocalJson(oPC, "JSON_REPUTATION", jReps);
    
    Fact_Debug("SUCCESS: Faction " + sFactKey + " shifted (" + IntToString(nAmount) + "). New Total: " + IntToString(nNewRep), oPC);

    // PHASE 5: INSTANT SYNCHRONIZATION
    // GOLD STANDARD: Instead of waiting for the 30s heartbeat, we force the 
    // rank/pricing engine to run NOW so the world reacts to the change instantly.
    ExecuteScript("fact_engine", oPC);
    
    // PHASE 6: VARIABLE CLEANUP
    // Delete the "Inputs" to prevent logic-looping or double-awarding of reputation.
    DeleteLocalInt(oPC, "DOWE_REWARD_FACT");
    DeleteLocalInt(oPC, "DOWE_REWARD_AMT");
}
