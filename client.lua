local QBCore = exports['qb-core']:GetCoreObject()

-- === CONFIG ===
local Recruiters = {
    {
        job = "police",
        label = "Police",
        model = `s_m_y_cop_01`,
        coords = vector3(441.3, -978.85, 30.69),
        heading = 150.0,
        zone = "npc_police_signon",
        targetDistance = 4.0,
        useExactZ = true
    },
    {
        job = "ambulance",
        label = "EMS",
        model = `s_m_m_paramedic_01`,
        coords = vector3(311.61, -594.11, 43.28),
        heading = 340.22,
        zone = "npc_ems_signon",
        targetDistance = 4.0,
        useExactZ = true
    },
    {
        job = "taxi",
        label = "Taxi Driver",
        model = `s_m_m_gentransport`,
        coords = vector3(898.68, -175.97, 73.83),
        heading = 260.68,
        zone = "npc_taxi_signon",
        targetDistance = 4.0,
        useExactZ = true
    }
}

-- === STATE ===
local Peds = {} -- [zone] = ped

-- === HELPERS ===
local function addTargets(rec, ped)
    exports['qb-target']:AddTargetEntity(ped, {
        options = {
            {
                label = ("Become %s"):format(rec.label),
                icon = "fa-solid fa-user-check",
                canInteract = function()
                    local pd = QBCore.Functions.GetPlayerData()
                    return pd and pd.job and pd.job.name ~= rec.job
                end,
                action = function()
                    TriggerServerEvent("npc_recruiter:setJob", rec.job)
                end
            },
            {
                label = ("Stop Being %s"):format(rec.label),
                icon = "fa-solid fa-user-xmark",
                canInteract = function()
                    local pd = QBCore.Functions.GetPlayerData()
                    return pd and pd.job and pd.job.name == rec.job
                end,
                action = function()
                    TriggerServerEvent("npc_recruiter:setJob", "unemployed")
                end
            }
        },
        distance = rec.targetDistance
    })
end

local function spawnOne(rec)
    if Peds[rec.zone] and DoesEntityExist(Peds[rec.zone]) then
        DeleteEntity(Peds[rec.zone])
        Peds[rec.zone] = nil
    end

    RequestModel(rec.model)
    while not HasModelLoaded(rec.model) do Wait(0) end

    local x, y, z = rec.coords.x, rec.coords.y, rec.coords.z
    local ped = CreatePed(4, rec.model, x, y, z, rec.heading, false, true)

    SetEntityAsMissionEntity(ped, true, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)

    -- exact placement to avoid float/sink on desks or stairs
    SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
    SetEntityHeading(ped, rec.heading)
    FreezeEntityPosition(ped, true)

    addTargets(rec, ped)
    SetModelAsNoLongerNeeded(rec.model)
    Peds[rec.zone] = ped
end

local function spawnAll()
    for _, rec in ipairs(Recruiters) do
        spawnOne(rec)
    end
end

-- === BOOT ===
CreateThread(function()
    spawnAll()
    while true do
        for _, rec in ipairs(Recruiters) do
            if not (Peds[rec.zone] and DoesEntityExist(Peds[rec.zone])) then
                spawnOne(rec)
            end
        end
        Wait(5000)
    end
end)

AddEventHandler('onResourceStart', function(res)
    if res == GetCurrentResourceName() then
        Wait(250)
        spawnAll()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    for _, rec in ipairs(Recruiters) do
        if Peds[rec.zone] then addTargets(rec, Peds[rec.zone]) end
    end
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function()
    for _, rec in ipairs(Recruiters) do
        if Peds[rec.zone] then addTargets(rec, Peds[rec.zone]) end
    end
end)

RegisterCommand('recruiters', function() spawnAll() end, false)
