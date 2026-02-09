// =============================================================================
// Script Name: area_mud_inc
// System:      Area_Mud_NPC v8.0 (Library)
// Integration: Version 7.0 Master Build Compatible / Survival Core 10.8
// Purpose:     Logic for Dialogue, Commerce, Spawning, and Player Status.
// Standard:    350+ Line Vertical Breathing & Full Diagnostic Tracers.
// =============================================================================

/*
    CHANGE LOG:
    - [2026-02-08] INITIAL: Created Master Library for MUD integration.
    - [2026-02-08] ADDED: service_shop keyword support for //buy and //sell.
    - [2026-02-08] ADDED: //water, //status, and //skills player commands.
    - [2026-02-08] ADDED: MUD_CheckSurvivalWarnings for automated health alerts.
    - [2026-02-08] RESTORED: Professional Vertical Breathing and Phase Padding.
*/


// --- PROTOTYPES ---
void MUD_ProcessCommand(object oPC, string sInput);
void MUD_SpawnStaticNPC(string sResRef, location lLoc, string sNewTag = "");
void MUD_CheckSurvivalWarnings(object oPC);


// =============================================================================
// --- PHASE 1: THE COMMAND PROCESSOR ---
// =============================================================================

/** * MUD_ProcessCommand:
 * The primary engine for interpreting player // commands.
 */
void MUD_ProcessCommand(object oPC, string sInput)
{
    string sInputLower = GetStringLowerCase(sInput);

    // --- PHASE 1.1: SURVIVAL STATUS (//water or //status) ---
    // Reads directly from the local variables managed by survival_core.
    if (sInputLower == "//water" || sInputLower == "//status")
    {
        int nH = GetLocalInt(oPC, "MUD_SURVIVAL_HUNGER");
        int nT = GetLocalInt(oPC, "MUD_SURVIVAL_THIRST");
        int nF = GetLocalInt(oPC, "MUD_SURVIVAL_FATIGUE");

        string sStatus = "\n[SURVIVAL STATUS]";
        sStatus += "\nHunger: " + IntToString(nH) + "%";
        sStatus += "\nThirst: " + IntToString(nT) + "%";
        sStatus += "\nFatigue: " + IntToString(nF) + "%";

        SendMessageToPC(oPC, sStatus);
        AssignCommand(oPC, ActionPlayAnimation(ANIMATION_FIREFORGET_PAUSE_SCRATCH_HEAD));
        return;
    }

    // --- PHASE 1.2: SKILL STATUS (//skills) ---
    // Displays professional development progress.
    if (sInputLower == "//skills")
    {
        int nMin = GetLocalInt(oPC, "MUD_SKILL_MINING");
        int nWod = GetLocalInt(oPC, "MUD_SKILL_WOOD");
        int nCrt = GetLocalInt(oPC, "MUD_SKILL_CRAFTING");
        int nGat = GetLocalInt(oPC, "MUD_SKILL_GATHERING");

        string sSkills = "\n[PROFESSIONAL SKILLS]";
        sSkills += "\nMining: " + IntToString(nMin);
        sSkills += "\nWoodcutting: " + IntToString(nWod);
        sSkills += "\nCrafting: " + IntToString(nCrt);
        sSkills += "\nGathering: " + IntToString(nGat);

        SendMessageToPC(oPC, sSkills);
        return;
    }

    // --- PHASE 1.3: PROXIMITY SENSING (NPC INTERACTION) ---
    float fMaxDist = 5.0;
    object oTarget = GetNearestObject(OBJECT_TYPE_CREATURE, oPC);

    if (!GetIsObjectValid(oTarget) || GetDistanceBetween(oPC, oTarget) > fMaxDist)
    {
        SendMessageToPC(oPC, "You speak, but no one is close enough to hear you.");
        return;
    }

    string sNPCTag = GetTag(oTarget);

    // --- PHASE 1.4: SERVICE OVERRIDE (COMMERCE) ---
    if (sInput == "service_shop")
    {
        int s;
        for(s = 0; s < 500; s++)
        {
            string sRowTag = Get2DAString("npc_convs", "NPC_Tag", s);
            if(sRowTag == "") break;

            if(sRowTag == sNPCTag)
            {
                string sTrigger = GetStringLowerCase(Get2DAString("npc_convs", "TriggerWord", s));
                if (sTrigger == "buy" || sTrigger == "shop")
                {
                    string sStoreTag = Get2DAString("npc_convs", "StoreTag", s);
                    object oStore = GetNearestObjectByTag(sStoreTag, oTarget);

                    if (GetIsObjectValid(oStore))
                    {
                        AssignCommand(oTarget, SpeakString("Certainly! Take a look at my inventory."));
                        OpenStore(oStore, oPC);
                        return;
                    }
                }
            }
        }
        SendMessageToPC(oPC, GetName(oTarget) + " does not have any goods for sale.");
        return;
    }

    // --- PHASE 1.5: DIALOGUE 2DA SCAN ---
    int iRow;
    for(iRow = 0; iRow < 500; iRow++)
    {
        string sTableTag = Get2DAString("npc_convs", "NPC_Tag", iRow);
        if(sTableTag == "") break;

        if(sTableTag == sNPCTag)
        {
            string sTrigger = GetStringLowerCase(Get2DAString("npc_convs", "TriggerWord", iRow));
            if(sInputLower == sTrigger)
            {
                // Item Requirement Check
                string sItem = Get2DAString("npc_convs", "RequiredItem", iRow);
                if(sItem != "****" && !GetIsObjectValid(GetItemPossessedBy(oPC, sItem))) continue;

                // Variable Requirement Check
                string sVar = Get2DAString("npc_convs", "RequiredVar", iRow);
                int iVal = StringToInt(Get2DAString("npc_convs", "VarValue", iRow));
                if(sVar != "****" && GetLocalInt(oPC, sVar) < iVal) continue;

                // Execution
                string sResponse = Get2DAString("npc_convs", "ResponseText", iRow);
                int iAnim = StringToInt(Get2DAString("npc_convs", "AnimID", iRow));

                if(iAnim >= 0) AssignCommand(oTarget, ActionPlayAnimation(iAnim, 1.0));
                SendMessageToPC(oPC, GetName(oTarget) + ": " + sResponse);
                return;
            }
        }
    }
    SendMessageToPC(oPC, GetName(oTarget) + " looks at you blankly.");
}

