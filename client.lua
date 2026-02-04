-- Globale Variablen für die Fahrzeugschadensverwaltung
local pedInSameVehicleLast = false -- Prüft, ob der Spieler im selben Fahrzeug bleibt
local vehicle -- Aktuelles Fahrzeug des Spielers
local lastVehicle -- Letztes Fahrzeug des Spielers
local vehicleClass -- Klasse des aktuellen Fahrzeugs
local fCollisionDamageMult = 0.0 -- Multiplikator für Kollisionsschaden
local fDeformationDamageMult = 0.0 -- Multiplikator für Verformungsschaden
local fEngineDamageMult = 0.0 -- Multiplikator für Motorschaden
local fBrakeForce = 1.0 -- Bremskraft-Multiplikator
local isBrakingForward = false -- Prüft, ob vorwärts gebremst wird
local isBrakingReverse = false -- Prüft, ob rückwärts gebremst wird

-- Variablen für Motorzustand
local healthEngineLast = 1000.0 -- Letzter Motorzustand
local healthEngineCurrent = 1000.0 -- Aktueller Motorzustand
local healthEngineNew = 1000.0 -- Neuer Motorzustand nach Berechnung
local healthEngineDelta = 0.0 -- Änderung des Motorzustands
local healthEngineDeltaScaled = 0.0 -- Skalierte Änderung des Motorzustands

-- Variablen für Karosseriezustand
local healthBodyLast = 1000.0 -- Letzter Karosseriezustand
local healthBodyCurrent = 1000.0 -- Aktueller Karosseriezustand
local healthBodyNew = 1000.0 -- Neuer Karosseriezustand nach Berechnung
local healthBodyDelta = 0.0 -- Änderung des Karosseriezustands
local healthBodyDeltaScaled = 0.0 -- Skalierte Änderung des Karosseriezustands

-- Variablen für Tankzustand
local healthPetrolTankLast = 1000.0 -- Letzter Tankzustand
local healthPetrolTankCurrent = 1000.0 -- Aktueller Tankzustand
local healthPetrolTankNew = 1000.0 -- Neuer Tankzustand nach Berechnung
local healthPetrolTankDelta = 0.0 -- Änderung des Tankzustands
local healthPetrolTankDeltaScaled = 0.0 -- Skalierte Änderung des Tankzustands

local tireBurstLuckyNumber -- Zufällige Zahl für Reifenplatzer-Lotterie

-- Zufallsgenerator initialisieren
math.randomseed(GetGameTimer())

-- Reifenplatzer-Intervall berechnen (1200 Mal pro Minute)
local tireBurstMaxNumber = cfg.randomTireBurstInterval * 1200
if cfg.randomTireBurstInterval ~= 0 then 
    tireBurstLuckyNumber = math.random(tireBurstMaxNumber) 
end

-- Zufällige Nachrichtenauswahl für Reparaturen
local fixMessagePos = math.random(repairCfg.fixMessageCount)
local noFixMessagePos = math.random(repairCfg.noFixMessageCount)

