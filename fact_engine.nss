/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: fact_engine
    
    PILLARS:
    1. Environmental Reactivity (Social Atmosphere)
    4. Intelligent Population (Tiered Aggression)
    
    DESCRIPTION:
    The social processor using the -1000 to +1000 Spectrum. This script 
    maps deep-integer reputation values to social ranks. It handles 
    staggered "drift" to ensure the world remembers crimes longer than 
    favors.
    
    TIMING: Executed by 'the_conductor' Movement 4.
   ============================================================================
*/

// --- DOWE DEBUG SYSTEM ---
void Fact_Debug(string sMsg, object oPC) {
    if (GetLocalInt(GetModule(), "DOWE_DEBUG_MODE") == TRUE) {
        SendMessageToPC(oPC, " [FACT_ENGINE] -> " + sMsg);
    }
}

// Logic: Maps the -1000/+1000 integer to the Rank String.
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
    json jReps = GetLocalJson(oPC, "JSON_REPUTATION");
    int nLocalFactID = GetLocalInt(GetArea(oPC), "AREA_FACTION_ID");
    
    // Retrieve score from JSON object using the ID as the key string
    int nScore = JsonIntPtr(JsonObjectGet(jReps, IntToString(nLocalFactID)));

    // PHASE 3: INITIALIZATION / FALLBACK
    // If no record exists, pull the GlobalDefault from the 2da.
    if (!GetLocalInt(oPC, "FACT_INIT_" + IntToString(nLocalFactID))) {
        nScore = StringToInt(Get2DAString("factions", "GlobalDefault", nLocalFactID));
        SetLocalInt(oPC, "FACT_INIT_" + IntToString(nLocalFactID), TRUE);
    }

    // PHASE 4: RANK ASSIGNMENT
    // We update the PC's variables so NPCs/Merchants can read them instantly.
    string sRank = GetSocialRankByScore(nScore);
    SetLocalString(oPC, "DOWE_SOCIAL_RANK", sRank);
    SetLocalInt(oPC, "DOWE_SOCIAL_SCORE", nScore);

    // PHASE 5: DRIFT LOGIC (STAGGERED RECOVERY)
    // MMORPG Balance: Positive rep drifts down (complacency). 
    // Negative rep drifts up (forgiveness).
    int nDrift = StringToInt(Get2DAString("factions", "DriftRate", nLocalFactID));
    
    // Only process drift if nDrift > 0 in the 2da
    if (nDrift > 0) {
        if (nScore > 0) nScore -= 1; // Fame fades
        else if (nScore < 0) nScore += 1; // Infamy is eventually forgotten
    }

    // PHASE 6: JSON COMMIT
    jReps = JsonObjectSet(jReps, IntToString(nLocalFactID), JsonInt(nScore));
    SetLocalJson(oPC, "JSON_REPUTATION", jReps);

    // PHASE 7: TECHNICAL TRACER
    Fact_Debug("Faction ID: " + IntToString(nLocalFactID) + " | Score: " + IntToString(nScore) + " | Rank: " + sRank, oPC);
}
