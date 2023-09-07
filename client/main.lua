-- Initialize flags and timers
local IsDead = false
local IsEMSNotified = false  -- Flag to prevent duplicate notifications
local IsEMS = false
local secondsRemaining = Config.respawnTime
local isBleedingOut = false
local bleedOutTime = 0
local cprInProgress = false

RegisterNetEvent("ems:login")
AddEventHandler("ems:login", function(isEms)
    IsEMS = isEms
end)

-- Main Loop --
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local health = GetEntityHealth(PlayerPedId())
        if health < 2 then
            IsDead = true
            if Config.AutoNotify then
                if not IsEMSNotified then
                -- Notify medical departments when there's a downed player
                    if IsEMS == true then
                        local playerCoords = GetEntityCoords(PlayerPedId())
                        local message = "A player is down and needs medical attention. Respond to the location:"
                        local blip = NotifyMedicDept(message, playerCoords) -- Pass playerCoords to the function
                        IsEMSNotified = true
                        print("Notifying medic department.")
                        break
                    end
                end
            end
        else
            IsDead = false
            IsEMSNotified = false
        end
        if IsDead then
            exports.spawnmanager:setAutoSpawn(false)
            ShowRespawnText()
				if secondsRemaining == 0 then
                -- Allow the player to respawn when the timer is zero
                if IsControlJustReleased(1, 38) then
                    RespawnPlayer()
                end
            end
        end
    end
end)

-- Timer Loop --
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        
        if secondsRemaining > 0 and IsDead then
            secondsRemaining = secondsRemaining - 1
        end
        
        if isBleedingOut and GetGameTimer() > bleedOutTime then
            RespawnPlayer() -- Respawn the player after bleed out time
        end
    end
end)

-- Function to draw custom text on the screen
function DrawCustomText(text, x, y, scale, font)
    SetTextFont(font)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextOutline()
    SetTextJustification(1)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

-- Function to show respawn text
function ShowRespawnText()
    local textToShow
    if secondsRemaining > 0 then
        textToShow = IsDead and Config.respawnTextWithTimer:format(secondsRemaining) or ""
    else
        textToShow = IsDead and Config.respawnText or ""
    end
    DrawCustomText(textToShow, 0.500, 0.900, 0.50, 4) -- Updated position
end

-- Function to respawn the player
function RespawnPlayer()
    local respawnLocation = GetClosestRespawnLocation(GetEntityCoords(PlayerPedId()))
    local playerPed = PlayerPedId()

    if respawnLocation then
        IsDead = false
        DoScreenFadeOut(1500)
        Citizen.Wait(1500) 
        NetworkResurrectLocalPlayer(respawnLocation.x, respawnLocation.y, respawnLocation.z, respawnLocation.h, true, true, false)
        SetEntityCoordsNoOffset(playerPed, respawnLocation.x, respawnLocation.y, respawnLocation.z, true, true, true)
        SetEntityHeading(playerPed, respawnLocation.h)
        SetPlayerInvincible(playerPed, false)
        ClearPedBloodDamage(playerPed)
        DoScreenFadeIn(1500)
        secondsRemaining = Config.respawnTime
    else
        print("No valid respawn location found.")
    end
end

-- Function to get the closest respawn location based on player coordinates
function GetClosestRespawnLocation(playerCoords)
    local closestLocation = nil
    local closestDistance = math.huge

    for _, respawnLocation in pairs(Config.respawnLocations) do
        local distance = #(vector3(respawnLocation.x, respawnLocation.y, respawnLocation.z) - playerCoords)
        if distance < closestDistance then
            closestDistance = distance
            closestLocation = respawnLocation
        end
    end

    return closestLocation
end


-- Function to respawn the player at downed position
function RespawnPlayerAtDownedPosition()
    local playerPos = GetEntityCoords(PlayerPedId())
    local respawnHeading = Config.respawnHeading
    local playerPed = PlayerPedId() -- Use PlayerPedId() directly
    IsDead = false
    DoScreenFadeOut(1500)
    Citizen.Wait(1500) 
    NetworkResurrectLocalPlayer(playerPos.x, playerPos.y, playerPos.z, respawnHeading, true, true, false)
    SetEntityHeading(playerPed, respawnHeading)
    SetPlayerInvincible(playerPed, false)
    ClearPedBloodDamage(playerPed)
    DoScreenFadeIn(1500)
    secondsRemaining = Config.respawnTime
end

