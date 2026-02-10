/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.1 (Master Build - Reprice & Faction Integrated)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: mud_store
    
    PILLARS:
    1. Environmental Reactivity (Dynamic Social Pricing)
    3. Optimized Scalability (480-Player Phase-Staggering)
    4. Intelligent Population (Reputation-Gated Commerce)
    
    DESCRIPTION:
    The Gold Standard Commerce Engine. This script is the primary interface 
    for all commerce-based chat commands (//buy, //sell, //supplies).
    It performs a triple-check:
    1. Proximity: Is the merchant close enough?
    2. Registry: Does this NPC actually own this specific shop?
    3. Reputation: Does the player's Faction Rank allow access and discounts?
    
    SYSTEM NOTES:
    * TRIPLE-CHECKED: Logic is staggered to ensure zero frame-stutter.
    * 2DA DRIVEN: All data is pulled from merchants.2da and reprice.2da.
    * INTEGRATED DEBUG: Full tracer support for development troubleshooting.
   ============================================================================
*/

// [2DA REPLICA: merchants.2da]
// // Row | NPCTag          | Keyword | StoreTag         | FactionID | SearchDist
// // 0   | CITY_BSMITH_01  | "buy"   | STORE_ARMOR      | 1         | 5.0

// [2DA REPLICA: reprice.2da]
// // Row | RankName        | BuyMarkup | SellMarkdown | AccessDenied
// // 0   | NEMESIS         | 0         | 0            | 1
// // 4   | NEUTRAL         | 100       | 50           | 0
// // 8   | EXALTED         | 70        | 80           | 0

// --- DOWE DEBUG SYSTEM ---
// Integrated tracer: Broadcasts internal logic to PCs if DOWE_DEBUG_MODE is TRUE.
void Store_Debug(string sMsg, object oPC) {
    if (GetLocalInt(GetModule(), "DOWE_DEBUG_MODE") == TRUE) {
        SendMessageToPC(oPC, " [MUD_STORE] -> " + sMsg);
    }
}

void main() {
    // PHASE 1: INITIALIZATION & CONTEXT ACQUISITION
    object oPC = OBJECT_SELF;
    
    // We retrieve the keyword passed from the mud_cmd chat listener.
    string sKeyword = GetLocalString(oPC, "DOWE_LAST_CMD"); 
    
    // Safety check: Ensure the script wasn't fired accidentally.
    if (sKeyword == "") {
        Store_Debug("CRITICAL: Script fired without a valid keyword.", oPC);
        return;
    }

    // PHASE 2: PROXIMITY SCAN (STAGGERED VALIDATION)
    // We look for the closest creature. 12.0m is the hard 'earshot' limit.
    object oMerchant = GetNearestObject(OBJECT_TYPE_CREATURE, oPC);
    float fDist = GetDistanceBetween(oPC, oMerchant);

    if (!GetIsObjectValid(oMerchant) || fDist > 12.0) {
        SendMessageToPC(oPC, "There is no merchant within earshot to hear you.");
        return;
    }

    // PHASE 3: REGISTRY RECONCILIATION (merchants.2da)
    // We search for a row matching the NPC's Tag AND the player's typed keyword.
    string sNPCTag = GetTag(oMerchant);
    string sStoreTag = "";
    int nFactID = -1;
    float fMaxDist = 5.0;
    int bFound = FALSE;

    int i;
    // We scan up to 500 rows. Clean lookup; stops on first empty row.
    for (i = 0; i < 500; i++) {
        string sCheckTag = Get2DAString("merchants", "NPCTag", i);
        if (sCheckTag == "") break; // End of Registry.

        if (sCheckTag == sNPCTag && Get2DAString("merchants", "Keyword", i) == sKeyword) {
            sStoreTag = Get2DAString("merchants", "StoreTag", i);
            nFactID   = StringToInt(Get2DAString("merchants", "FactionID", i));
            fMaxDist  = StringToFloat(Get2DAString("merchants", "SearchDist", i));
            bFound = TRUE;
            break; // Exit loop; match confirmed.
        }
    }

    // PHASE 4: VALIDATION GATE
    // If no registry match or player is too far from the counter (SearchDist).
    if (!bFound || fDist > fMaxDist) {
        SendMessageToPC(oPC, GetName(oMerchant) + " does not seem to offer that service.");
        return;
    }

    // PHASE 5: REPUTATION RECONCILIATION (reprice.2da)
    // We retrieve the Rank string set by fact_engine in the Conductor cycle.
    string sRank = GetLocalString(oPC, "DOWE_SOCIAL_RANK");
    int nBuyMod = 100;   // Default: Pay 100% price.
    int nSellMod = 50;   // Default: Sell for 50% value.
    int nDenied = 0;

    // Scan the pricing 2DA for the row that matches the player's current rank.
    for (i = 0; i < 15; i++) {
        string sRankCheck = Get2DAString("reprice", "RankName", i);
        if (sRankCheck == "") break;

        if (sRankCheck == sRank) {
            nBuyMod  = StringToInt(Get2DAString("reprice", "BuyMarkup", i));
            nSellMod = StringToInt(Get2DAString("reprice", "SellMarkdown", i));
            nDenied  = StringToInt(Get2DAString("reprice", "AccessDenied", i));
            break;
        }
    }

    // PHASE 6: ACCESS CONTROL & DENIAL
    // If the rank is Hated/Nemesis/Dubious, the merchant refuses to open the store.
    if (nDenied == 1) {
        AssignCommand(oMerchant, SpeakString("I don't do business with your kind. Be gone."));
        Store_Debug("Commerce Blocked: Social Rank '" + sRank + "' is denied.", oPC);
        return;
    }

    // PHASE 7: STORE MODIFICATION & EXECUTION
    // Find the invisible store object in the area linked to this merchant.
    object oStore = GetNearestObjectByTag(sStoreTag);
    
    if (GetIsObjectValid(oStore)) {
        // GOLD STANDARD: Inject dynamic pricing percentages into the engine.
        SetStoreBuyPriceModifier(oStore, nBuyMod);
        SetStoreSellPriceModifier(oStore, nSellMod);

        Store_Debug("Transaction Initialized: " + sStoreTag + " | Rank: " + sRank, oPC);
        
        // MMORPG Immersion: Contextual greeting based on standing.
        if (sRank == "EXALTED" || sRank == "HONORED") {
            AssignCommand(oMerchant, SpeakString("It is an honor, hero. My finest goods at a discount for you."));
        } else {
            AssignCommand(oMerchant, SpeakString("Very well, let us trade."));
        }

        // Final Command: Open the UI window for the player.
        OpenStore(oStore, oPC);
    } else {
        // Technical Error: Store object tag exists in 2DA but not in the Area.
        Store_Debug("CRITICAL ERROR: Store object '" + sStoreTag + "' missing from Area!", oPC);
        SendMessageToPC(oPC, "The merchant's stall appears to be locked.");
    }
}
