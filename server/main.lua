-- Admin revive command
RegisterCommand("adrev", function(source, args, rawCommand)
    local player = source -- Store the source (player) ID
    local hasPermission = false

    -- Check if the player is an admin with aceperm, reviveadmin
    if IsPlayerAceAllowed(player, 'reviveadmin') then 
        hasPermission = true
    else 
        hasPermission = false
    end
    if hasPermission == false then
        TriggerClientEvent("chatMessage", player, "^1Error: ^7You don't have permission to use this command.") -- Permission check failed
        return
    end

    local targetPlayerId = tonumber(args[1])

    if targetPlayerId then
        TriggerClientEvent("JGN:AdminRevivePlayerAtPosition", -1, targetPlayerId) -- Pass targetPlayerId to the client event
        TriggerClientEvent("chatMessage", player, "^2Admin: ^7You have revived player " .. targetPlayerId)
    else
        TriggerClientEvent("chatMessage", player, "^1Error: ^7Invalid player ID.")
    end
end, false)

-- CPR Command
RegisterCommand("cpr", function(source, args, rawCommand)
    local player = source -- Store the source (player) ID
    local hasPermission = false

    if IsPlayerAceAllowed(player, 'reviveems') then
        hasPermission = true
    else
        hasPermission = false
    end

    if hasPermission == false then
        TriggerClientEvent("chatMessage", player, "^1Error: ^7You don't have permission to use this command.")
        return
    end

    local targetPlayerId = tonumber(args[1])
    if targetPlayerId then
        TriggerClientEvent("startCPRAnimation", source) -- Trigger the client event to start CPR animation for everyone

        Citizen.Wait(5000) -- Wait for the CPR animation to finish (adjust timing as needed)

        local playerName = GetPlayerName(targetPlayerId) -- Get the target player's name
        local cprMessage = ("You have initiated CPR on player %s."):format(playerName)
        TriggerClientEvent("SendMedicalNotifications", player, cprMessage)
        
        TriggerClientEvent("JGN_Death:AdminRevivePlayerAtPosition", -1, targetPlayerId, source) -- Pass targetPlayerId and source to the client event

        local reviveMessage = ("You have revived player %s."):format(playerName)
        TriggerClientEvent("SendMedicalNotifications", player, reviveMessage)
    end
end, false)

-- This event is triggered from the client to revive a player at their downed position
RegisterServerEvent("JGN_Death:AdminRevivePlayerAtPosition")
AddEventHandler("JGN_Death:AdminRevivePlayerAtPosition", function(targetPlayerId)
    local targetPlayer = tonumber(targetPlayerId)

    if targetPlayer then
        local targetPlayerPed = GetPlayerPed(targetPlayer)

        if IsEntityDead(targetPlayerPed) then -- Check if the player is dead
            RespawnPlayerAtDownedPosition() -- Call the new function to revive at downed position
            TriggerClientEvent("chatMessage", -1, "^2Server: ^7Player " .. targetPlayer .. " revived by an admin.")
        else
            TriggerClientEvent("chatMessage", -1, "^1Error: ^7Player is not dead.")
        end
    end
end)

RegisterCommand("emslogin", function(source, args, rawCommand)
    local player = source

    if IsPlayerAceAllowed(player, "reviveems") then
        -- Set session variable to mark player as EMS
        TriggerClientEvent("ems:login", player, true)
        TriggerClientEvent("chatMessage", player, "^2Success: ^7You have logged in as EMS.")
    else
        TriggerClientEvent("chatMessage", player, "^1Error: ^7You don't have permission to log in as EMS.")
    end
end, false)

RegisterCommand("emslogout", function (source, args, rawcommand)
    local player = source

    if IsPlayerAceAllowed(player, "reviveems") then
        -- Set session variable to mark player as EMS
        TriggerClientEvent("ems:login", player, false)
        TriggerClientEvent("chatMessage", player, "^2Success: ^7You have logged out as EMS.")
    else
        TriggerClientEvent("chatMessage", player, "^1Error: ^7You don't have permission to log out as EMS.")
    end 
end, false)