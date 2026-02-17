-- Globale Variablen für die Fahrzeugschadensverwaltung
local pedInSameVehicleLast = false -- Prüft, ob der Spieler im selben Fahrzeug bleibt
local vehicle -- Aktuelles Fahrzeug des Spielers
local lastVehicle -- Letztes Fahrzeug des Spielers
local vehicleClass -- Klasse des aktuellen Fahrzeugs
local fCollisionDamageMult = 0.0 -- Multiplikator für Kollisionsschaden
local fDeformationDamageMult = 0.0 -- Multiplikator für Verformungsschaden
local fEngineDamageMult = 0.0 -- Multiplikator für Motorschaden
local fBrakeForce = 1.0 -- Bremskraft-Multiplikator

-- Variablen für Raucheffekt bei Motorschaden
local engineSmokeData = {} -- [netId] = { ptfx = { ... } }
local engineSmokeSyncState = {} -- [netId] = true wenn synchronisiert
local engineSmokeRemoteState = {} -- [netId] = true wenn Sync aktiv ist

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

local function isSmokeActive(netId)
    return netId and engineSmokeData[netId] ~= nil
end

local function isVehicleDriver(veh, ped)
    if not DoesEntityExist(veh) then return false end
    return GetPedInVehicleSeat(veh, -1) == ped
end

local function syncEngineSmoke(netId, enabled, veh, ped)
    if not cfg.engineSmokeSync or not netId or netId == 0 then return end
    if cfg.engineSmokeSyncDriverOnly and (not veh or not ped or not isVehicleDriver(veh, ped)) then return end
    if enabled then
        if engineSmokeSyncState[netId] then return end
        TriggerServerEvent('ultra_damage:engineSmokeSync', netId, true)
        engineSmokeSyncState[netId] = true
    else
        if not engineSmokeSyncState[netId] then return end
        TriggerServerEvent('ultra_damage:engineSmokeSync', netId, false)
        engineSmokeSyncState[netId] = nil
    end
end

-- Startet den großen Raucheffekt am Motor (nicht-blockierend)
local function startEngineSmoke(veh, netId)
    if not cfg.engineSmokeEnabled then return end
    if not DoesEntityExist(veh) then return end
    netId = netId or NetworkGetNetworkIdFromEntity(veh)
    if not netId or netId == 0 then return end
    if engineSmokeData[netId] then return end
    engineSmokeData[netId] = { ptfx = {} }

    -- In eigenem Thread spawnen, damit der Haupt-Thread nicht blockiert wird
    Citizen.CreateThread(function()
        -- Asset laden mit Timeout (max 3 Sekunden)
        local asset = 'core'
        RequestNamedPtfxAsset(asset)
        local timeout = 0
        while not HasNamedPtfxAssetLoaded(asset) and timeout < 300 do
            Citizen.Wait(10)
            timeout = timeout + 1
        end
        if not HasNamedPtfxAssetLoaded(asset) then
            engineSmokeData[netId] = nil
            return
        end
        -- Prüfen ob Fahrzeug noch existiert
        if not DoesEntityExist(veh) then
            engineSmokeData[netId] = nil
            return
        end
        if not engineSmokeData[netId] then return end

        local data = engineSmokeData[netId]
        local scale = cfg.engineSmokeScale or 5.0
        local offsetY = cfg.engineSmokeOffsetY or 1.5
        local offsetZ = cfg.engineSmokeOffsetZ or 0.3
        local stackCount = cfg.engineSmokeStackCount or 2
        local stackStepZ = cfg.engineSmokeStackStepZ or 0.6
        local stackScaleFalloff = cfg.engineSmokeStackScaleFalloff or 0.85

        for i = 0, stackCount - 1 do
            local z = offsetZ + (i * stackStepZ)
            local s = scale * (stackScaleFalloff ^ i)
            UseParticleFxAssetNextCall(asset)
            local ptfx = StartParticleFxLoopedOnEntity('ent_ray_prologue_smoke', veh, 0.0, offsetY, z, 0.0, 0.0, 0.0, s, false, false, false)
            if not ptfx or ptfx == 0 then
                -- Fallback-Effekt
                UseParticleFxAssetNextCall(asset)
                ptfx = StartParticleFxLoopedOnEntity('exp_grd_grenade_smoke', veh, 0.0, offsetY, z, 0.0, 0.0, 0.0, s * 0.8, false, false, false)
            end
            if ptfx and ptfx ~= 0 then
                SetParticleFxLoopedColour(ptfx, 0.05, 0.05, 0.05, false)
                SetParticleFxLoopedAlpha(ptfx, 1.0)
                table.insert(data.ptfx, ptfx)
            end
        end

        if #data.ptfx == 0 then
            engineSmokeData[netId] = nil
        end
    end)
