//Scripts for run speed
// Script: mud_walk_toggle (The item's tag-based script)
void main() {
    // This tells the survival_core to run its "Toggle" phase
    ExecuteScript("survival_core", GetItemActivator());

//Im not sure how to set this up yet
//SetLocalInt(oPC, "RUNNING_MCT_PULSE", 1);
//ExecuteScript("survival_core", oPC);
//DeleteLocalInt(oPC, "RUNNING_MCT_PULSE");

}
