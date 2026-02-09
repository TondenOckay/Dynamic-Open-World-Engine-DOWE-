/* NAME: survival_core
    VERSION: 12.1 - GOLD STANDARD MASTER BUILD
    AUTHOR: Gemini
    PERFORMANCE: Phase-Staggered Logic for 480-Player Scale
    BASE: area_dse (Pseudo-Heartbeat / 1200s Pulse)
    INTEGRATION: auto_save_inc v8.0 & area_mud_inc v8.0 | area_rest v1.0

    // =========================================================================
    // THE 2DA BLUEPRINT (Reference for: mud_survival.2da)
    // =========================================================================
    // ID   LABEL       HNG_DRAIN  THR_DRAIN  FAT_DRAIN  WGT_CAP    MOVE_MOD
    // 0    DWARF       10         15         5          250        0.90
    // 1    ELF         6          10         4          120        1.10
    // 2    GNOME       5          8          3          100        0.85
    // 3    HALFLING    5          7          3          100        0.85
    // 4    HALFELF     8          12         5          160        1.00
    // 5    HALFORC     14         20         8          300        1.00
    // 6    HUMAN       9          13         6          180        1.00
    // 10   CAMEL       5          40         15         800        1.15
    // 11   MULE        12         20         20         500        0.95
    // 12   HENCHMAN    9          13         10         175        1.00
    // =========================================================================

    // =========================================================================
    // THE TERRAIN BLUEPRINT (Reference for: mud_terrain.2da)
    // =========================================================================
    // ID   LABEL          FAT_MOD   XP_DRAIN   NOTE
    // 0    DIRT           1         0          Standard
    // 1    SAND           3         5          High exertion
    // 2    GRASS          1         0          Standard
    // 3    STONE          0         0          Easy path
    // 4    WATER          4         10         Wading/Swimming
    // 5    MUD            3         8          Sticky terrain
    // =========================================================================
*/

#include "auto_save_inc" // Version 8.0 Master Persistence
#include "area_mud_inc"  // Version 8.0 Master Library (Warnings & Commands)

// --- CONSTANTS ---
const float COIN_WEIGHT  = 0.02;
const string REF_2DA     = "mud_survival";
const string TERRAIN_2DA = "mud_terrain";

// --- PHASE 1: PHYSICS & WEIGHT ---
void ExecuteWeightPhase(object oPC, int nRace) {
    float fTotal = 0.0;
    object oItem = GetFirstItemInInventory(oPC);

    while (GetIsObjectValid(oItem)) {
        fTotal += GetLocalFloat(oItem, "MUD_ITEM_WEIGHT");
        oItem = GetNextItemInInventory(oPC);
    }

    fTotal += (IntToFloat(GetGold(oPC)) * COIN_WEIGHT);
    float fCap = StringToFloat(Get2DAString(REF_2DA, "WGT_CAP", nRace));

    if (fTotal > fCap) {
        int nSlow = FloatToInt(((fTotal - fCap) / fCap) * 100.0);
        if (nSlow > 95) nSlow = 95;

        effect eEff = GetFirstEffect(oPC);
        while(GetIsEffectValid(eEff)) {
            if(GetEffectType(eEff) == EFFECT_TYPE_MOVEMENT_SPEED_DECREASE) RemoveEffect(oPC, eEff);
            eEff = GetNextEffect(oPC);
        }
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, EffectMovementSpeedDecrease(nSlow), oPC);
    }
}

