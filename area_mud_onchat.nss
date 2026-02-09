// =============================================================================
// Script Name: area_mud_onchat
// Event:         Module OnPlayerChat
// Integration: Version 7.0 - FULL ANNOTATED MASTER (MUD Switching Logic)
// Standard:     Professional Vertical Breathing & High Readability
//
// VIRTUAL 2DA REFERENCE (mud_recipes.2da)
// -----------------------------------------------------------------------------
// Index | Label        | Skill      | Level | Input_Tag    | Output_ResRef
// -----------------------------------------------------------------------------
// 0     | Iron_Ingot   | Mining     | 5     | ore_iron     | ingot_iron
// 1     | Oak_Plank    | Woodcutting| 10    | log_oak      | plank_oak
// 2     | Mud_Brick    | Crafting   | 1     | raw_mud      | brick_mud
// 3     | Dagger       | Crafting   | 15    | ingot_iron   | nw_wswdg001
// =============================================================================

#include "area_mud_inc"
#include "area_craft_inc" // Added for Crafting/Gathering logic

void main() {
    object oPC   = GetPCChatSpeaker();
    string sChat = GetPCChatMessage();

    // --- PHASE 1: SAFETY & DM FILTER ---
    if (!GetIsObjectValid(oPC)) return;
    if (!GetIsPC(oPC) && !GetIsDM(oPC)) return;

    // --- PHASE 2: MUD PREFIX CHECK (//) ---
    if (GetStringLeft(sChat, 2) == "//")
    {
        string sLower = GetStringLowerCase(sChat);

        // --- PHASE 3: OBJECT INTERACTION SWITCH (Physics) ---
        if (FindSubString(sLower, "smash") != -1 || FindSubString(sLower, "open") != -1)
        {
            SetPCChatMessage("");
            ExecuteScript("area_objects", oPC);
            return;
        }

        // --- PHASE 3.5: CRAFTING & GATHERING SWITCH (New) ---
        // Logic: Stand near a node/forge and type the command.
        // INTEGRATED: //combine command for strict recipe production.
        // VERSION 7.0: Now extracts keywords for dynamic 2DA row lookup.
        if (FindSubString(sLower, "mine") != -1 ||
            FindSubString(sLower, "chop") != -1 ||
            FindSubString(sLower, "craft") != -1 ||
            FindSubString(sLower, "combine") != -1)
        {
            SetPCChatMessage("");

            string sReqTag = "";
            string sKeyword = "";

            // Map keywords to specific Toolset Tags
            if (FindSubString(sLower, "mine") != -1)      sReqTag = "NODE_MINING";
            else if (FindSubString(sLower, "chop") != -1) sReqTag = "NODE_WOOD";

            // Both 'craft' and 'combine' target the workstation containers
            else if (FindSubString(sLower, "craft") != -1 ||
                     FindSubString(sLower, "combine") != -1)
            {
                sReqTag = "FORGE_CONTAINER";

                // --- KEYWORD EXTRACTION LOGIC ---
                // Logic: Find the first space and take everything to the right.
                // Result: "//craft dagger" -> "dagger"
                int nSpace = FindSubString(sLower, " ");
                if (nSpace != -1)
                {
                    sKeyword = GetSubString(sLower, nSpace + 1, GetStringLength(sLower) - nSpace);
                }
            }

            // Find nearest node within 3.5 meters
            object oTarget = GetNearestObjectByTag(sReqTag, oPC);
            float fDist = GetDistanceBetween(oPC, oTarget);

            // Validate distance and Cull state
            if (GetIsObjectValid(oTarget) && fDist <= 3.5 && !GetLocalInt(oTarget, "IS_CULLED"))
            {
                // --- VERSION 7.0 UNIVERSAL SKILL GATEKEEPER ---
                // Logic: Check for a 'CRAFT_MIN_SKILL' (int) and 'CRAFT_SKILL_NAME' (string)
                // on the placeable. If player skill is lower than required, abort.
                int nRequired     = GetLocalInt(oTarget, "CRAFT_MIN_SKILL");
                string sSkillName = GetLocalString(oTarget, "CRAFT_SKILL_NAME"); // e.g. "Mining"

                // Dynamically check player skill (e.g. "MUD_SKILL_Mining")
                int nPlayerLevel  = GetLocalInt(oPC, "MUD_SKILL_" + sSkillName);

                if (nRequired > 0 && nPlayerLevel < nRequired)
                {
                    string sFail = "Your " + sSkillName + " skill is too low! (Required: " + IntToString(nRequired) + ")";
                    FloatingTextStringOnCreature(sFail, oPC, FALSE);
                    AssignCommand(oPC, PlaySound("as_cv_minehit1"));
                    return;
                }

                // Pass the PC and the Keyword to the target.
                SetLocalObject(oTarget, "LAST_USER", oPC);
                SetLocalString(oTarget, "CRAFT_KEYWORD", sKeyword);

                ExecuteScript("area_crafting", oTarget);
            }
            else
            {
                // Specific feedback if the player is just out of range or node is depleted
                if (GetIsObjectValid(oTarget) && GetLocalInt(oTarget, "IS_CULLED"))
                {
                    SendMessageToPC(oPC, "That resource or workstation is currently depleted.");
                }
                else
                {
                    SendMessageToPC(oPC, "You are not close enough to a valid source to do that.");
                }
            }
            return;
        }

        // --- PHASE 4: COMMERCE & SERVICE SWITCH ---
        if (FindSubString(sLower, "buy") != -1 || FindSubString(sLower, "sell") != -1)
        {
            SetPCChatMessage("");
            MUD_ProcessCommand(oPC, "service_shop");
            return;
        }

        // --- PHASE 5: NPC CONVERSATION SWITCH ---
        int iLen = GetStringLength(sChat);
        string sCmd = GetStringRight(sChat, iLen - 2);

        if (sCmd != "" && sCmd != " ")
        {
            SetPCChatMessage("");
            MUD_ProcessCommand(oPC, sCmd);
        }
    }
}
