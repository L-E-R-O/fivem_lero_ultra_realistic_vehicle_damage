-- Befehl zum Auslösen der Reparatur auf dem Client
RegisterCommand("repair", function(source, args)
    CancelEvent() -- Verhindert Standardverhalten
    TriggerClientEvent('iens:repair', source) -- Löst das Reparatur-Event auf dem Client aus
end, false)

-- Synchronisiert Motorschaden-Rauch fuer alle Clients
RegisterNetEvent('ultra_damage:engineSmokeSync')
AddEventHandler('ultra_damage:engineSmokeSync', function(netId, enabled)
    if not cfg.engineSmokeSync then return end
    if cfg.engineSmokeSyncDriverOnly then
        local ped = GetPlayerPed(source)
        local veh = NetworkGetEntityFromNetworkId(netId)
        if not DoesEntityExist(veh) then return end
        if GetPedInVehicleSeat(veh, -1) ~= ped then return end
    end
    TriggerClientEvent('ultra_damage:engineSmokeSync', -1, netId, enabled)
end)