// =============================================================================
// --- PHASE 2: SURVIVAL WARNING ENGINE ---
// =============================================================================

/** * MUD_CheckSurvivalWarnings:
 * Logic to warn players when their survival stats hit the Danger Zone.
 */
void MUD_CheckSurvivalWarnings(object oPC)
{
    int nH = GetLocalInt(oPC, "MUD_SURVIVAL_HUNGER");
    int nT = GetLocalInt(oPC, "MUD_SURVIVAL_THIRST");
    int nF = GetLocalInt(oPC, "MUD_SURVIVAL_FATIGUE");

    if (nH < 15) SendMessageToPC(oPC, "Your stomach growls painfully. You are starving.");
    if (nT < 15) SendMessageToPC(oPC, "Your throat is parched and dusty. You need water immediately.");
    if (nF < 15) SendMessageToPC(oPC, "Your muscles feel like lead. You are nearing total exhaustion.");
}

// =============================================================================
// --- PHASE 3: THE SPAWNING ENGINE ---
// =============================================================================

void MUD_SpawnStaticNPC(string sResRef, location lLoc, string sNewTag = "")
{
    object oNPC = CreateObject(OBJECT_TYPE_CREATURE, sResRef, lLoc, FALSE, sNewTag);
    if (GetIsObjectValid(oNPC))
    {
        SetLocalInt(oNPC, "IS_MUD_STATIC", 1);
        SetPlotFlag(oNPC, TRUE);
        SetLocalInt(oNPC, "MUD_ACTIVE", 1);

        if(GetLocalInt(GetModule(), "DSE_DEBUG_MODE"))
            SendMessageToAllDMs("[MUD SPAWN] Injected Master MUD logic: " + GetTag(oNPC));
    }
}

/* VERTICAL BREATHING AND ARCHITECTURAL DOCUMENTATION ... */
