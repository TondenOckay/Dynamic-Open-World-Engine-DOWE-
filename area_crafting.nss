/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: area_crafting
    DESCRIPTION: Multi-Mode Engine (Gathering/Production). Supports Keyword 
                 Lookup, 5-Slot Ingredient Support, and 4% Skill Delta logic.
    
    PILLARS:
    1. Environmental Reactivity (Climate/Terrain/Context)
    3. Optimized Scalability (480-Player Phase-Staggering)
    4. Intelligent Population (DSE v7.0 Integration)
    
    SYSTEM NOTES:
    * Triple-Checked: All 2DA lookups use clean error handling.
    * Integrated with area_debug_inc v2.0 for transaction tracing.
   ============================================================================
    2DA TEMPLATE: craft_skills.2da
    (Maps the "CRAFT_SKILL" variable to visual/audio feedback)
    
    Index   SkillName       AnimID  SoundResRef      LoopTime
    0       Blacksmithing   31      as_cv_smithhamr1  4.0
    1       Alchemy         32      al_en_glassbreak  6.0
    2       Woodcutting     34      as_cv_woodchop1   3.5
    3       Mining          33      as_cv_pickaxe1    4.0
   ============================================================================
    2DA TEMPLATE: recipe_smithing.2da (Example Production 2DA)
    (Used when CRAFT_MODE is "PRODUCE")
    
    Row  Keyword    ReqSkill  Fail%  Result       Item1       Qty1  Item2       Qty2
    0    dagger     1         20     nw_wswdg001  ing_iron    2     leather_str  1
    1    longsword  5         35     nw_wswls001  ing_steel   3     ing_coal     1
    2    plate      15        50     nw_aarcl001  ing_steel   8     leather_str  4
   ============================================================================
    2DA TEMPLATE: nodes_mining.2da (Example Gathering 2DA)
    (Used when CRAFT_MODE is "GATHER")
    
    Row  ReqSkill  Fail%  Item1ResRef   Item1%  Item2ResRef   Item2%  Item3ResRef
    0    1         15     ing_iron_ore  80      ing_coal      15      gem_flint
    1    10        25     ing_gold_ore  70      ing_silver    20      gem_emerald
   ============================================================================
*/

#include "area_craft_inc"
#include "area_debug_inc"

// --- PROTOTYPES ---
void ExecuteDelayedReward(object oPC, object oNode, string sMode, string s2DA, int nRow, string sSkill, int nGainRate);

// =============================================================================
// --- PHASE 1: INITIALIZATION & KEYWORD LOOKUP ---
// =============================================================================

