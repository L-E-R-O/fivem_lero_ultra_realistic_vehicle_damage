-- Konfiguration für das Vehicle Damage Script
cfg = {
    deformationMultiplier = -1, -- Verformungsmultiplikator (-1 = keine Änderung)
    deformationExponent = 0.4, -- Komprimiert Verformungswerte Richtung 1.0
    collisionDamageExponent = 0.6, -- Komprimiert Kollisionsschaden Richtung 1.0

    damageFactorEngine = 5.0, -- Schadensfaktor für den Motor
    damageFactorBody = 5.0, -- Schadensfaktor für die Karosserie
    damageFactorPetrolTank = 32.0, -- Schadensfaktor für den Tank
    engineDamageExponent = 0.6, -- Komprimiert Motorschaden Richtung 1.0
    weaponsDamageMultiplier = 0.01, -- Waffenschaden-Multiplikator
    minDamageThreshold = 5.0, -- Minimaler Roh-Schadenswert um als Kollision erkannt zu werden

    cascadingFailureThreshold = 360.0, -- Schwelle für Kaskadeneffekt
    engineSafeGuard = 100.0, -- Minimaler Motorzustand vor Totalausfall

    torqueMultiplierEnabled = true, -- Aktiviert Drehmoment-Anpassung bei Schaden
    limpMode = false, -- Wenn true, bleibt der Motor immer minimal funktionsfähig
    limpModeMultiplier = 0.15, -- Drehmoment-Multiplikator im Limp-Modus

    compatibilityMode = false, -- Verhindert Tankmanipulation durch andere Skripte

    engineSmokeEnabled = true, -- Aktiviert Raucheffekt bei Motorschaden (true/false)
    engineSmokeScale = 1.0, -- Größe des Raucheffekts (1.0 = klein, 3.0 = mittel, 5.0 = groß, 10.0 = extrem)

    -- Schadensmultiplikatoren je Fahrzeugklasse
    classDamageMultiplier = {
        [0] = 1.0, -- Compacts
        [1] = 0.9, -- Sedans
        [2] = 0.8, -- SUVs
        [3] = 0.9, -- Coupes
        [4] = 0.9, -- Muscle
        [5] = 0.9, -- Sports Classics
        [6] = 0.9, -- Sports
        [7] = 0.9, -- Super
        [8] = 0.2, -- Motorcycles
        [9] = 0.8, -- Off-road
        [10] = 0.3, -- Industrial
        [11] = 0.3, -- Utility
        [12] = 0.9, -- Vans
        [13] = 1.0, -- Cycles
        [14] = 0.5, -- Boats
        [15] = 0.8, -- Helicopters
        [16] = 0.8, -- Planes
        [17] = 0.7, -- Service
        [18] = 0.8, -- Emergency
        [19] = 0.3, -- Military
        [20] = 0.4, -- Commercial
        [21] = 0.3 -- Trains
    }
}

-- Konfiguration des Reparatursystems
repairCfg = {
    fixMessages = {
        "Du hast den Ölstopfen wieder reingedreht",
        "Du hast das Ölleck mit Kaugummi gestoppt",
        "Du hast das Ölleitungsrohr mit Klebeband repariert",
        "Du hast die Ölwannenschraube angezogen und das Tropfen gestoppt",
        "Du hast den Motor getreten und er sprang wie durch Magie wieder an",
        "Du hast Rost vom Zündrohr entfernt",
        "Du hast dein Fahrzeug angeschrien und es hatte irgendwie Wirkung"
    },
    fixMessageCount = 7,

    noFixMessages = {
        "Du hast den Ölstopfen überprüft. Er ist noch da",
        "Du hast den Motor angeschaut, er schien in Ordnung",
        "Du hast sichergestellt, dass das Klebeband den Motor noch zusammenhält",
        "Du hast das Radio lauter gedreht. Es übertönt die komischen Motorgeräusche",
        "Du hast Rostschutzmittel ins Zündrohr gegeben. Es hat nichts gebracht",
        "Reparier nichts, was nicht kaputt ist, sagen sie. Du hast nicht gehört. Es wurde zumindest nicht schlimmer"
    },
    noFixMessageCount = 6
}