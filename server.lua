-- Befehl zum Auslösen der Reparatur auf dem Client
RegisterCommand("repair", function(source, args)
    CancelEvent() -- Verhindert Standardverhalten
    TriggerClientEvent('iens:repair', source) -- Löst das Reparatur-Event auf dem Client aus
end, false)