-- Funktion zur Anzeige von Benachrichtigungen
local function notification(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

-- Prüft, ob der Spieler ein Fahrzeug fährt (keine Flugzeuge, Helikopter, Fahrräder oder Züge)
local function isPedDrivingAVehicle()
    local ped = GetPlayerPed(-1)
    vehicle = GetVehiclePedIsIn(ped, false)
    if IsPedInAnyVehicle(ped, false) and GetPedInVehicleSeat(vehicle, -1) == ped then
        local class = GetVehicleClass(vehicle)
        if class ~= 15 and class ~= 16 and class ~= 21 and class ~= 13 then
            return true
        end
    end
    return false
end

-- Skalierungsfunktion für Werte (z.B. Steuerung)
local function fscale(inputValue, originalMin, originalMax, newBegin, newEnd, curve)
    if curve > 10.0 then curve = 10.0 end
    if curve < -10.0 then curve = -10.0 end
    curve = (curve * -0.1)
    curve = 10.0 ^ curve

    if inputValue < originalMin then inputValue = originalMin end
    if inputValue > originalMax then inputValue = originalMax end

    local OriginalRange = originalMax - originalMin
    local NewRange = newEnd > newBegin and (newEnd - newBegin) or (newBegin - newEnd)
    local invFlag = newEnd > newBegin and 0 or 1

    local zeroRefCurVal = inputValue - originalMin
    local normalizedCurVal = zeroRefCurVal / OriginalRange

    if originalMin > originalMax then return 0 end
    return invFlag == 0 and ((normalizedCurVal ^ curve) * NewRange) + newBegin or newBegin - ((normalizedCurVal ^ curve) * NewRange)
end

-- Reifenplatzer-Lotterie
local function tireBurstLottery()
    if math.random(tireBurstMaxNumber) == tireBurstLuckyNumber and GetVehicleTyresCanBurst(vehicle) then
        local numWheels = GetVehicleNumberOfWheels(vehicle)
        local affectedTire
        if numWheels == 2 then
            affectedTire = (math.random(2) - 1) * 4 -- Rad 0 oder 4
        elseif numWheels == 4 then
            affectedTire = math.random(4) - 1
            if affectedTire > 1 then affectedTire = affectedTire + 2 end -- 0, 1, 4, 5
        elseif numWheels == 6 then
            affectedTire = math.random(6) - 1
        else
            affectedTire = 0
        end
        SetVehicleTyreBurst(vehicle, affectedTire, false, 1000.0)
        tireBurstLuckyNumber = math.random(tireBurstMaxNumber)
    end
end

-- Event-Handler für Fahrzeugreparatur
RegisterNetEvent('iens:repair')
AddEventHandler('iens:repair', function()
    if not isPedDrivingAVehicle() then
        notification("~y~Du musst in einem Fahrzeug sein, um es zu reparieren")
        return
    end

    local ped = GetPlayerPed(-1)
    if GetVehicleEngineHealth(vehicle) < cfg.cascadingFailureThreshold + 5 then
        if GetVehicleOilLevel(vehicle) > 0 then
            SetVehicleUndriveable(vehicle, false)
            SetVehicleEngineHealth(vehicle, cfg.cascadingFailureThreshold + 5)
            SetVehiclePetrolTankHealth(vehicle, 750.0)
            healthEngineLast, healthPetrolTankLast = cfg.cascadingFailureThreshold + 5, 750.0
            SetVehicleEngineOn(vehicle, true, false)
            SetVehicleOilLevel(vehicle, (GetVehicleOilLevel(vehicle) / 3) - 0.5)
            notification("~g~" .. repairCfg.fixMessages[fixMessagePos] .. ", das hält nicht lange!")
            fixMessagePos = (fixMessagePos % repairCfg.fixMessageCount) + 1
        else
            notification("~r~Dein Fahrzeug war zu stark beschädigt. Kann nicht repariert werden!")
        end
    else
        notification("~y~" .. repairCfg.noFixMessages[noFixMessagePos])
        noFixMessagePos = (noFixMessagePos % repairCfg.noFixMessageCount) + 1
    end
end)

-- Event-Handler für fehlende Berechtigung
RegisterNetEvent('iens:notAllowed')
AddEventHandler('iens:notAllowed', function()
    notification("~r~Du hast keine Berechtigung, Fahrzeuge zu reparieren")
end)

-- Haupt-Thread für Fahrzeugsteuerung (Drehmoment, Sonntagsfahrer, Fahrzeugumkippen verhindern)
if cfg.torqueMultiplierEnabled or cfg.preventVehicleFlip or cfg.limpMode then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            if pedInSameVehicleLast and (cfg.torqueMultiplierEnabled or cfg.sundayDriver or cfg.limpMode) then
                local factor = 1.0
                if cfg.torqueMultiplierEnabled and healthEngineNew < 900 then
                    factor = (healthEngineNew + 200.0) / 1100
                end
                if cfg.sundayDriver and GetVehicleClass(vehicle) ~= 14 then
                    local accelerator = GetControlValue(2, 71)
                    local brake = GetControlValue(2, 72)
                    local speed = GetEntitySpeedVector(vehicle, true).y
                    local brk = fBrakeForce

                    if speed >= 1.0 then
                        if accelerator > 127 then
                            factor = factor * fscale(accelerator, 127.0, 254.0, 0.1, 1.0, 10.0 - (cfg.sundayDriverAcceleratorCurve * 2.0))
                        end
                        if brake > 127 then
                            isBrakingForward = true
                            brk = fscale(brake, 127.0, 254.0, 0.01, fBrakeForce, 10.0 - (cfg.sundayDriverBrakeCurve * 2.0))
                        end
                    elseif speed <= -1.0 then
                        if brake > 127 then
                            factor = factor * fscale(brake, 127.0, 254.0, 0.1, 1.0, 10.0 - (cfg.sundayDriverAcceleratorCurve * 2.0))
                        end
                        if accelerator > 127 then
                            isBrakingReverse = true
                            brk = fscale(accelerator, 127.0, 254.0, 0.01, fBrakeForce, 10.0 - (cfg.sundayDriverBrakeCurve * 2.0))
                        end
                    elseif GetEntitySpeed(vehicle) < 1 then
                        if isBrakingForward then
                            DisableControlAction(2, 72, true)
                            SetVehicleForwardSpeed(vehicle, speed * 0.98)
                            SetVehicleBrakeLights(vehicle, true)
                        elseif isBrakingReverse then
                            DisableControlAction(2, 71, true)
                            SetVehicleForwardSpeed(vehicle, speed * 0.98)
                            SetVehicleBrakeLights(vehicle, true)
                        end
                        if isBrakingForward and GetDisabledControlNormal(2, 72) == 0 then isBrakingForward = false end
                        if isBrakingReverse and GetDisabledControlNormal(2, 71) == 0 then isBrakingReverse = false end
                    end
                    if brk > fBrakeForce - 0.02 then brk = fBrakeForce end
                    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fBrakeForce', brk)
                end
                if cfg.limpMode and healthEngineNew < cfg.engineSafeGuard + 5 then
                    factor = cfg.limpModeMultiplier
                end
                SetVehicleEngineTorqueMultiplier(vehicle, factor)
            end
            if cfg.preventVehicleFlip then
                local roll = GetEntityRoll(vehicle)
                if (roll > 75.0 or roll < -75.0) and GetEntitySpeed(vehicle) < 2 then
                    DisableControlAction(2, 59, true)
                    DisableControlAction(2, 60, true)
                end
            end
        end
    end)
