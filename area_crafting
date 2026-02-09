// area_crafting (Version 7.0 - Annotated Master)
// Logic: Multi-Mode Engine with 5-Slot Ingredient Support & Keyword Lookup
// -----------------------------------------------------------------------------
#include "area_craft_inc"

void ExecuteDelayedReward(object oPC, object oNode, string sMode, string s2DA, int nRow, string sSkill, int nGainRate);

void main() {
    // --- PHASE 1: INITIALIZATION ---
    object oPC   = GetLocalObject(OBJECT_SELF, "LAST_USER");
    object oNode = OBJECT_SELF;

    // Safety: Ensure valid user and prevent double-clicking
    if (!GetIsObjectValid(oPC) || GetLocalInt(oNode, "BUSY")) return;

    // Retrieve Node Variables (Set in Toolset or via MUD Chat)
    string sMode     = GetLocalString(oNode, "CRAFT_MODE");
    string s2DA      = GetLocalString(oNode, "CRAFT_2DA");
    string sSkill    = GetLocalString(oNode, "CRAFT_SKILL");
    string sKeyword  = GetLocalString(oNode, "CRAFT_KEYWORD");
    int nGainRate    = GetLocalInt(oNode, "CRAFT_GAIN");
    int nRow         = -1;

    // --- PHASE 1.1: KEYWORD & HELP LOOKUP (Dynamic Production) ---
    if (sMode == "PRODUCE") {
        // Handle help request first
        if (sKeyword == "help") {
            ListWorkstationKeywords(oPC, s2DA);
            return; // Exit: Help listed, no busy lock.
        }

        // Search for the specific recipe row via Keyword
        nRow = GetRecipeRowByKeyword(s2DA, sKeyword);

        if (nRow == -1) {
            SendMessageToPC(oPC, "Usage: //craft [keyword]. Type '//craft help' for a list of recipes.");
            return;
        }
    } else {
        // GATHERING mode still uses fixed toolset rows
        nRow = GetLocalInt(oNode, "CRAFT_ROW");
    }

    // --- PHASE 1.5: FORGE PRE-CHECK (Strict Multi-Validation) ---
    if (sMode == "PRODUCE") {
        // Updated to Gold Standard: Checks all 5 ResRef/Qty pairs in the 2DA
        string sError = GetForgeValidationMessage(oNode, s2DA, nRow);

        if (sError != "") {
            SendMessageToPC(oPC, sError);
            return; // EXIT EARLY: No animation, no busy lock.
        }
    }

    // Set lock now that we passed validation
    SetLocalInt(oNode, "BUSY", TRUE);

    // --- PHASE 2: SENSORY FEEDBACK (2DA LOOKUP) ---
    int nAnimRow = 0;
    string sCheck = Get2DAString("craft_skills", "SkillName", nAnimRow);
    while (sCheck != "" && sCheck != sSkill) {
        nAnimRow++;
        sCheck = Get2DAString("craft_skills", "SkillName", nAnimRow);
    }

    int nAnim      = StringToInt(Get2DAString("craft_skills", "AnimID", nAnimRow));
    string sSound  = Get2DAString("craft_skills", "SoundResRef", nAnimRow);
    float fLoop    = StringToFloat(Get2DAString("craft_skills", "LoopTime", nAnimRow));

    // --- PHASE 3: START ANIMATION ---
    AssignCommand(oPC, SetFacingPoint(GetPosition(oNode)));
    AssignCommand(oPC, ActionPlayAnimation(nAnim, 1.0, fLoop));
    PlaySound(sSound);

    // --- PHASE 4: STAGGERED SUCCESS ---
    DelayCommand(fLoop, ExecuteDelayedReward(oPC, oNode, sMode, s2DA, nRow, sSkill, nGainRate));

    // Reset Busy status slightly after reward to prevent animation-skipping exploits.
    DelayCommand(fLoop + 0.5, DeleteLocalInt(oNode, "BUSY"));
}

void ExecuteDelayedReward(object oPC, object oNode, string sMode, string s2DA, int nRow, string sSkill, int nGainRate) {
    if (!GetIsObjectValid(oPC)) return;

    int nPlayerSkill = GetCampaignInt("CRAFT_DB", "SKILL_" + sSkill, oPC);
    int nReqSkill    = StringToInt(Get2DAString(s2DA, "ReqSkill", nRow));
    int nBaseFail    = StringToInt(Get2DAString(s2DA, "FailChance", nRow));

    // --- PHASE 5: DYNAMIC SKILL MATH (The 4% Rule) ---
    int nSkillDiff = nPlayerSkill - nReqSkill;
    int nAdjustedFail = nBaseFail - (nSkillDiff * 4);
    if (nAdjustedFail < 5) nAdjustedFail = 5;

    // --- GATHERING MODE ---
    if (sMode == "GATHER") {
        if (d100() > nAdjustedFail) {
            int nRoll = d100();
            int nC1 = StringToInt(Get2DAString(s2DA, "Item1%", nRow));
            int nC2 = StringToInt(Get2DAString(s2DA, "Item2%", nRow));

            string sRes = (nRoll <= nC1) ? Get2DAString(s2DA, "Item1ResRef", nRow) :
                          (nRoll <= (nC1+nC2)) ? Get2DAString(s2DA, "Item2ResRef", nRow) :
                          Get2DAString(s2DA, "Item3ResRef", nRow);

            CreateItemOnObject(sRes, oPC);
            FloatingTextStringOnCreature("Harvested: " + sRes, oPC);

            int nHealth = GetLocalInt(oNode, "NODE_RES_COUNT");
            if (nHealth == 0) nHealth = Random(4) + 3;
            nHealth--;
            SetLocalInt(oNode, "NODE_RES_COUNT", nHealth);

            if (nHealth <= 0) {
                FloatingTextStringOnCreature("The source is depleted.", oPC);
                SetNodeCullState(oNode, TRUE);
            }
        } else {
            FloatingTextStringOnCreature("*Clang* - You failed to extract anything usable.", oPC);
        }
    }

    // --- PRODUCTION MODE (Forge/Workbench) ---
    else if (sMode == "PRODUCE") {
        // Materials were checked in Phase 1.5; we consume them now.
        ConsumeForgeMaterials(oNode);

        if (d100() > nAdjustedFail) {
            // Updated to use 'Result' column name for output
            string sCraftItem = Get2DAString(s2DA, "Result", nRow);
            CreateItemOnObject(sCraftItem, oPC);
            FloatingTextStringOnCreature("Successfully crafted: " + sCraftItem, oPC);
        } else {
            FloatingTextStringOnCreature("The materials were ruined in the process.", oPC);
            CreateItemOnObject("it_craft_slag", oNode);
        }
    }

    // --- PHASE 6: UNIVERSAL SKILL GAIN ---
    if (d100() <= nGainRate) {
        SetCampaignInt("CRAFT_DB", "SKILL_" + sSkill, nPlayerSkill + 1, oPC);
        FloatingTextStringOnCreature("Your " + sSkill + " skill has improved!", oPC);
    }
}
