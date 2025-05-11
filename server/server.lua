local QBCore = exports['qb-core']:GetCoreObject()
local cacheData = {}
local playerPositions = {}

RegisterNetEvent('race:getData')
AddEventHandler('race:getData', function()
    -- Ambil semua data track dari database
    local tracks = MySQL.Sync.fetchAll("SELECT * FROM exter_racing_track", {})
    local racesRaw = MySQL.Sync.fetchAll("SELECT * FROM exter_racing", {})
    local aliasRaw = MySQL.Sync.fetchAll("SELECT * FROM exter_racing_alias", {})

    local data = {
        tracks = {},
        alias = {},
    }

    -- Decode setiap race data yang berbentuk JSON
    for _, raceRow in ipairs(racesRaw) do
        local races = raceRow.races
        if type(races) == "string" then
            races = json.decode(races)
        end

        table.insert(data.tracks, {
            id = raceRow.id,
            races = races
        })
    end

    -- Alias
    for _, alias in ipairs(aliasRaw) do
        data.alias[alias.identifier] = {
            alias = alias.alias,
            data = {}
        }
    end

    -- Cekpoint Track
    for _, track in ipairs(tracks) do
        table.insert(data.tracks, {
            id = track.id,
            track_data = json.decode(track.track_data),
            checkpoints = json.decode(track.checkpoints)
        })
    end

    cacheData = data
end)

RegisterNetEvent('race:dataPostClient')
AddEventHandler('race:dataPostClient',function()
    TriggerClientEvent('race:setClient',source,cacheData)
end)

CreateCallback('race:data', function(source, cb)
    cb({races = cacheData})
end)

CreateCallback('race:trackItemControl', function(source, cb)
    local src = source
    local item = GetItemCount(src,Config.trackItem)
    if item == 0 then
        cb({message = "You don't have the necessary chip to create ", type = "error"})
        return
    end
    cb({message = "You have the necessary chip to create ", type = "success"})
    return
end)

CreateCallback('race:create', function(source, cb, raceData)
    local src = source
    local raceId = raceData.trackId
    local playerCid = GetPlayerCid(source)
    local item = GetItemCount(src,Config.trackItem)
    if item == 0 then
        cb({message = "You don't have the necessary chip to create the race ", type = "error"})
        return
    end
    
    if not table.contains(Config.authorization, playerCid) then
        cb({message = "You are not authorized to create a race.", type = "error"})
        return
    end

    for _, race in ipairs(cacheData) do
        if race.id == raceId then
            if type(race.races) == "string" then
                race.races = json.decode(race.races)
            end

            for _, r in pairs(race.races) do
                if type(r) == "boolean" then
                    goto continue
                end

                if r.completed == false and r.identifier == playerCid then
                    cb({message = "You already have a race created", type = "error"})
                    TriggerClientEvent('race:nuiUpdate', source, cacheData)
                    return
                end
                ::continue::
            end
            
            cb({message = "There is already a race prepared in this region", type = "error"})
            return
        end
    end

    local aliasData = cacheData['alias'][playerCid] or {}
    local playerAlias = aliasData.alias or "Unknown"

    local newRaceEntry = {
        id = raceId,
        races = {
            {
                id = raceId,
                creator = source,
                eventName = raceData.eventName,
                vehicleClass = raceData.vehicleClass,
                buyIn = raceData.buyIn,
                laps = raceData.laps,
                countdownStart = raceData.countdownStart,
                dnfPosition = raceData.dnfPosition,
                dnfCountdown = raceData.dnfCountdown,
                password = raceData.password,
                sendNotification = raceData.sendNotification,
                reverse = raceData.reverse,
                showPosition = raceData.showPosition,
                forceFPP = raceData.forceFPP,
                checkpoints = raceData.checkpoints,
                distance = raceData.distance,
                type = raceData.type,
                players = {{identifier = playerCid,alias = playerAlias}},
                raceResult = {},
                startTime = nil,
                identifier = playerCid,
                startControl = false,
                completed = false,
            }
        }
    }

    table.insert(cacheData, newRaceEntry)

    TriggerClientEvent('race:update', -1, cacheData)
    Wait(1000)
    TriggerClientEvent('race:nuiUpdate', source, cacheData)
    cb({message = "Race created with ID: " .. raceId, type = "success", race = newRaceEntry})
    
    MySQL.Sync.execute("INSERT INTO exter_racing (id, races) VALUES (@id, @races)", {
        ['@id'] = raceId,
        ['@races'] = json.encode(newRaceEntry.races),
    })
end)