end

-- Haupt-Thread für Schadensberechnung und Verwaltung
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(50)
        local ped = GetPlayerPed(-1)
        if isPedDrivingAVehicle() then
            vehicleClass = GetVehicleClass(vehicle)

            -- Aktuelle Zustände abrufen
            healthEngineCurrent = GetVehicleEngineHealth(vehicle)
            if healthEngineCurrent == 1000 then healthEngineLast = 1000.0 end
            healthEngineNew = healthEngineCurrent
            healthEngineDelta = healthEngineLast - healthEngineCurrent
            healthEngineDeltaScaled = healthEngineDelta * cfg.damageFactorEngine * cfg.classDamageMultiplier[vehicleClass]

            healthBodyCurrent = GetVehicleBodyHealth(vehicle)
            if healthBodyCurrent == 1000 then healthBodyLast = 1000.0 end
            healthBodyNew = healthBodyCurrent
            healthBodyDelta = healthBodyLast - healthBodyCurrent
            healthBodyDeltaScaled = healthBodyDelta * cfg.damageFactorBody * cfg.classDamageMultiplier[vehicleClass]

            healthPetrolTankCurrent = GetVehiclePetrolTankHealth(vehicle)
            if cfg.compatibilityMode and healthPetrolTankCurrent < 1 then healthPetrolTankLast = healthPetrolTankCurrent end
            if healthPetrolTankCurrent == 1000 then healthPetrolTankLast = 1000.0 end
            healthPetrolTankNew = healthPetrolTankCurrent
            healthPetrolTankDelta = healthPetrolTankLast - healthPetrolTankCurrent
            healthPetrolTankDeltaScaled = healthPetrolTankDelta * cfg.damageFactorPetrolTank * cfg.classDamageMultiplier[vehicleClass]

            -- Fahrzeug fahrbar oder nicht?
            if healthEngineCurrent > cfg.engineSafeGuard + 1 then
                SetVehicleUndriveable(vehicle, false)
            elseif not cfg.limpMode then
                SetVehicleUndriveable(vehicle, true)
            end

            if vehicle ~= lastVehicle then pedInSameVehicleLast = false end

            if pedInSameVehicleLast and (healthEngineCurrent ~= 1000.0 or healthBodyCurrent ~= 1000.0 or healthPetrolTankCurrent ~= 1000.0) then
                local healthEngineCombinedDelta = math.max(healthEngineDeltaScaled, healthBodyDeltaScaled, healthPetrolTankDeltaScaled)
                if healthEngineCombinedDelta > (healthEngineCurrent - cfg.engineSafeGuard) then
                    healthEngineCombinedDelta = healthEngineCombinedDelta * 0.7
                end
                if healthEngineCombinedDelta > healthEngineCurrent then
                    healthEngineCombinedDelta = healthEngineCurrent - (cfg.cascadingFailureThreshold / 5)
                end

                healthEngineNew = healthEngineLast - healthEngineCombinedDelta

                if healthEngineNew > cfg.cascadingFailureThreshold + 5 and healthEngineNew < cfg.degradingFailureThreshold then
                    healthEngineNew = healthEngineNew - (0.038 * cfg.degradingHealthSpeedFactor)
                elseif healthEngineNew < cfg.cascadingFailureThreshold then
                    healthEngineNew = healthEngineNew - (0.1 * cfg.cascadingFailureSpeedFactor)
                end
                if healthEngineNew < cfg.engineSafeGuard then healthEngineNew = cfg.engineSafeGuard end
                if not cfg.compatibilityMode and healthPetrolTankCurrent < 750 then healthPetrolTankNew = 750.0 end
                if healthBodyNew < 0 then healthBodyNew = 0.0 end
            else
                fDeformationDamageMult = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fDeformationDamageMult')
                fBrakeForce = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fBrakeForce')
                local newFDeformationDamageMult = fDeformationDamageMult ^ cfg.deformationExponent
                if cfg.deformationMultiplier ~= -1 then SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fDeformationDamageMult', newFDeformationDamageMult * cfg.deformationMultiplier) end
                if cfg.weaponsDamageMultiplier ~= -1 then SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fWeaponDamageMult', cfg.weaponsDamageMultiplier / cfg.damageFactorBody) end

                fCollisionDamageMult = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fCollisionDamageMult')
                SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fCollisionDamageMult', fCollisionDamageMult ^ cfg.collisionDamageExponent)

                fEngineDamageMult = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fEngineDamageMult')
                SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fEngineDamageMult', fEngineDamageMult ^ cfg.engineDamageExponent)

                if healthBodyCurrent < cfg.cascadingFailureThreshold then healthBodyNew = cfg.cascadingFailureThreshold end
                pedInSameVehicleLast = true
            end

            -- Neue Werte setzen
            if healthEngineNew ~= healthEngineCurrent then SetVehicleEngineHealth(vehicle, healthEngineNew) end
            if healthBodyNew ~= healthBodyCurrent then SetVehicleBodyHealth(vehicle, healthBodyNew) end
            if healthPetrolTankNew ~= healthPetrolTankCurrent then SetVehiclePetrolTankHealth(vehicle, healthPetrolTankNew) end

            healthEngineLast, healthBodyLast, healthPetrolTankLast = healthEngineNew, healthBodyNew, healthPetrolTankNew
            lastVehicle = vehicle
            if cfg.randomTireBurstInterval ~= 0 and GetEntitySpeed(vehicle) > 10 then tireBurstLottery() end
        elseif pedInSameVehicleLast then
            lastVehicle = GetVehiclePedIsIn(ped, true)
            if cfg.deformationMultiplier ~= -1 then SetVehicleHandlingFloat(lastVehicle, 'CHandlingData', 'fDeformationDamageMult', fDeformationDamageMult) end
            SetVehicleHandlingFloat(lastVehicle, 'CHandlingData', 'fBrakeForce', fBrakeForce)
            if cfg.weaponsDamageMultiplier ~= -1 then SetVehicleHandlingFloat(lastVehicle, 'CHandlingData', 'fWeaponDamageMult', cfg.weaponsDamageMultiplier) end
            SetVehicleHandlingFloat(lastVehicle, 'CHandlingData', 'fCollisionDamageMult', fCollisionDamageMult)
            SetVehicleHandlingFloat(lastVehicle, 'CHandlingData', 'fEngineDamageMult', fEngineDamageMult)
            pedInSameVehicleLast = false
        end
    end
end)