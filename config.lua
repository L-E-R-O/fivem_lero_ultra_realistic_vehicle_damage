-- Konfiguration für das Vehicle Damage Script
cfg = {
    repairTimeoutMS = 5000, -- Wartezeit in Millisekunden für Reparaturen

    deformationMultiplier = -1, -- Verformungsmultiplikator (-1 = keine Änderung)
    deformationExponent = 0.4, -- Komprimiert Verformungswerte Richtung 1.0
    collisionDamageExponent = 0.6, -- Komprimiert Kollisionsschaden Richtung 1.0

    damageFactorEngine = 5.0, -- Schadensfaktor für den Motor
    damageFactorBody = 5.0, -- Schadensfaktor für die Karosserie
    damageFactorPetrolTank = 32.0, -- Schadensfaktor für den Tank
    engineDamageExponent = 0.6, -- Komprimiert Motorschaden Richtung 1.0
    weaponsDamageMultiplier = 0.01, -- Waffenschaden-Multiplikator
    degradingHealthSpeedFactor = 10, -- Geschwindigkeit der langsamen Verschlechterung
    cascadingFailureSpeedFactor = 8.0, -- Geschwindigkeit des Kaskadeneffekts

    degradingFailureThreshold = 800.0, -- Schwelle für langsame Verschlechterung
    cascadingFailureThreshold = 360.0, -- Schwelle für Kaskadeneffekt
    engineSafeGuard = 100.0, -- Minimaler Motorzustand vor Totalausfall

    torqueMultiplierEnabled = true, -- Aktiviert Drehmoment-Anpassung bei Schaden
    limpMode = false, -- Wenn true, bleibt der Motor immer minimal funktionsfähig
    limpModeMultiplier = 0.15, -- Drehmoment-Multiplikator im Limp-Modus
    preventVehicleFlip = true, -- Verhindert das Umdrehen eines umgekippten Fahrzeugs
    sundayDriver = false, -- Ermöglicht langsames Fahren mit angepasster Gasannahme
    sundayDriverAcceleratorCurve = 7.5, -- Kurve für Gaspedal im Sunday-Driver-Modus
    sundayDriverBrakeCurve = 5.0, -- Kurve für Bremse im Sunday-Driver-Modus

    displayBlips = false, -- Blips deaktiviert, da Mechaniker-Standorte entfernt wurden
    compatibilityMode = false, -- Verhindert Tankmanipulation durch andere Skripte
    randomTireBurstInterval = 0, -- Minuten bis zum zufälligen Reifenplatzer (0 = deaktiviert)

    -- Schadensmultiplikatoren je Fahrzeugklasse
    classDamageMultiplier = {
        [0] = 1.0, -- Compacts
        [1] = 1.0, -- Sedans
        [2] = 1.0, -- SUVs
        [3] = 1.0, -- Coupes
        [4] = 1.0, -- Muscle
        [5] = 1.0, -- Sports Classics
        [6] = 1.0, -- Sports
        [7] = 1.0, -- Super
        [8] = 0.25, -- Motorcycles
        [9] = 0.7, -- Off-road
        [10] = 0.25, -- Industrial
        [11] = 1.0, -- Utility
        [12] = 1.0, -- Vans
        [13] = 1.0, -- Cycles
        [14] = 0.5, -- Boats
        [15] = 1.0, -- Helicopters
        [16] = 1.0, -- Planes
        [17] = 1.0, -- Service
        [18] = 0.75, -- Emergency
        [19] = 0.75, -- Military
        [20] = 1.0, -- Commercial
        [21] = 1.0 -- Trains
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