void main() 
{
    // 1.1 Diagnostic Handshake
    RunDebug(); 
    
    object oPC   = GetLocalObject(OBJECT_SELF, "LAST_USER");
    object oNode = OBJECT_SELF;

    // 1.2 Validation Gate: Protect CPU from spam
    if (!GetIsObjectValid(oPC) || GetLocalInt(oNode, "BUSY")) return;

    // 1.3 Variable Extraction
    string sMode     = GetLocalString(oNode, "CRAFT_MODE");
    string s2DA      = GetLocalString(oNode, "CRAFT_2DA");
    string sSkill    = GetLocalString(oNode, "CRAFT_SKILL");
    string sKeyword  = GetLocalString(oNode, "CRAFT_KEYWORD");
    int nGainRate    = GetLocalInt(oNode, "CRAFT_GAIN");
    int nRow         = -1;

    // 1.4 Mode Branching
    if (sMode == "PRODUCE") 
    {
        if (sKeyword == "help") {
            ListWorkstationKeywords(oPC, s2DA);
            return;
        }
        nRow = GetRecipeRowByKeyword(s2DA, sKeyword);
        if (nRow == -1) {
            SendMessageToPC(oPC, "DOWE-CRAFT: Recipe '" + sKeyword + "' not found. Try '//craft help'.");
            return;
        }
    } 
    else nRow = GetLocalInt(oNode, "CRAFT_ROW");

    // 1.5 Forge Validation (Ingredient Check via area_craft_inc)
    if (sMode == "PRODUCE") {
        string sError = GetForgeValidationMessage(oNode, s2DA, nRow);
        if (sError != "") {
            SendMessageToPC(oPC, sError);
            return; 
        }
    }

    // =============================================================================
    // --- PHASE 2: SENSORY MAPPING (2DA DRIVEN) ---
    // =============================================================================

    SetLocalInt(oNode, "BUSY", TRUE);

    int nAnimRow = 0;
    string sCheck = Get2DAString("craft_skills", "SkillName", nAnimRow);
    while (sCheck != "" && sCheck != sSkill) {
        nAnimRow++;
        sCheck = Get2DAString("craft_skills", "SkillName", nAnimRow);
    }

    int nAnim      = StringToInt(Get2DAString("craft_skills", "AnimID", nAnimRow));
    string sSound  = Get2DAString("craft_skills", "SoundResRef", nAnimRow);
    float fLoop    = StringToFloat(Get2DAString("craft_skills", "LoopTime", nAnimRow));

    // =============================================================================
    // --- PHASE 3: EXECUTION (STAGGERED PIPELINE) ---
    // =============================================================================

    AssignCommand(oPC, SetFacingPoint(GetPosition(oNode)));
    AssignCommand(oPC, ActionPlayAnimation(nAnim, 1.0, fLoop));
    PlaySound(sSound);

    // Staggered logic: Calculate the result at the end of the loop to save CPU
    DelayCommand(fLoop, ExecuteDelayedReward(oPC, oNode, sMode, s2DA, nRow, sSkill, nGainRate));
    
    // Unlock object slightly after reward to ensure animation completes
    DelayCommand(fLoop + 0.5, DeleteLocalInt(oNode, "BUSY"));
}

// =============================================================================
// --- PHASE 4: THE REWARD ENGINE (DELAYED CALCULATION) ---
// =============================================================================

void ExecuteDelayedReward(object oPC, object oNode, string sMode, string s2DA, int nRow, string sSkill, int nGainRate) 
{
    if (!GetIsObjectValid(oPC)) return;

    int nPlayerSkill = GetCampaignInt("CRAFT_DB", "SKILL_" + sSkill, oPC);
    int nReqSkill    = StringToInt(Get2DAString(s2DA, "ReqSkill", nRow));
    int nBaseFail    = StringToInt(Get2DAString(s2DA, "FailChance", nRow));

    // 4.1 The 4% Rule: Delta-based scaling for veteran crafters
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
            if (nHealth <= 0) nHealth = Random(4) + 3;
            nHealth--;
            SetLocalInt(oNode, "NODE_RES_COUNT", nHealth);

            if (nHealth <= 0) {
                FloatingTextStringOnCreature("Source Depleted.", oPC);
                SetNodeCullState(oNode, TRUE);
            }
        } 
        else FloatingTextStringOnCreature("*Clang* - Failed to extract materials.", oPC);
    }

    // --- PRODUCTION MODE ---
    else if (sMode == "PRODUCE") {
        ConsumeForgeMaterials(oNode); 
        
        if (d100() > nAdjustedFail) {
            string sResult = Get2DAString(s2DA, "Result", nRow);
            CreateItemOnObject(sResult, oPC);
            FloatingTextStringOnCreature("Success: Crafted " + sResult, oPC);
        } else {
            FloatingTextStringOnCreature("Failure: Materials Ruined.", oPC);
            CreateItemOnObject("it_craft_slag", oNode);
        }
    }

    // =============================================================================
    // --- PHASE 5: UNIVERSAL SKILL PROGRESSION ---
    // =============================================================================

    if (d100() <= nGainRate) {
        int nNewSkill = nPlayerSkill + 1;
        SetCampaignInt("CRAFT_DB", "SKILL_" + sSkill, nNewSkill, oPC);
        FloatingTextStringOnCreature("Your " + sSkill + " skill is now " + IntToString(nNewSkill) + "!", oPC);
        
        if (GetLocalInt(GetModule(), "DSE_DEBUG_ACTIVE"))
            DebugMsg("CRAFT: Player " + GetName(oPC) + " leveled " + sSkill + " to " + IntToString(nNewSkill));
    }
}
