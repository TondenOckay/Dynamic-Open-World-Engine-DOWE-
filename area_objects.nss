// =============================================================================
// LNS ENGINE: area_objects (Version 7.0 - MUD Interaction Master)
// Purpose: Handles //smash and //open keywords for baked area objects.
// Logic: Diverts traffic from Chat Listener to the Physics Library.
// =============================================================================

#include "area_objects_inc" // Contains Uni_Smash, Uni_Open, etc.

void main()
{
    // --- PHASE 1: INPUT PROCESSING ---
    string sChat  = GetPCChatMessage();
    object oPC    = GetPCChatSpeaker();
    string sLower = GetStringLowerCase(sChat);


    // Filter: Only process if it starts with the MUD prefix //
    if (GetStringLeft(sChat, 2) != "//") return;


    // --- PHASE 2: PROXIMITY SCAN ---
    // Locates the nearest 'Baked Point' (Waypoint/Invisible Object)
    int nIndex = GetBakedPointIndex(oPC);

    if (nIndex == -1)
    {
        SendMessageToPC(oPC, "There is nothing nearby to interact with.");
        return;
    }


    // --- PHASE 3: KEYWORD: //SMASH ---
    if (FindSubString(sLower, "smash") != -1)
    {
        // Reference the data table (area_items.2da or area_objects.2da)
        int nType = StringToInt(Get2DAString("area_items", "Type", nIndex));


        if (nType == 1) // Type 1: Smashable
        {
            Uni_Smash(oPC, nIndex);
            SetPCChatMessage("");   // Silence the command
        }
        else
        {
            SendMessageToPC(oPC, "That is too sturdy to smash! Try //open.");
            SetPCChatMessage("");
        }
    }


    // --- PHASE 4: KEYWORD: //OPEN ---
    else if (FindSubString(sLower, "open") != -1)
    {
        // Universal open logic (Prying lids or unlocking chests)
        Uni_Open(oPC, nIndex);
        SetPCChatMessage("");
    }
}
