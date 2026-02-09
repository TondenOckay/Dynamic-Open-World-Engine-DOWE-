/* ============================================================================
    PROJECT: Dynamic Open World Engine (DOWE)
    VERSION: 2.0 (Master Build)
    MODULE: area_mud_cmd
    
    DESCRIPTION:
    Centralized Player Command Hub. Processes //dowe and other survival-related
    text inputs for the 480-player ecosystem.
    ============================================================================
*/

#include "area_mud_inc"

void main() {
    object oPC = OBJECT_SELF;
    // Extract the command from the player's chat (assuming standard command parsing)
    // For this example, we'll focus on the //dowe output.

    SendMessageToPC(oPC, " "); 
    SendMessageToPC(oPC, "--- DYNAMIC OPEN WORLD ENGINE (DOWE) v2.0 ---");
    SendMessageToPC(oPC, "The world is alive and reactive. Your survival depends on context.");
    SendMessageToPC(oPC, "--------------------------------------------------");
    
    // Pillar 1: Movement & Stamina
    SendMessageToPC(oPC, "• MOVEMENT: Toggle 'Walk Mode' on your hotbar to conserve energy.");
    SendMessageToPC(oPC, "  Running drains Fatigue every 6s unless Walk Mode is active.");
    
    // Pillar 2: Thermal & Environment
    SendMessageToPC(oPC, "• CLIMATE: Seeking shade (Interiors/Caves) or standing near fires");
    SendMessageToPC(oPC, "  is mandatory for survival in extreme desert temperatures.");
    
    // Pillar 3: Recovery (The Timer System)
    SendMessageToPC(oPC, "• SHORT REST (240s): 75% Fatigue / 5% HP recovery.");
    SendMessageToPC(oPC, "• LONG REST (960s): 100% Recovery + Spells. Requires a Tent.");
    
    // Pillar 4: The VIP Identity
    SendMessageToPC(oPC, "• LOGISTICS: Tents and Fires are tagged to your VIP ID.");
    SendMessageToPC(oPC, "  Casters must possess a Spellbook to recover magic during rest.");
    
    SendMessageToPC(oPC, "--------------------------------------------------");
}