CreateCallback('race:join', function(source, cb, raceId, password, carType)
    for _, race in ipairs(cacheData) do
        if race.id == raceId then
            if type(race.races) == "string" then
                race.races = json.decode(race.races)
            end

            for _, r in pairs(race.races) do
                if r.password then 
                    if r.password ~= password then 
                        cb({message = "Password is incorrect", type = "error"})
                        return
                    end
                end

                if r.vehicleClass == "Open" then
                elseif r.vehicleClass == "Fast" then
                    if carType == "Slow" then
                        cb({message = "Slow cars are not allowed in Fast races", type = "error"})
                        return
                    end
                elseif r.vehicleClass == "Slow" then
                    if carType == "Fast" then
                        cb({message = "Fast cars are not allowed in Slow races", type = "error"})
                        return
                    end
                else
                    cb({message = "Invalid race vehicle class", type = "error"})
                    return
                end

                local result = addPlayerToRace(source, race, r)
                cb(result)
                return
            end
        end
    end
    cb({message = "You can't take part in this race", type = "error"})
end)

CreateCallback('race:endrace', function(source, cb, raceId)
    for i, race in ipairs(cacheData) do
        if race.id == raceId then
            table.remove(cacheData, i)

            MySQL.Sync.execute("DELETE FROM exter_racing WHERE id = @id", {
                ['@id'] = race.id
            })

            TriggerClientEvent('race:update', -1, cacheData)
            TriggerClientEvent('race:nuiUpdate', -1, cacheData)
            cb({message = "Race ended and removed with ID: " .. raceId, type = "success"})
            return
        end
    end

    cb({message = "Race not found with ID: " .. raceId, type = "error"})
end)

CreateCallback('race:login', function(source, cb, alias)
    local playerCid = GetPlayerCid(source)

    -- Simpan alias ke database (jika sudah ada, update)
    MySQL.Sync.execute([[
        INSERT INTO exter_racing_alias (identifier, alias)
        VALUES (@identifier, @alias)
        ON DUPLICATE KEY UPDATE alias = @alias
    ]], {
        ['@identifier'] = playerCid,
        ['@alias'] = alias
    })

    -- Simpan ke cache
    cacheData['alias'] = cacheData['alias'] or {}
    cacheData['alias'][playerCid] = {
        alias = alias,
        data = {}
    }

    -- Kirim update ke semua client
    TriggerClientEvent('race:update', -1, cacheData)

    -- Callback sukses
    cb({ alias = alias })
end)

CreateCallback('race:start', function(source, cb, raceId)
    local playerCid = GetPlayerCid(source)
    local raceToStart = nil
    for _, race in ipairs(cacheData) do
        if race.id == raceId then
            if type(race.races) == "string" then
                race.races = json.decode(race.races)
            end
            raceToStart = race
            break
        end
    end

    if not raceToStart then
        cb({ message = "Race not found", type = "error" })
        return
    end

    local controlRace = raceToStart.races[1] or raceToStart.races["1"]
    if not controlRace then
        cb({ message = "No control data for this race", type = "error" })
        return
    end

    -- Cek apakah player yang memulai race adalah creator
    if controlRace.identifier ~= playerCid then
        cb({ message = "Only the creator can start this race", type = "error" })
        return
    end

    -- Tandai waktu mulai race
    controlRace.startTime = os.time()
    controlRace.startControl = true

    -- Simpan ke database
    MySQL.Sync.execute("UPDATE exter_racing SET races = @races WHERE id = @id", {
        ['@id'] = raceToStart.id,
        ['@races'] = json.encode(raceToStart.races)
    })

    -- Update ke semua pemain dalam race
    local racers = {}
    for _, player in ipairs(controlRace.players) do
        local targetSrc = playersByIdentifier[player.identifier]
        if targetSrc then
            table.insert(racers, targetSrc)
        end
    end

    -- Broadcast start ke semua peserta
    for _, player in ipairs(controlRace.players) do
        local targetSrc = playersByIdentifier[player.identifier]
        if targetSrc then
            TriggerClientEvent('race:started', targetSrc, raceId, racers)
        end
    end

    cb({
        message = "Race started!",
        type = "success",
        race = controlRace
    })
end)

totalCheckpoints = 0

RegisterNetEvent('race:updatePlayerPosition')
AddEventHandler('race:updatePlayerPosition', function(raceId, lap, checkpoint,checkpointTime,totalCheckpoints,bestLapTime,carName,carTransmission,carTurbo,carType)
    local source = source
    if not playerPositions[source] then
        playerPositions[source] = {}
    end
    playerPositions[source].lap = lap
    playerPositions[source].checkpoint = checkpoint
    playerPositions[source].checkpointTime = checkpointTime
    playerPositions[source].identifier = GetPlayerCid(source)
    playerPositions[source].totalCheckpoints = totalCheckpoints
    playerPositions[source].carName = carName
    playerPositions[source].carTransmission = carTransmission
    playerPositions[source].carTurbo = carTurbo
    playerPositions[source].carType = carType
    totalCheckpoints  = totalCheckpoints

    if bestLapTime then
        playerPositions[source].bestLapTime = bestLapTime
    else
        playerPositions[source].bestLapTime = 0
    end
    updatePlayerPositions(raceId,source)

end)

