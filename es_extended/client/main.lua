Core = {}
Core.Input = {}
Core.Events = {}

ESX.PlayerData = {}

-- NPC systems removed: disable ambient population/cops once on startup.
CreateThread(function()
    SetPedPopulationBudget(0)
    SetVehiclePopulationBudget(0)
    SetCreateRandomCops(false)
    SetCreateRandomCopsNotOnScenarios(false)
    SetCreateRandomCopsOnScenarios(false)
end)
ESX.PlayerLoaded = false
ESX.playerId = PlayerId()
ESX.serverId = GetPlayerServerId(ESX.playerId)

ESX.UI = {}
ESX.UI.Menu = {}
ESX.UI.Menu.RegisteredTypes = {}
ESX.UI.Menu.Opened = {}

ESX.Game = {}
ESX.Game.Utils = {}

local joinFreezeThreadActive = false
local joinFreezeActive = false
local joinFreezeMovementControls = { 30, 31, 32, 33, 34, 35 }

local function setJoinFreezeState(active)
    local ped = PlayerPedId()

    if ped <= 0 or not DoesEntityExist(ped) then
        return
    end

    SetEntityVelocity(ped, 0.0, 0.0, 0.0)
    FreezeEntityPosition(ped, active)
end

function Core.StopJoinFreeze()
    if not joinFreezeActive then
        return
    end

    joinFreezeActive = false
    setJoinFreezeState(false)
end

function Core.StartJoinFreeze()
    joinFreezeActive = true
    setJoinFreezeState(true)

    if joinFreezeThreadActive then
        return
    end

    joinFreezeThreadActive = true

    CreateThread(function()
        while joinFreezeActive do
            local shouldUnfreeze = false

            for i = 1, #joinFreezeMovementControls do
                if IsControlPressed(0, joinFreezeMovementControls[i]) then
                    shouldUnfreeze = true
                    break
                end
            end

            if shouldUnfreeze then
                Core.StopJoinFreeze()
                break
            end

            setJoinFreezeState(true)
            Wait(0)
        end

        joinFreezeThreadActive = false
    end)
end

local function waitForPlayerActivation()
    if not NetworkIsPlayerActive(ESX.playerId) then
        return SetTimeout(100, waitForPlayerActivation)
    end

    ESX.DisableSpawnManager()
    DoScreenFadeOut(0)
    Wait(250)
    TriggerServerEvent("esx:onPlayerJoined")
end

CreateThread(waitForPlayerActivation)
