/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    MODULE: craft_gather
    
    DESCRIPTION:
    Processes node depletion and 10-slot loot tables. Uses staggered creation.
   ============================================================================
*/

void main() {
    object oPC = GetLastUsedBy();
    object oNode = OBJECT_SELF;
    
    int bDebug = GetLocalInt(GetModule(), "DOWE_DEBUG_MODE");
    int bSuccess = GetLocalInt(oNode, "TEMP_SUCCESS");

    if (!bSuccess) {
        FloatingTextStringOnCreature("*Resource Destroyed*", oPC);
        if(bDebug) SendMessageToPC(oPC, "DEBUG: [craft_gather] Success check returned FALSE.");
    } else {
        // PHASE 1: STAGGERED LOOT TABLE (10 SLOTS)
        // Each item is created with a slight delay to prevent inventory lag spikes.
        int i;
        float fDelay = 0.1;
        for(i = 1; i <= 10; i++) {
            string sRes = GetLocalString(oNode, "PP_ITEM" + IntToString(i));
            int nCh     = GetLocalInt(oNode, "PP_CH" + IntToString(i));

            if (sRes != "" && sRes != "****") {
                if (d100() <= nCh) {
                    DelayCommand(fDelay, [oPC, sRes]() { CreateItemOnObject(sRes, oPC); });
                    fDelay += 0.2; 
                }
            }
        }
    }

    // PHASE 2: NODE DEPLETION & CLEANUP
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_COM_CHUNK_STONE_SMALL), oNode);
    
    // PHASE 3: the_switchboard SIGNALING
    // Signals that this node is "Spent" and needs a respawn heartbeat.
    SetLocalInt(GetArea(oNode), "RESPAWN_PENDING_" + GetTag(oNode), TRUE);
    
    if(bDebug) SendMessageToPC(oPC, "DEBUG: [craft_gather] Process complete. Node cleaned.");
    DestroyObject(oNode, 0.4);
}
