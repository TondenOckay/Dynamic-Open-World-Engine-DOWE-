/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.1 (Master Build - Reprice & JSON Integrated)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: fact_engine
    
    PILLARS:
    1. Environmental Reactivity (Social Atmosphere)
    4. Intelligent Population (Tiered Aggression & Pricing)
    
    DESCRIPTION:
    The core social processor for the DOWE ecosystem. This script manages 
    the -1000 to +1000 Reputation Spectrum. It reconciles the player's 
    persistent JSON Reputation Passport with the static definitions in 
    factions.2da and reprice.2da.
    
    PHASE LOGIC:
    1. Validation: Ensures the target is a valid player.
    2. Data Retrieval: Pulls the current Area's Faction ID and JSON data.
    3. Initialization: Handles first-time setup for new factions.
    4. Rank Mapping: Converts integer scores to Social Rank Strings.
    5. Reprice Caching: Pulls price modifiers for the current rank.
    6. Drift: Handles the natural decay of fame and infamy.
    7. Commitment: Saves the updated JSON back to the PC.

    TIMING: Executed by 'the_conductor' Movement 4.
   ============================================================================
*/

// [2DA REPLICA: factions.2da]
// // Row | Label      | GlobalDefault | DriftRate
// // 0   | CITY_GUARD | 0             | 1

// [2DA REPLICA: reprice.2da]
// // Row | RankName   | BuyMarkup | SellMarkdown | AccessDenied
// // 0   | NEMESIS    | 0         | 0            | 1
// // 4   | NEUTRAL    | 100       | 50           | 0
// // 8   | EXALTED    | 70        | 80           | 0

#include "save_mgr"

// --- DOWE DEBUG SYSTEM ---
// Integrated tracer: Broadcasts faction updates and rank changes if Debug Mode is active.
void Fact_Debug(string sMsg, object oPC) {
    if (GetLocalInt(GetModule(), "DOWE_DEBUG_MODE") == TRUE) {
        SendMessageToPC(oPC, " [FACT_ENGINE] -> " + sMsg);
    }
}

// ----------------------------------------------------------------------------
// HELPER: Social Rank Mapping
// Converts the raw integer into the 2026 Tiered Social Spectrum.
// ----------------------------------------------------------------------------
string GetSocialRankByScore(int nScore) {
    if (nScore <= -751) return "NEMESIS";
    if (nScore <= -401) return "HATED";
    if (nScore <= -151) return "UNFRIENDLY";
    if (nScore <= -51)  return "DUBIOUS";
    if (nScore <= 50)   return "NEUTRAL";
    if (nScore <= 250)  return "APPRENTICE";
    if (nScore <= 500)  return "FRIENDLY";
    if (nScore <= 850)  return "HONORED";
    return "EXALTED";
}

void main() {
    // PHASE 1: TARGET VALIDATION
    object oPC = OBJECT_SELF;
    if (!GetIsPC(oPC) || GetIsDM(oPC)) return;

    // PHASE 2: DATA RETRIEVAL (JSON PASSPORT)
    // We pull the local Faction ID defined for the current area.
    json jReps = GetLocalJson(oPC, "JSON_REPUTATION");
    int nLocalFactID = GetLocalInt(GetArea(oPC), "AREA_FACTION_ID");
    
    // Retrieve integer score from the JSON object using ID as the key string.
    int nScore = JsonIntPtr(JsonObjectGet(jReps, IntToString(nLocalFactID)));

    // PHASE 3: INITIALIZATION / FALLBACK
    // TRIPLE-CHECK: If this player has never visited this faction, pull 2DA defaults.
    if (!GetLocalInt(oPC, "FACT_INIT_" + IntToString(nLocalFactID))) {
        nScore = StringToInt(Get2DAString("factions", "GlobalDefault", nLocalFactID));
        SetLocalInt(oPC, "FACT_INIT_" + IntToString(nLocalFactID), TRUE);
        Fact_Debug("Initializing Faction " + IntToString(nLocalFactID) + " for PC.", oPC);
    }

    // PHASE 4: RANK & REPRICE CACHING
    // We convert the score to a Rank Name, then cache pricing modifiers.
    string sRank = GetSocialRankByScore(nScore);
    
    // Update PC variables for instant access by mud_store/mud_quest.
    SetLocalString(oPC, "DOWE_SOCIAL_RANK", sRank);
    SetLocalInt(oPC, "DOWE_SOCIAL_SCORE", nScore);

    // GOLD STANDARD: Registry Scan for reprice.2da modifiers.
    int i;
    for (i = 0; i < 15; i++) {
        string sCheck = Get2DAString("reprice", "RankName", i);
        if (sCheck == "") break; 

        if (sCheck == sRank) {
            // Cache economic modifiers to eliminate 2DA lag during commerce.
            SetLocalInt(oPC, "DOWE_PRC_BUY", StringToInt(Get2DAString("reprice", "BuyMarkup", i)));
            SetLocalInt(oPC, "DOWE_PRC_SELL", StringToInt(Get2DAString("reprice", "SellMarkdown", i)));
            SetLocalInt(oPC, "DOWE_PRC_DENY", StringToInt(Get2DAString("reprice", "AccessDenied", i)));
            break;
        }
    }

    // PHASE 5: DRIFT LOGIC (STAGGERED RECOVERY)
    // Reputation naturally trends toward 0 (Neutral) over time.
    int nDrift = StringToInt(Get2DAString("factions", "DriftRate", nLocalFactID));
    
    if (nDrift > 0) {
        if (nScore > 0) nScore -= 1; // Fame fades through complacency.
        else if (nScore < 0) nScore += 1; // Infamy is eventually forgotten.
    }

    // PHASE 6: JSON COMMIT
    // Re-insert the updated score into the JSON object and save back to the PC.
    jReps = JsonObjectSet(jReps, IntToString(nLocalFactID), JsonInt(nScore));
    SetLocalJson(oPC, "JSON_REPUTATION", jReps);

    // PHASE 7: TECHNICAL TRACER
    Fact_Debug("Updated Faction " + IntToString(nLocalFactID) + " [" + sRank + "] Score: " + IntToString(nScore), oPC);
}
