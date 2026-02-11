/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: craft_create
    
    DESCRIPTION:
    Processes Forges and Benches. Strict 5-ingredient scan. 
    * GOLD STANDARD UPDATE: If ingredients do not match, items are spat back 
      to the player instead of being left in the container.
   ============================================================================
*/

void main() {
    object oPC = GetLastUsedBy();
    object oForge = OBJECT_SELF;
    
    int bDebug = GetLocalInt(GetModule(), "DOWE_DEBUG_MODE");
    string sTool = GetLocalString(oForge, "PP_TOOL_TAG");
    int bSuccess = GetLocalInt(oForge, "TEMP_SUCCESS");

    // PHASE 1: QUANTITY SCAN (5 SLOTS)
    int bMatch = TRUE;
    int i;
    for(i = 1; i <= 5; i++) {
        string sNeed = GetLocalString(oForge, "PP_ITEM" + IntToString(i));
        int nQty = GetLocalInt(oForge, "PP_QTY" + IntToString(i));
        
        if (sNeed != "" && sNeed != "****") {
            int nCount = 0;
            object oInv = GetFirstItemInInventory(oForge);
            while(GetIsObjectValid(oInv)) {
                if(GetTag(oInv) == sNeed) nCount += GetItemStackSize(oInv);
                oInv = GetNextItemInInventory(oForge);
            }
            if (nCount != nQty) bMatch = FALSE;
        }
    }

    // PHASE 2: EVALUATION & SMART RETURN
    if (!bMatch) {
        FloatingTextStringOnCreature("These items cannot create anything.", oPC);
        if(bDebug) SendMessageToPC(oPC, "DEBUG: [craft_create] Ingredient mismatch. Returning items.");
        
        object oRet = GetFirstItemInInventory(oForge);
        while (GetIsObjectValid(oRet)) {
            CopyItem(oRet, oPC, TRUE);
            DestroyObject(oRet);
            oRet = GetNextItemInInventory(oForge);
        }
        return;
    }

    // PHASE 3: CONSUMPTION & DURABLE TOOL PROTECTION
    // If we reached here, ingredients are CORRECT. Now we consume or protect.
    object oItem = GetFirstItemInInventory(oForge);
    while (GetIsObjectValid(oItem)) {
        object oNext = GetNextItemInInventory(oForge);
        
        // If the item is the tool, move it back to player bags
        if (GetTag(oItem) == sTool) {
            CopyItem(oItem, oPC, TRUE);
            if(bDebug) SendMessageToPC(oPC, "DEBUG: [craft_create] Durable tool " + sTool + " returned to player.");
        }
        
        // Destroy the item in the forge (Tool or Material)
        DestroyObject(oItem); 
        oItem = oNext;
    }

    // PHASE 4: FINAL DELIVERY
    if (bSuccess) {
        string sRes = GetLocalString(oForge, "PP_RESULT_RESREF");
        CreateItemOnObject(sRes, oPC);
        FloatingTextStringOnCreature("Crafting Success!", oPC);
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_MAGIC_RESISTANCE_USE), oPC);
        if(bDebug) SendMessageToPC(oPC, "DEBUG: [craft_create] Success. Item Created: " + sRes);
    } else {
        FloatingTextStringOnCreature("Crafting Failed: Materials Ruined.", oPC);
        if(bDebug) SendMessageToPC(oPC, "DEBUG: [craft_create] Roll Failed. Materials consumed.");
    }
    
    // Cleanup
    DeleteLocalInt(oForge, "TEMP_SUCCESS");
}
