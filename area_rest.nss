// =============================================================================
// Script Name: area_rest
// System:      Survival Recovery Engine v1.2 (EE COMPATIBLE)
// Integration: Linked to area_manager (VIP ID) & survival_core (Fatigue)
// Purpose:     Handles Short (240s) and Long (960s) resting logic.
// =============================================================================

#include "area_mud_inc"

// --- PROTOTYPES ---
void ExecuteRestLogic(object oPC, int bIsLongRest);
int GetHasSpellbook(object oPC);

void main() {
    object oPC = OBJECT_SELF;
    int nEvent = GetLastRestEventType();

    // --- PHASE 1: THE SPELLBOOK CHECK ---
    if (nEvent == REST_EVENTTYPE_REST_STARTED) {
        if (!GetHasSpellbook(oPC)) {
            SendMessageToPC(oPC, "WARNING: You are resting without a spellbook. You will not regain spells!");
            FloatingTextStringOnCreature("No Spellbook Found!", oPC, FALSE);
        }
    }

    // --- PHASE 2: RECOVERY CALCULATION ---
    if (nEvent == REST_EVENTTYPE_REST_FINISHED) {
        int nRestTimer = GetLocalInt(oPC, "MUD_REST_PULSE_COUNT");

        // 960s / 120s Pulse = 8 Pulses for a Long Rest
        if (nRestTimer >= 8) {
            ExecuteRestLogic(oPC, TRUE); // Long Rest
            SetLocalInt(oPC, "MUD_REST_PULSE_COUNT", 0); // Reset Odometer
        } else {
            ExecuteRestLogic(oPC, FALSE); // Short Rest
        }
    }
}

// --- PHASE 3: THE RECOVERY ENGINE ---
void ExecuteRestLogic(object oPC, int bIsLongRest) {
    object oArea = GetArea(oPC);
    int nH = GetLocalInt(oPC, "MUD_SURVIVAL_HUNGER");
    int nT = GetLocalInt(oPC, "MUD_SURVIVAL_THIRST");
    int nMaxHP = GetMaxHitPoints(oPC);
    int nCurF = GetLocalInt(oPC, "MUD_SURVIVAL_FATIGUE");

    // EE-COMPATIBLE SHADE DETECTION
    // Shade is defined as being Interior OR Underground.
    int bInShade = GetIsAreaInterior(oArea);
    if (!bInShade) {
        // Check for 'Underground' property (Natural/Underground areas)
        if (!GetIsAreaAboveGround(oArea)) bInShade = TRUE;
    }

    // Environment Sensing
    object oFire = GetNearestObjectByTag("MUD_OBJ_FIRE", oPC);
    object oTent = GetNearestObjectByTag("MUD_OBJ_TENT", oPC);

    int bNearFire = (GetIsObjectValid(oFire) && GetDistanceBetween(oPC, oFire) < 5.0);
    int bNearTent = (GetIsObjectValid(oTent) && GetDistanceBetween(oPC, oTent) < 5.0);

    int bStarving = (nH <= 0 || nT <= 0);

    float fFatiguePct = 0.0;
    float fHPPercent = 0.0;

    // --- CALCULATION: LONG REST ---
    if (bIsLongRest) {
        if (bNearTent || bNearFire) {
            fFatiguePct = 1.0;
            fHPPercent = 0.30;
        } else {
            fFatiguePct = 0.75;
            fHPPercent = 0.10;
        }
    }
    // --- CALCULATION: SHORT REST ---
    else {
        if (GetIsDay()) {
            if (bInShade) {
                fFatiguePct = 0.75;
                fHPPercent = 0.05;
            } else {
                fFatiguePct = 0.375;
            }
        } else { // Night
            if (bNearFire) {
                fFatiguePct = 0.75;
                fHPPercent = 0.05;
            } else {
                fFatiguePct = 0.375;
            }
        }
    }

    // --- STARVATION PENALTY ---
    if (bStarving) {
        fHPPercent = 0.0;
        fFatiguePct = fFatiguePct * 0.25;
        SendMessageToPC(oPC, "Starvation limits your body's ability to recover.");
    }

    // --- APPLY STATS ---
    float fRecov = 100.0 * fFatiguePct;
    int nNewF = nCurF + FloatToInt(fRecov);
    if (nNewF > 100) nNewF = 100;

    SetLocalInt(oPC, "MUD_SURVIVAL_FATIGUE", nNewF);

    if (fHPPercent > 0.0) {
        float fHeal = IntToFloat(nMaxHP) * fHPPercent;
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(FloatToInt(fHeal)), oPC);
    }

    SendMessageToPC(oPC, "Rest complete. Current Fatigue: " + IntToString(nNewF) + "%");
}

int GetHasSpellbook(object oPC) {
    int nClass = GetClassByPosition(1, oPC);
    if (nClass == CLASS_TYPE_WIZARD || nClass == CLASS_TYPE_CLERIC || nClass == CLASS_TYPE_PALADIN) {
        return GetIsObjectValid(GetItemPossessedBy(oPC, "mud_spellbook"));
    }
    return TRUE;
}
