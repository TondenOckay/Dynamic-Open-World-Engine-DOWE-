/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: area_mud_spawn

    PILLARS:
    1. Environmental Reactivity (Climate/Terrain/Context)
    2. Biological Persistence (Hunger/Thirst/Fatigue)
    3. Optimized Scalability (480-Player Phase-Staggering)
    4. Intelligent Population (DSE v7.0 Integration)

    SYSTEM NOTES:
    * Built for 2026 High-Readability Standard.
    * Integrated with auto_save_inc v8.0 & area_mud_inc v8.0.
   ============================================================================
*/

#include "area_mud_inc"

// --- CONSTANTS ---
const float CAMP_DECAY_TIME = 1800.0; // 30 Minutes (CPU Safety)

void main() {
    object oPC = OBJECT_SELF;
    object oItem = GetItemActivated();
    string sTag = GetTag(oItem);
    location lLoc = GetItemActivatedTargetLocation();

    // Determine ResRef based on Item Tag
    string sResRef = "";
    if (sTag == "MUD_ITM_FIREKIT") sResRef = "mud_obj_fire";
    else if (sTag == "MUD_ITM_TENTKIT") sResRef = "mud_obj_tent";

    if (sResRef == "") return;

    // Execute Spawn
    object oCampObj = CreateObject(OBJECT_TYPE_PLACEABLE, sResRef, lLoc);

    if (GetIsObjectValid(oCampObj)) {
        // Retrieve VIP ID from Area Manager data on Player
        int nVIP = GetLocalInt(oPC, "PLAYER_VIP_ID");
        string sName = GetName(oPC);

        // Visual and Internal Ownership Tagging
        SetName(oCampObj, sName + "'s " + GetName(oCampObj));
        SetLocalInt(oCampObj, "MUD_OWNER_VIP", nVIP);
        SetLocalString(oCampObj, "MUD_OWNER_NAME", sName);

        // Performance Safety: Auto-cleanup
        DestroyObject(oCampObj, CAMP_DECAY_TIME);

        // Visual Feedback
        ApplyEffectAtLocation(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_PULSE_NATURE), lLoc);
        SendMessageToPC(oPC, "Camp equipment deployed and linked to VIP ID: " + IntToString(nVIP));
    }
}