end

-- Stoppt den Raucheffekt
local function stopEngineSmokeForNetId(netId)
    if not netId or netId == 0 then return end
    local data = engineSmokeData[netId]
    if not data then return end
    if data.ptfx and #data.ptfx > 0 then
        for _, ptfx in ipairs(data.ptfx) do
            StopParticleFxLooped(ptfx, false)
        end
    end
    engineSmokeData[netId] = nil
end

RegisterNetEvent('ultra_damage:engineSmokeSync')
AddEventHandler('ultra_damage:engineSmokeSync', function(netId, enabled)
    if not cfg.engineSmokeEnabled or not netId or netId == 0 then return end
    if enabled then
        engineSmokeRemoteState[netId] = true
        local veh = NetToVeh(netId)
        if DoesEntityExist(veh) then
            local range = cfg.engineSmokeSyncRange or 200.0
            local ped = PlayerPedId()
            local pedCoords = GetEntityCoords(ped)
            local vehCoords = GetEntityCoords(veh)
            if #(pedCoords - vehCoords) > range then return end
            startEngineSmoke(veh, netId)
        end
    else
        engineSmokeRemoteState[netId] = nil
        stopEngineSmokeForNetId(netId)
        engineSmokeSyncState[netId] = nil
    end
end)

-- Abstand-Refresh fuer synchronisierten Rauch
Citizen.CreateThread(function()
    while true do
        local refreshMs = cfg.engineSmokeSyncRefreshMS or 1000
        Citizen.Wait(refreshMs)
        if not cfg.engineSmokeEnabled or not cfg.engineSmokeSync then
            goto continue
        end
        local range = cfg.engineSmokeSyncRange or 200.0
        local ped = PlayerPedId()
        local pedCoords = GetEntityCoords(ped)
        for netId, _ in pairs(engineSmokeRemoteState) do
            local veh = NetToVeh(netId)
            if not DoesEntityExist(veh) then
                engineSmokeRemoteState[netId] = nil
                stopEngineSmokeForNetId(netId)
            else
                local vehCoords = GetEntityCoords(veh)
                local inRange = #(pedCoords - vehCoords) <= range
                if inRange then
                    if not isSmokeActive(netId) then
                        startEngineSmoke(veh, netId)
                    end
                elseif isSmokeActive(netId) then
                    stopEngineSmokeForNetId(netId)
                end
            end
        end
        ::continue::
    end
end)

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
            local netId = NetworkGetNetworkIdFromEntity(vehicle)
            stopEngineSmokeForNetId(netId)
            syncEngineSmoke(netId, false, vehicle, ped)
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