RegisterNetEvent('race:finish')
AddEventHandler('race:finish', function(raceId,raceposition,bestLapTime)
    local src = source
    CheckRaceCompletion(raceId,raceposition,bestLapTime,src)
end)

RegisterNetEvent('race:disqualify')
AddEventHandler('race:disqualify', function(raceId)
    local source = source
    for _, race in ipairs(cacheData) do
        if race.id == raceId then
            for i, playerId in ipairs(race.races.players) do
                if playerId == source then
                    table.remove(race.races.players, i)
                    break
                end
            end
            playerPositions[source] = nil
            TriggerClientEvent('race:disqualified', source)
            CheckRaceCompletion(raceId, 0, 0, source)
            return
        end
    end
end)

RegisterNetEvent("race:recieveCreateData")
AddEventHandler("race:recieveCreateData", function(pRaceName, pRaceType, pRaceMinLaps, pCheckpoints)
    local src = source
    local playerCid = GetPlayerCid(src)
    local alias = cacheData['alias'][playerCid]

    local distanceMap = 0.0
    for i, v in ipairs(pCheckpoints) do
        if i == #pCheckpoints and pRaceType == "Lap" then
            distanceMap = #(vector3(v["pos"]["x"], v["pos"]["y"], v["pos"]["z"]) - vector3(pCheckpoints[1]["pos"]["x"], pCheckpoints[1]["pos"]["y"], pCheckpoints[1]["pos"]["z"])) + distanceMap
        elseif i ~= #pCheckpoints then
            distanceMap = #(vector3(v["pos"]["x"], v["pos"]["y"], v["pos"]["z"]) - vector3(pCheckpoints[i+1]["pos"]["x"], pCheckpoints[i+1]["pos"]["y"], pCheckpoints[i+1]["pos"]["z"])) + distanceMap
        end
    end
    distanceMap = math.ceil(distanceMap)

    local newRace = {
        eventName = pRaceName,
        vehicleClass = "Open",
        laps = pRaceMinLaps,
        distance = distanceMap,
        type = pRaceType,
        createTime = os.time(),
    }

    local insertId = MySQL.Sync.insert("INSERT INTO exter_racing_track (track_data, checkpoints) VALUES (@track_data, @checkpoints)", {
        ['@track_data'] = json.encode(newRace),
        ['@checkpoints'] = json.encode(pCheckpoints),
    })

    table.insert(cacheData['tracks'], {track_data = newRace, checkpoints = pCheckpoints, id = insertId})

    TriggerClientEvent('race:trackUpdate', -1, cacheData['tracks'])
end)

RegisterUseableItem("racetablet")

function addPlayerToRace(source, race, r)
    local playerCid = GetPlayerCid(source)
    for _, player in ipairs(r.players) do
        if player.identifier == playerCid then
            return {message = "You have already joined this race", type = "error"}
        end
    end

    if GetPlayerMoney(source, 'cash') >= tonumber(r.buyIn) then
        RemoveMoney(source, 'cash', tonumber(r.buyIn))

        local aliasData = cacheData['alias'][playerCid] or {}
        local playerAlias = aliasData.alias or "Unknown"


        local playerData = {
            identifier = playerCid,
            alias = playerAlias
        }

        table.insert(r.players, playerData)
        playerPositions[source] = { lap = 1, checkpoint = 1 }
        
        for _, cacheRace in ipairs(cacheData) do
            if cacheRace.id == race.id then
                cacheRace.races = race.races
                break
            end
        end
        
        TriggerClientEvent('race:update', -1, cacheData)
        
        TriggerClientEvent('race:joined', source, r)
        
        MySQL.Sync.execute("UPDATE exter_racing SET races = @races WHERE id = @id", {
            ['@id'] = race.id,
            ['@races'] = json.encode(race.races)
        })

        return {message = "You have joined", type = "success", players = r.players}
    else
        return {message = "You do not have enough money to join this", type = "error"}
    end
end

function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

function hasPlayerJoinedRace(players, playerCid)
    for _, player in pairs(players) do
        if player.identifier == playerCid then
            return true
        end
    end
    return false
end