-- Event to notify EMS about a downed player
function NotifyMedicDept(message, coordsToBlip)
    if IsEMS == true then
        local location = GetStreetNameFromHashKey(GetStreetNameAtCoord(coordsToBlip.x, coordsToBlip.y, coordsToBlip.z))
        local messageWithLocation = message .. " Location: " .. location
        if GetResourceState("ModernHUD") == "started" then
            exports["ModernHUD"]:AndyyyNotify({
                title = "<p style='color: #ff0000;'>EMS Call:</p>",
                message = "<p style='color: #ffffff;'>Player down and needs medical attention at:</p><br><p style='color: #ff0000;'>" .. location .. "</p>",
                icon = "fa-solid fa-ambulance",
                colorHex = "#ff0000",
                timeout = 8000
            })
        else
            TriggerEvent('chatMessage', '^3EMS Call', { 255, 255, 255 }, 'Player down and needs medical attention at: ' .. location)
        end
        -- Play the existing "Beep_Red" sound
        function PlayBeepRedSound()
            local soundName = "Beep_Red"
            local soundSet = "DLC_HEIST_HACKING_SNAKE_SOUNDS" -- Soundset containing the "Beep_Red" sound
            local beepVolume = 0.5
            local beepPitch = 1.0

            PlaySoundFrontend(-1, soundName, soundSet, false)
        end

        -- Call the function to play the sound
        PlayBeepRedSound()

        -- Add a blip on the map
        local blip = AddBlipForCoord(coordsToBlip.x, coordsToBlip.y, coordsToBlip.z)
        SetBlipSprite(blip, 153) -- EMS blip sprite
        SetBlipDisplay(blip, 2)
        SetBlipColour(blip, 3) -- Red color
        SetBlipFlashes(blip, true)
        SetBlipFlashInterval(blip, 500)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("EMS Call")
        EndTextCommandSetBlipName(blip)
        local blipDuration = 30000 -- Set the blip duration in milliseconds (30 seconds)

        -- Create a timer to remove the blip after the specified duration
        Citizen.CreateThread(function()
            Citizen.Wait(blipDuration)
            RemoveBlip(blip) -- Remove the blip
        end)
        
        return blip -- Return the blip ID for later use
    end
end


-- Event to notify EMS about a downed player
RegisterNetEvent("JGN_Death:NotifyEMS")
AddEventHandler("JGN_Death:NotifyEMS", function(playerCoords)
    local location = GetStreetNameFromHashKey(GetStreetNameAtCoord(playerCoords.x, playerCoords.y, playerCoords.z))
    
    -- Create a blip on the map
    local blip = AddBlipForCoord(playerCoords.x, playerCoords.y, playerCoords.z)
    SetBlipSprite(blip, 153) -- EMS blip sprite
    SetBlipDisplay(blip, 2)
    SetBlipColour(blip, 3) -- Red color
    SetBlipFlashes(blip, true)
    SetBlipFlashInterval(blip, 500)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("EMS Call")
    EndTextCommandSetBlipName(blip)
    local blipDuration = 30000 -- Set the blip duration in milliseconds (30 seconds)

    -- Create a timer to remove the blip after the specified duration
    Citizen.CreateThread(function()
        Citizen.Wait(blipDuration)
        RemoveBlip(blip) -- Remove the blip
    end)


    if GetResourceState("ModernHUD") == "started" then
        exports["ModernHUD"]:AndyyyNotify({
            title = "<p style='color: #ff0000;'>EMS Call:</p>",
            message = "<p style='color: #ffffff;'>Player down and needs medical attention at:</p><br><p style='color: #ff0000;'>" .. location .. "</p>",
            icon = "fa-solid fa-ambulance",
            colorHex = "#ff0000",
            timeout = 30000 -- Set the timeout to 30000 milliseconds (30 seconds)
        })
    else
        TriggerEvent('chatMessage', '^3EMS Call', { 255, 255, 255 }, 'Player down and needs medical attention at: ' .. location)
    end

    -- Create a timer to remove the blip after 30 seconds
    Citizen.CreateThread(function()
        Citizen.Wait(30000) -- Wait for 30 seconds
        RemoveBlip(blip) -- Remove the blip
    end)
end)


-- Code to revive player at position
RegisterNetEvent("JGN_Death:AdminRevivePlayerAtPosition")
AddEventHandler("JGN_Death:AdminRevivePlayerAtPosition", function()
    local playerPed = PlayerPedId()
    if IsEntityDead(playerPed) then
        RespawnPlayerAtDownedPosition() -- Call the new function
    end
end)

-- Code to start CPR Animation
RegisterNetEvent("startCPRAnimation")
AddEventHandler("startCPRAnimation", function()
    if cprInProgress then
        return
    end
	
    local playerPed = PlayerPedId()
    cprInProgress = true
    TaskStartScenarioInPlace(playerPed, "CODE_HUMAN_MEDIC_TEND_TO_DEAD", 0, true)
    Citizen.Wait(10000) -- Adjust the time as needed for the animation to play
    ClearPedTasks(playerPed)
    cprInProgress = false
end)



RegisterNetEvent("SendMedicalNotifications")
AddEventHandler("SendMedicalNotifications", function(message)
    if GetResourceState("ModernHUD") == "started" then
        exports["ModernHUD"]:AndyyyNotify({
            title = "<p style='color: #34eb52;'>EMS Call:</p>",
            message = "<p style='color: #ffffff;'>" .. message .. "</p>",
            icon = "fa-solid fa-ambulance",
            colorHex = "#34eb52", -- Change to medical green color
            timeout = 8000
        })
    else
        TriggerEvent('chatMessage', '^3[EMS Dispatch]', { 255, 255, 255 }, message)
    end
end)

Citizen.CreateThread(function()
    Citizen.Wait(30000) -- Wait for 30 seconds
end)