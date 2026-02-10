/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.5 (Master Build - VIP Gateway)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: the_gateway
    
    PILLARS:
    3. Optimized Scalability (VIP Indexing for 480-Players)
    4. Intelligent Population (Synthetic Player Integration)
    
    DESCRIPTION:
    The "Border Control" of the DOWE Area system. This script assigns unique 
    VIP IDs to PCs and Live NPCs. This ID creates a high-speed "search index" 
    on the Area object, allowing other engines to find players instantly 
    without performing expensive area-wide object scans.
    
    PHASE LOGIC:
    1. Validation: Identifies if entrant is a PC or stamped with DOWE_IS_LIVE.
    2. Registry: Scans the Area's VIP array for an empty (NULL) slot to recycle.
    3. Assignment: Stashes the object in the slot and stamps the VIP ID.
    
    SYSTEM NOTES:
    * TRIPLE-CHECKED: Slot recycling ensures the index never grows infinitely.
    * SEARCH READY: Other scripts can now loop 1 to DOWE_VIP_COUNT.
    * DEBUG: Linked to the DOWE_DEBUG_MODE module toggle.
   ============================================================================
*/

// --- DOWE DEBUG SYSTEM ---
// Integrated tracer: Only sends messages if the module switch is TRUE.
void Gate_Debug(string sMsg, object oPC) {
    if (GetLocalInt(GetModule(), "DOWE_DEBUG_MODE") == TRUE) {
        SendMessageToPC(oPC, " [GATEWAY] -> " + sMsg);
    }
}

void main() {
    object oEntrant = GetEnteringObject();
    object oArea = OBJECT_SELF;

    // PHASE 1: IDENTIFICATION & ELIGIBILITY
    // Only VIPs (Actual Players and Test Bots) get registered in the high-speed index.
    int bIsPC = GetIsPC(oEntrant);
    int bIsLive = GetLocalInt(oEntrant, "DOWE_IS_LIVE");

    if (!bIsPC && !bIsLive) return;

    // PHASE 2: REGISTRY RECONCILIATION (Slot Recycling)
    // We look for the first available slot. If someone left, we take their old ID.
    int nMax = GetLocalInt(oArea, "DOWE_VIP_COUNT");
    int nTargetSlot = -1;
    int i;

    // SCALABILITY: This loop is capped by the number of players/bots in area.
    for (i = 1; i <= nMax; i++) {
        object oCheck = GetLocalObject(oArea, "DOWE_VIP_" + IntToString(i));
        // If the object in this slot is no longer valid, the slot is free.
        if (!GetIsObjectValid(oCheck)) {
            nTargetSlot = i;
            break;
        }
    }

    // PHASE 3: ARRAY EXPANSION
    // If no empty slots were found, we increase the count to create a new one.
    if (nTargetSlot == -1) {
        nMax++;
        nTargetSlot = nMax;
        SetLocalInt(oArea, "DOWE_VIP_COUNT", nMax);
    }

    // PHASE 4: STAMPING & EXECUTION
    // We store the object reference on the area and the ID on the entrant.
    SetLocalObject(oArea, "DOWE_VIP_" + IntToString(nTargetSlot), oEntrant);
    SetLocalInt(oEntrant, "DOWE_VIP_ID", nTargetSlot);
    
    // Metadata for the debug log.
    string sType = (bIsPC) ? "PLAYER" : "TEST_BOT";
    Gate_Debug("ID #" + IntToString(nTargetSlot) + " assigned to " + GetName(oEntrant) + " [" + sType + "]", oEntrant);
}
