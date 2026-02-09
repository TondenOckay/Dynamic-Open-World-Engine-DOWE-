// =============================================================================
// SCRIPT: area_items_inc (Version 1.0 - Master Library)
// Purpose: Universal logic for //smash and //open MUD interactions.
// Part of the DSE Version 7.0 System.
// =============================================================================

// Helper: Finds the nearest baked waypoint and returns its 2DA Row Index
int GetBakedPointIndex(object oPC)
{
    object oPoint = GetNearestObjectByTag("DSE_BAKED_POINT", oPC);
    if (!GetIsObjectValid(oPoint) || GetDistanceBetween(oPC, oPoint) > 3.5)
    {
        return -1;
    }
    // We store the 2DA row index on the waypoint when it is "baked"
    return GetLocalInt(oPoint, "ITEM_INDEX");
}

// Helper: Returns the actual Waypoint object being targeted
object GetBakedPointObject(object oPC)
{
    return GetNearestObjectByTag("DSE_BAKED_POINT", oPC);
}

// Logic for //smash - Destructive, Loud, and Performance-Friendly
void Uni_Smash(object oPC, int nIndex)
{
    object oPoint = GetBakedPointObject(oPC);
    string sLabel = Get2DAString("area_items", "Label", nIndex);
    int nVFX      = StringToInt(Get2DAString("area_items", "VFX", nIndex));
    int nMinGold  = StringToInt(Get2DAString("area_items", "GoldMin", nIndex));
    int nMaxGold  = StringToInt(Get2DAString("area_items", "GoldMax", nIndex));

    // 1. Play the "Smash" Visual at the waypoint's location
    ApplyEffectAtLocation(DURATION_TYPE_INSTANT, EffectVisualEffect(nVFX), GetLocation(oPoint));

    // 2. Sound/Noise Logic (Alerts LNS Engine Version 1.2 Monsters)
    // This makes 'Smash' riskier than 'Open'
    SignalEvent(oPoint, EventUserDefined(900)); // Custom "Noise" event

    // 3. Roll Gold and Grant Loot
    int nGrant = nMinGold + Random(nMaxGold - nMinGold + 1);
    if(nGrant > 0) GiveGoldToCreature(oPC, nGrant);

    // 4. Feedback
    SendMessageToPC(oPC, ">> You SMASH the " + sLabel + " and find " + IntToString(nGrant) + " gold!");

    // 5. THE PERFORMANCE WIN: Delete the data point from the world
    DestroyObject(oPoint);
}

// Logic for //open - Gentle, Quiet, and Virtualized
void Uni_Open(object oPC, int nIndex)
{
    object oPoint = GetBakedPointObject(oPC);
    string sLabel = Get2DAString("area_items", "Label", nIndex);
    int nMinGold  = StringToInt(Get2DAString("area_items", "GoldMin", nIndex));
    int nMaxGold  = StringToInt(Get2DAString("area_items", "GoldMax", nIndex));

    // 1. Animation (PC prying it open)
    AssignCommand(oPC, ActionPlayAnimation(ANIMATION_LOOPING_GET_LOW, 1.0, 1.0));

    // 2. Roll for loot
    int nGrant = nMinGold + Random(nMaxGold - nMinGold + 1);
    if(nGrant > 0) GiveGoldToCreature(oPC, nGrant);

    // 3. Feedback
    SendMessageToPC(oPC, ">> You carefully open the " + sLabel + ".");

    // Note: We do NOT DestroyObject here because it's just 'open', not destroyed.
}
