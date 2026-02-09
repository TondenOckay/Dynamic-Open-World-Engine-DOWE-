// area_craft_inc (Version 7.0 - Annotated Master)
// Phase: Sensory Feedback, Node Management & Multi-Ingredient Validation
// -----------------------------------------------------------------------------
/* EXAMPLE: craft_skills.2da
    Row | Label    | SkillName      | AnimID | SoundResRef    | LoopTime
    0   | Mining   | Mining         | 6      | as_cv_minetin2 | 3.0
    1   | Woodcut  | Woodcutting    | 20     | as_cv_woodchop1| 2.5
    2   | Forge    | Blacksmithing  | 11     | as_cv_blacksmth1| 4.0
*/

/* EXAMPLE: forge_recipes.2da (The 5-Slot Multi-Recipe System with Keywords)
    Row | Label      | Keyword  | Res1       | Qty1 | Res2       | Qty2 | Res3 | Qty3 | Res4 | Qty4 | Res5 | Qty5 | Result     | ReqSkill | Fail
    0   | Iron Dagger| dagger   | iron_ingot | 2    | leather_st | 1    | **** | 0    | **** | 0    | **** | 0    | it_dag_001 | 5        | 25
    1   | Chain Shirt| shirt    | iron_ingot | 8    | **** | 0    | **** | 0    | **** | 0    | **** | 0    | it_arm_005 | 15       | 35
*/
// -----------------------------------------------------------------------------

// Calculates success based on skill vs req (4% per point)
int GetCraftSuccessChance(int nPlayerSkill, int nReqSkill, int nBaseChance) {
    int nChance = nBaseChance + ((nPlayerSkill - nReqSkill) * 4);
    if (nChance > 100) nChance = 100;
    if (nChance < 0) nChance = 0;
    return nChance;
}

// Manages the "Cull" state (Vanish/Appear)
void SetNodeCullState(object oNode, int bCulled) {
    if (bCulled) {
        SetPlotFlag(oNode, FALSE);
        SetObjectVisualTransform(oNode, OBJECT_VISUAL_TRANSFORM_SCALE, 0.0);
        SetLocalInt(oNode, "IS_CULLED", TRUE);
    } else {
        SetObjectVisualTransform(oNode, OBJECT_VISUAL_TRANSFORM_SCALE, 1.0);
        DeleteLocalInt(oNode, "IS_CULLED");
        DeleteLocalInt(oNode, "NODE_RES_COUNT");
    }
}

// Scans the 2DA for a matching keyword. Returns -1 if not found.
int GetRecipeRowByKeyword(string s2DA, string sKeyword) {
    int i = 0;
    string sCheck = Get2DAString(s2DA, "Keyword", i);
    while (sCheck != "") {
        if (sCheck == sKeyword) return i;
        i++;
        sCheck = Get2DAString(s2DA, "Keyword", i);
    }
    return -1;
}

// Lists all available keywords for the player
void ListWorkstationKeywords(object oPC, string s2DA) {
    SendMessageToPC(oPC, "Available recipes at this station:");
    int i = 0;
    string sLabel = Get2DAString(s2DA, "Label", i);
    string sKey   = Get2DAString(s2DA, "Keyword", i);
    while (sLabel != "") {
        SendMessageToPC(oPC, " - " + sLabel + " (Keyword: //craft " + sKey + ")");
        i++;
        sLabel = Get2DAString(s2DA, "Label", i);
        sKey   = Get2DAString(s2DA, "Keyword", i);
    }
}

// Strict Multi-Recipe Check: Returns error message or "" if perfect.
string GetForgeValidationMessage(object oForge, string s2DA, int nRow) {
    int i;
    int bInvalidFound = FALSE;
    string sInvalidTag = "";

    // STEP 1: SCAN FOR CONTAMINATION (Wrong items)
    object oItem = GetFirstItemInInventory(oForge);
    while (GetIsObjectValid(oItem)) {
        string sItemRes = GetResRef(oItem);
        int bMatched = FALSE;

        for (i = 1; i <= 5; i++) {
            string sReq = Get2DAString(s2DA, "Res" + IntToString(i), nRow);
            if (sItemRes == sReq) {
                bMatched = TRUE;
                break;
            }
        }

        if (!bMatched) {
            bInvalidFound = TRUE;
            sInvalidTag = sItemRes;
            break;
        }
        oItem = GetNextItemInInventory(oForge);
    }

    if (bInvalidFound) return "Invalid item found in forge: [" + sInvalidTag + "]. Remove it to proceed.";

    // STEP 2: SCAN QUANTITIES (Strict match for all 5 potential slots)
    for (i = 1; i <= 5; i++) {
        string sRes = Get2DAString(s2DA, "Res" + IntToString(i), nRow);
        int nQty    = StringToInt(Get2DAString(s2DA, "Qty" + IntToString(i), nRow));

        if (sRes != "" && sRes != "****") {
            int nFound = 0;
            object oCheck = GetFirstItemInInventory(oForge);
            while (GetIsObjectValid(oCheck)) {
                if (GetResRef(oCheck) == sRes) nFound += GetItemStackSize(oCheck);
                oCheck = GetNextItemInInventory(oForge);
            }

            if (nFound < nQty) return "Insufficient materials: [" + sRes + "]. Need " + IntToString(nQty) + ", found " + IntToString(nFound) + ".";
            if (nFound > nQty) return "Too much [" + sRes + "] in forge! Recipe only requires " + IntToString(nQty) + ".";
        }
    }

    return ""; // Exact match confirmed.
}

// Purges the forge inventory (materials consumed)
void ConsumeForgeMaterials(object oForge) {
    object oItem = GetFirstItemInInventory(oForge);
    while (GetIsObjectValid(oItem)) {
        DestroyObject(oItem);
        oItem = GetNextItemInInventory(oForge);
    }
}