-- Haupt-Thread für Fahrzeugsteuerung (Drehmoment, Sonntagsfahrer, Fahrzeugumkippen verhindern)
if cfg.torqueMultiplierEnabled or cfg.limpMode then
    Citizen.CreateThread(function()
        while true do
            if pedInSameVehicleLast then
                local factor = 1.0
                if cfg.torqueMultiplierEnabled and healthEngineNew < 900 then
                    factor = (healthEngineNew + 200.0) / 1100
                end
                if cfg.limpMode and healthEngineNew < cfg.engineSafeGuard + 5 then
                    factor = cfg.limpModeMultiplier
                end
                SetVehicleEngineTorqueMultiplier(vehicle, factor)
                Citizen.Wait(0)
            else
                Citizen.Wait(500) -- Längere Wartezeit wenn nicht im Fahrzeug
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
            healthEngineDeltaScaled = healthEngineDelta * cfg.damageFactorEngine * (cfg.classDamageMultiplier[vehicleClass] or 1.0)

            healthBodyCurrent = GetVehicleBodyHealth(vehicle)
            if healthBodyCurrent == 1000 then healthBodyLast = 1000.0 end
            healthBodyNew = healthBodyCurrent
            healthBodyDelta = healthBodyLast - healthBodyCurrent
            healthBodyDeltaScaled = healthBodyDelta * cfg.damageFactorBody * (cfg.classDamageMultiplier[vehicleClass] or 1.0)

            healthPetrolTankCurrent = GetVehiclePetrolTankHealth(vehicle)
            if cfg.compatibilityMode and healthPetrolTankCurrent < 1 then healthPetrolTankLast = healthPetrolTankCurrent end
            if healthPetrolTankCurrent == 1000 then healthPetrolTankLast = 1000.0 end
            healthPetrolTankNew = healthPetrolTankCurrent
            healthPetrolTankDelta = healthPetrolTankLast - healthPetrolTankCurrent
            healthPetrolTankDeltaScaled = healthPetrolTankDelta * cfg.damageFactorPetrolTank * (cfg.classDamageMultiplier[vehicleClass] or 1.0)

            local netId = NetworkGetNetworkIdFromEntity(vehicle)

            -- Fahrzeug fahrbar oder nicht?
            if healthEngineCurrent > cfg.engineSafeGuard + 1 then
                SetVehicleUndriveable(vehicle, false)
                if isSmokeActive(netId) then
                    stopEngineSmokeForNetId(netId)
                    syncEngineSmoke(netId, false, vehicle, ped)
                end
            elseif not cfg.limpMode then
                SetVehicleUndriveable(vehicle, true)
                startEngineSmoke(vehicle, netId)
                syncEngineSmoke(netId, true, vehicle, ped)
            else
                -- Limp-Mode aktiv, Motor kaputt → trotzdem Rauch
                startEngineSmoke(vehicle, netId)
                syncEngineSmoke(netId, true, vehicle, ped)
            end

            if vehicle ~= lastVehicle then pedInSameVehicleLast = false end

            if not pedInSameVehicleLast then
                -- Erstes Einsteigen: Handling-Werte einmalig lesen und anpassen
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
            elseif healthEngineDelta > cfg.minDamageThreshold or healthBodyDelta > cfg.minDamageThreshold or healthPetrolTankDelta > cfg.minDamageThreshold then
                -- Schaden nur bei tatsächlicher Kollision/Interaktion verarbeiten
                local healthEngineCombinedDelta = math.max(healthEngineDeltaScaled, healthBodyDeltaScaled, healthPetrolTankDeltaScaled)
                if healthEngineCombinedDelta > (healthEngineCurrent - cfg.engineSafeGuard) then
                    healthEngineCombinedDelta = healthEngineCombinedDelta * 0.7
                end
                if healthEngineCombinedDelta > healthEngineCurrent then
                    healthEngineCombinedDelta = healthEngineCurrent - (cfg.cascadingFailureThreshold / 5)
                end

                healthEngineNew = healthEngineLast - healthEngineCombinedDelta

                if healthEngineNew < cfg.engineSafeGuard then healthEngineNew = cfg.engineSafeGuard end
                if not cfg.compatibilityMode and healthPetrolTankCurrent < 750 then healthPetrolTankNew = 750.0 end
                if healthBodyNew < 0 then healthBodyNew = 0.0 end
            end

            -- Neue Werte setzen
            if healthEngineNew ~= healthEngineCurrent then SetVehicleEngineHealth(vehicle, healthEngineNew) end
            if healthBodyNew ~= healthBodyCurrent then SetVehicleBodyHealth(vehicle, healthBodyNew) end
            if healthPetrolTankNew ~= healthPetrolTankCurrent then SetVehiclePetrolTankHealth(vehicle, healthPetrolTankNew) end

            healthEngineLast, healthBodyLast, healthPetrolTankLast = healthEngineNew, healthBodyNew, healthPetrolTankNew
            lastVehicle = vehicle
        elseif pedInSameVehicleLast then
            lastVehicle = GetVehiclePedIsIn(ped, true)
            if cfg.deformationMultiplier ~= -1 then SetVehicleHandlingFloat(lastVehicle, 'CHandlingData', 'fDeformationDamageMult', fDeformationDamageMult) end
            SetVehicleHandlingFloat(lastVehicle, 'CHandlingData', 'fBrakeForce', fBrakeForce)
            if cfg.weaponsDamageMultiplier ~= -1 then SetVehicleHandlingFloat(lastVehicle, 'CHandlingData', 'fWeaponDamageMult', cfg.weaponsDamageMultiplier) end
            SetVehicleHandlingFloat(lastVehicle, 'CHandlingData', 'fCollisionDamageMult', fCollisionDamageMult)
            SetVehicleHandlingFloat(lastVehicle, 'CHandlingData', 'fEngineDamageMult', fEngineDamageMult)
            -- Rauch bleibt am Fahrzeug! Wird nur durch Reparatur gestoppt
            pedInSameVehicleLast = false
        end
    end
end)