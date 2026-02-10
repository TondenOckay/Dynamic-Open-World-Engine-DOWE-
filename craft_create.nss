/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    MODULE: craft_create
    
    DESCRIPTION:
    Processes Forges and Benches. Strict 5-ingredient scan. Durable Tool Logic.
   ============================================================================
*/

void main() {
    object oPC = GetLastUsedBy();
    object oForge = OBJECT_SELF;
    
    int bDebug = GetLocalInt(GetModule(), "DOWE_DEBUG_MODE");
    string sTool = GetLocalString(oForge, "PP_TOOL_TAG");
    int bSuccess = GetLocalInt(oForge, "TEMP_SUCCESS");

    // PHASE 1: QUANTITY SCAN (5 SLOTS)
    // Ensures EXACT counts are in the container.
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
            if (nCount != nQty) {
                FloatingTextStringOnCreature("Recipe Error: Check Ingredient Quantities.", oPC);
                if(bDebug) SendMessageToPC(oPC, "DEBUG: [craft_create] Found " + IntToString(nCount) + " of " + sNeed);
                return;
            }
        }
    }

    // PHASE 2: CONSUMPTION & TOOL PROTECTION
    // The Tool (e.g. Seam Ripper) is given back to the PC. Materials are destroyed.
    object oItem = GetFirstItemInInventory(oForge);
    while (GetIsObjectValid(oItem)) {
        object oNext = GetNextItemInInventory(oForge);
        if (GetTag(oItem) == sTool) {
            CopyItem(oItem, oPC, TRUE);
            if(bDebug) SendMessageToPC(oPC, "DEBUG: [craft_create] Durable tool returned.");
        }
        DestroyObject(oItem); 
        oItem = oNext;
    }

    // PHASE 3: FINAL DELIVERY
    if (bSuccess) {
        CreateItemOnObject(GetLocalString(oForge, "PP_RESULT_RESREF"), oPC);
        FloatingTextStringOnCreature("Crafting Success!", oPC);
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_MAGIC_RESISTANCE_USE), oPC);
    } else {
        FloatingTextStringOnCreature("Crafting Failed: Materials Ruined.", oPC);
    }
}