// --- MASTER MAIN ---
void main() {
    object oPC = OBJECT_SELF;
    if (!GetIsPC(oPC)) return;

    // -------------------------------------------------------------------------
    // PHASE 0: HOTBAR TOGGLE LOGIC (Signal Interceptor)
    // -------------------------------------------------------------------------
    if (GetIsObjectValid(GetItemActivated())) {
        int bIsWalking = !GetLocalInt(oPC, "MUD_WALK_MODE");
        SetLocalInt(oPC, "MUD_WALK_MODE", bIsWalking);

        if (bIsWalking) {
            effect eWalk = TagEffect(ExtraordinaryEffect(EffectMovementSpeedDecrease(50)), "MUD_WALK_EFF");
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eWalk, oPC);
            SendMessageToPC(oPC, "Mode: Conservation (Normal Fatigue Drain)");
        } else {
            effect eEff = GetFirstEffect(oPC);
            while(GetIsEffectValid(eEff)) {
                if(GetEffectTag(eEff) == "MUD_WALK_EFF") RemoveEffect(oPC, eEff);
                eEff = GetNextEffect(oPC);
            }
            SendMessageToPC(oPC, "Mode: Speed (HEAVY Fatigue Drain!)");
        }
        return;
    }

    // -------------------------------------------------------------------------
    // PHASE 1: MCT STAMINA HEARTBEAT (6.0s Logic)
    // -------------------------------------------------------------------------
    if (GetLocalInt(oPC, "RUNNING_MCT_PULSE")) {
        if (!GetLocalInt(oPC, "MUD_WALK_MODE")) {
            int nFat = GetLocalInt(oPC, "MUD_SURVIVAL_FATIGUE");
            if (nFat > 0) {
                SetLocalInt(oPC, "MUD_SURVIVAL_FATIGUE", nFat - 1);
                SetLocalInt(oPC, "IS_DIRTY", 1);
            }
        }
        return;
    }

    // -------------------------------------------------------------------------
    // PHASE 2: MASTER BIOLOGICAL PULSE (1200s Logic)
    // -------------------------------------------------------------------------
    int nRace = GetRacialType(oPC);
    int nSurface = GetSurfaceMaterial(GetLocation(oPC));

    // 1. EXECUTE PHYSICS
    ExecuteWeightPhase(oPC, nRace);

    // 2. EXECUTE TERRAIN MODIFIERS
    int nFatMod  = StringToInt(Get2DAString(TERRAIN_2DA, "FAT_MOD", nSurface));
    int nXPDrain = StringToInt(Get2DAString(TERRAIN_2DA, "XP_DRAIN", nSurface));

    if (nXPDrain > 0) {
        int nNewXP = GetXP(oPC) - nXPDrain;
        SetXP(oPC, (nNewXP < 0 ? 0 : nNewXP));
        SendMessageToPC(oPC, "The harsh terrain saps your energy and experience.");
    }

    // 3. REST ODOMETER TRACKING
    // Increments 'credit' toward Short (2 pulses) or Long (8 pulses) rests.
    if (GetStandardFactionReputation(STANDARD_FACTION_COMMONER, oPC) == 100) {
        int nPulse = GetLocalInt(oPC, "MUD_REST_PULSE_COUNT") + 1;
        SetLocalInt(oPC, "MUD_REST_PULSE_COUNT", nPulse);

        if (nPulse == 2) SendMessageToPC(oPC, "Rest Status: Short rest criteria met.");
        if (nPulse == 8) SendMessageToPC(oPC, "Rest Status: Long rest criteria met.");
    }

    // 4. EXECUTE BIOLOGICAL DRAIN
    int nHD = StringToInt(Get2DAString(REF_2DA, "HNG_DRAIN", nRace));
    int nTD = StringToInt(Get2DAString(REF_2DA, "THR_DRAIN", nRace));
    int nFD = StringToInt(Get2DAString(REF_2DA, "FAT_DRAIN", nRace)) + nFatMod;

    // Environmental Thermal Logic
    if (GetIsDay()) {
        if (GetNearestObjectByTag("MUD_OBJ_TENT", oPC) == OBJECT_INVALID) nTD *= 3;
    } else {
        if (GetNearestObjectByTag("MUD_OBJ_FIRE", oPC) == OBJECT_INVALID) {
             ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectDamage(2, DAMAGE_TYPE_MAGICAL), oPC);
             SendMessageToPC(oPC, "The freezing desert night chills you to the bone...");
        }
    }

    // Update States (Clamp at 0)
    int nCurH = GetLocalInt(oPC, "MUD_SURVIVAL_HUNGER") - nHD;
    int nCurT = GetLocalInt(oPC, "MUD_SURVIVAL_THIRST") - nTD;
    int nCurF = GetLocalInt(oPC, "MUD_SURVIVAL_FATIGUE") - nFD;

    SetLocalInt(oPC, "MUD_SURVIVAL_HUNGER", (nCurH < 0 ? 0 : nCurH));
    SetLocalInt(oPC, "MUD_SURVIVAL_THIRST", (nCurT < 0 ? 0 : nCurT));
    SetLocalInt(oPC, "MUD_SURVIVAL_FATIGUE", (nCurF < 0 ? 0 : nCurF));

    // 5. PLAYER NOTIFICATION
    MUD_CheckSurvivalWarnings(oPC);

    // 6. PERSISTENCE
    SetLocalInt(oPC, "IS_DIRTY", 1);
    ExportToDB(oPC);
}
