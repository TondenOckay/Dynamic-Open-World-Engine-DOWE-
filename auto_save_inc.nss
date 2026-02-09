// =============================================================================
// Script Name: auto_save_inc
// Version:     8.0 - EE MASTER BUILD (Integrated Skills & Survival)
// System:      MUD Persistence Engine
// Standard:    God Standard Native EE Campaign Persistence
// Order:       Mining | Wood | Craft | Gather | Hunger | Thirst | Fatigue
// =============================================================================

// --- PROTOTYPES ---
void ExportToDB(object oPC);
void HandleGhostLogout(object oPC);
void ExecutePulseSave(object oArea);

// =============================================================================
// --- PHASE 1: THE MASTER EXPORTER ---
// =============================================================================
void ExportToDB(object oPC)
{
    // 1. Validation Check
    // We only process valid PCs who have been flagged as "Dirty" (Modified).
    if (!GetIsObjectValid(oPC) || !GetLocalInt(oPC, "IS_DIRTY")) return;

    // 2. Identification (CD Key + Name)
    // Using CD Key as the primary key ensures 8-server cluster synchronization.
    string sID = GetPCPublicCDKey(oPC) + "_" + GetName(oPC);
    string sDB = "MUD_DATA";

    // 3. Data String Construction (The Big Seven)

    // --- SKILLS ---
    string sMin = IntToString(GetLocalInt(oPC, "MUD_SKILL_MINING"));
    string sWod = IntToString(GetLocalInt(oPC, "MUD_SKILL_WOOD"));
    string sCrt = IntToString(GetLocalInt(oPC, "MUD_SKILL_CRAFTING"));
    string sGat = IntToString(GetLocalInt(oPC, "MUD_SKILL_GATHERING"));

    // --- SURVIVAL (New for v8.0) ---
    string sHng = IntToString(GetLocalInt(oPC, "MUD_SURVIVAL_HUNGER"));
    string sThr = IntToString(GetLocalInt(oPC, "MUD_SURVIVAL_THIRST"));
    string sFat = IntToString(GetLocalInt(oPC, "MUD_SURVIVAL_FATIGUE"));

    // Result format: "Min|Wod|Crt|Gat|Hng|Thr|Fat"
    // Example: "15|40|10|5|100|85|90"
    string sData = sMin + "|" + sWod + "|" + sCrt + "|" + sGat + "|" + sHng + "|" + sThr + "|" + sFat;

    // 4. THE CORRECT EE SYNTAX: SetCampaignString
    // This writes to the physical .tlk or database file in the /database folder.
    SetCampaignString(sDB, sID, sData, oPC);

    // 5. Cleanup & Debug
    // Reset dirty flag to prevent redundant writes until the next change.
    SetLocalInt(oPC, "IS_DIRTY", 0);

    if(GetLocalInt(GetModule(), "DSE_DEBUG_MODE"))
    {
        WriteTimestampedLogEntry("[DSE_DEBUG] MASTER_SYNC: " + sID + " [SUCCESS]");
    }
}

// =============================================================================
// --- PHASE 2: GHOST SYSTEM ---
// =============================================================================
void HandleGhostLogout(object oPC)
{
    location lExit = GetLocation(oPC);
    object oGhost = CopyObject(oPC, lExit, OBJECT_INVALID, "LOGOUT_GHOST");

    if (GetIsObjectValid(oGhost))
    {
        SetName(oGhost, GetName(oPC) + " [Syncing...]");
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, EffectVisualEffect(VFX_DUR_GHOSTLY_VISAGE), oGhost);

        // Final Sync 30s later via the Ghost NPC to ensure final state capture.
        DelayCommand(30.0, ExportToDB(oGhost));
        DelayCommand(30.1, DestroyObject(oGhost));
    }
}

// =============================================================================
// --- PHASE 3: THE PULSE ---
// =============================================================================
void ExecutePulseSave(object oArea)
{
    int nBeat = GetLocalInt(oArea, "CURRENT_BEAT") + 1;
    if (nBeat > 5) nBeat = 1;
    SetLocalInt(oArea, "CURRENT_BEAT", nBeat);

    int nIndex = 1;
    float fStagger = 0.0;
    object oPC = GetFirstObjectInArea(oArea);

    while (GetIsObjectValid(oPC))
    {
        if (GetIsPC(oPC))
        {
            // Only save 1/5th of the players per beat to flatten CPU spikes.
            if ((nIndex % 5) == (nBeat % 5))
            {
                // 0.4s Stagger to prevent file-lock lag on high population.
                DelayCommand(fStagger, ExportToDB(oPC));
                fStagger += 0.4;
            }
            nIndex++;
        }
        oPC = GetNextObjectInArea(oArea);
    }
}
