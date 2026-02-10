/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    PLATFORM: Neverwinter Nights: Enhanced Edition (NWN:EE)
    MODULE: area_mud_op
    
    PILLARS:
    1. Environmental Reactivity (Climate/Terrain/Context)
    2. Biological Persistence (Hunger/Thirst/Fatigue)
    3. Optimized Scalability (480-Player Phase-Staggering)
    4. Intelligent Population (DSE v7.0 Integration)
    
    DESCRIPTION:
    Scans and indexes all Objects, NPCs, and Shops into local arrays on the 
    area object to ensure O(1) lookup speed. Now includes Node-Cull initialization
    to track depleted resource states across 480-player instances.
   ============================================================================
*/

/* // ----------------------------------------------------------------------------
// 2DA REFERENCE: area_objects.2da (Generated per Area)
// ----------------------------------------------------------------------------
// Label        Tag             Type        IsNode      MinSkill    RespawnTime
// IronVein     ORE_IRON_001    PLACEABLE   1           10          300
// SmithyBench  STATION_BLACK   PLACEABLE   0           15          0
// ----------------------------------------------------------------------------
// INTERNAL VARIABLE LIST (Virtual 2DA)
// ----------------------------------------------------------------------------
// Variable Name            | Type   | Description
// MUD_LIST_OBJ_[Index]     | Object | Stores Placeables (Nodes/Stations)
// MUD_LIST_NPC_[Index]     | Object | Stores all Non-PC Creatures
// MUD_LIST_SHOP_[Index]    | Object | Stores Creatures with 'IS_SHOPKEEPER' 1
// MUD_NODE_DEPLETED        | Int    | 0 = Active, 1 = Culled (Hidden)
// ----------------------------------------------------------------------------
*/

// --- PROTOTYPES ---
void DOWE_OP_Debug(string sMsg, object oArea);

// ----------------------------------------------------------------------------
// FUNCTION: DOWE_OP_Debug
// ----------------------------------------------------------------------------
void DOWE_OP_Debug(string sMsg, object oArea) {
    if (GetGlobalInt("DOWE_DEBUG_SWITCH") == 1) {
        SendMessageToPC(GetFirstPC(), "[DOWE OP DEBUG] " + GetName(oArea) + ": " + sMsg);
    }
}

// ----------------------------------------------------------------------------
// MAIN EXECUTION
// ----------------------------------------------------------------------------
void main() {
    object oArea = OBJECT_SELF;
    
    // Safety check to prevent redundant indexing and CPU spikes
    if (GetLocalInt(oArea, "MUD_INDEX_COMPLETE")) return;

    DOWE_OP_Debug("Phase 1: Starting Area Indexing and Node Initialization...", oArea);

    int nO = 0; int nN = 0; int nS = 0;
    object oT = GetFirstObjectInArea(oArea);

    // Triple-check loop for 480-player scalability (run once per area activation)
    while (GetIsObjectValid(oT)) {
        int nType = GetObjectType(oT);

        // Category 1: Objects (Placeables/Mining/Crafting)
        if (nType == OBJECT_TYPE_PLACEABLE) {
            nO++;
            SetLocalObject(oArea, "MUD_LIST_OBJ_" + IntToString(nO), oT);
            
            // --- NEW: NODE CULL INITIALIZATION ---
            // If the object is flagged as a node, ensure it is set to active 
            // and has its depletion variables wiped for a fresh start.
            if (GetLocalInt(oT, "IS_DOWE_NODE") == 1) {
                SetLocalInt(oT, "MUD_NODE_DEPLETED", 0);
                SetLocalInt(oT, "MUD_NODE_HITS", 0); // Logic handled in area_mud_obj
                SetHiddenObject(oT, FALSE); // Ensure it's visible on startup
            }
        }
        
        // Category 2: NPCs & Category 3: Shops
        else if (nType == OBJECT_TYPE_CREATURE && !GetIsPC(oT)) {
            nN++;
            SetLocalObject(oArea, "MUD_LIST_NPC_" + IntToString(nN), oT);
            
            // Check if NPC is marked as a Shopkeeper via local variable
            if (GetLocalInt(oT, "IS_SHOPKEEPER") == 1) {
                nS++;
                SetLocalObject(oArea, "MUD_LIST_SHOP_" + IntToString(nS), oT);
            }
        }
        
        // Stagger check: if area is massive, this loop remains sequential for the first load
        oT = GetNextObjectInArea(oArea);
    }

    // Finalize Registry
    SetLocalInt(oArea, "MUD_COUNT_OBJ", nO);
    SetLocalInt(oArea, "MUD_COUNT_NPC", nN);
    SetLocalInt(oArea, "MUD_COUNT_SHOP", nS);
    SetLocalInt(oArea, "MUD_INDEX_COMPLETE", 1);
    
    DOWE_OP_Debug("Phase 2: Indexing Complete. " + 
                  IntToString(nO) + " Objects, " + 
                  IntToString(nN) + " NPCs, and " + 
                  IntToString(nS) + " Shops registered.", oArea);
}