function updatePlayerPositions(raceId, source)
    for _, race in ipairs(cacheData) do
        if race.id == raceId then
            if type(race.races) == "string" then
                race.races = json.decode(race.races)
            end
            
            if type(race.races) == "table" then
                for _, r in pairs(race.races) do
                    if type(r) == "table" then
                        table.sort(r.players, function(a, b)
                            local posA = getPlayerPosition(a.identifier)
                            local posB = getPlayerPosition(b.identifier)

                            if posA.lap == posB.lap then
                                return posA.checkpoint > posB.checkpoint
                            else
                                return posA.lap > posB.lap
                            end
                        end)

                        local raceFinished = true
                        local playerCount = #r.players
                        local raceMoney = r.buyIn * playerCount
                        local rr = race.races[1] or race.races['1']
                        local raceStartTime = rr and rr.startTime or os.time()

                        for i, player in ipairs(r.players) do
                            local timeDifference

                            local posCurrent = getPlayerPosition(player.identifier)
                            r.laps = tonumber(r.laps)
                            
                            if i == 1 then
                                timeDifference = "0.000"
                            else
                                local previousPlayer = r.players[i - 1]
                                local posPrevious = getPlayerPosition(previousPlayer.identifier)
                                
                                local checkpointDifference = math.abs((posCurrent.lap * totalCheckpoints + posCurrent.checkpoint) - (posPrevious.lap * totalCheckpoints + posPrevious.checkpoint))
                                local randomTime = math.random(100, 500) / 1000
                                timeDifference = string.format("-%0.3f", checkpointDifference * randomTime)
                            end
                            player.timeDifference = timeDifference

                            if posCurrent.lap >= r.laps then
                                player.finishTime = os.time() - raceStartTime
                            else
                                player.finishTime = nil
                                raceFinished = false
                            end

                            if i == 1 then
                                player.cash = raceMoney * 0.50
                            elseif i == 2 then
                                player.cash = raceMoney * 0.30
                            elseif i == 3 then
                                player.cash = raceMoney * 0.20
                            else
                                player.cash = 0
                            end

                            local playerData = playerPositions[source]
                            if playerData and playerData.bestLapTime then
                                player.bestLapTime = playerData.bestLapTime
                            else
                                player.bestLapTime = nil
                            end
                            player.carName = playerPositions[source].carName
                            player.carTransmission = playerPositions[source].carTransmission
                            player.carTurbo = playerPositions[source].carTurbo
                            player.alias = cacheData['alias'][player.identifier]
                        end



                        -- if raceFinished then
                        --     print("All players have finished the race.")
                        -- end

                        TriggerClientEvent('race:positionsUpdated', -1, raceId, r.players)
                    else
                        -- print("Skipping non-table value in race.races: ", r)
                    end
                end
            end
        end
    end
end

function getPlayerPosition(playerIdentifier)
    for _, pos in pairs(playerPositions) do
        if pos.identifier == playerIdentifier then
            return pos
        end
    end
    return {lap = 0, checkpoint = 0}
end

function CheckRaceCompletion(raceId, raceposition, bestTime, source)
    local playerCid = GetPlayerCid(source)
    for _, race in ipairs(cacheData) do
        if race.id == raceId then
            if type(race.races) == "string" then
                race.races = json.decode(race.races)
            end

            for _, r in pairs(race.races) do
                if not r.completed and r.identifier == playerCid then
                    r.completed = true
                    r.finishTime = os.time()

                    -- Tandai posisi dan waktu terbaik pemain
                    for _, p in ipairs(r.players) do
                        if p.identifier == playerCid then
                            p.racePosition = raceposition
                            p.bestLapTime = bestTime or 0
                            break
                        end
                    end

                    -- Simpan ke database
                    MySQL.Sync.execute("UPDATE exter_racing SET races = @races WHERE id = @id", {
                        ['@id'] = race.id,
                        ['@races'] = json.encode(race.races)
                    })

                    -- Kirim update ke semua client
                    TriggerClientEvent('race:update', -1, cacheData)
                    return
                end
            end
        end
    end
end


function GetPlayerFromCid(identifier)
    for _, player in ipairs(GetPlayers()) do
        if GetPlayerCid(player) == identifier then
            return player
        end
    end
    return nil
end

RegisterNetEvent('race:addSource')
AddEventHandler('race:addSource',function()
    local src = source
    local identifier = GetPlayerCid(src)
    if identifier then
        playersByIdentifier[identifier] = src
    end
end)

RegisterNetEvent('race:removeSource',function()
    local src = source
    local identifier = GetPlayerCid(src)
    if identifier then
        playersByIdentifier[identifier] = nil
    end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer, isNew)
    local identifier = GetPlayerCid(playerId)
    if identifier then
        playersByIdentifier[identifier] = playerId
    end
end)

AddEventHandler('esx:playerDropped', function(playerId, reason) 
    local identifier = GetPlayerCid(playerId)
    if identifier then
        playersByIdentifier[identifier] = nil
    end
end)