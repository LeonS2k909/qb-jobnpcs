local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent("npc_recruiter:setJob", function(jobName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        Player.Functions.SetJob(jobName, 0)
        TriggerClientEvent('QBCore:Notify', src, "Your job is now: " .. jobName, "success")
    end
end)
