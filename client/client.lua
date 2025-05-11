local QBCore = exports['qb-core']:GetCoreObject()
local creating = false
local radius = 4.0

local raceName = nil
local raceType = nil
local raceMinLaps = nil
local checkpoints = {}
local blips = {}
local createdObjects = {}
local object1, object2


local bestLapTime = nil
local lastLapTime = nil
local checkpointTime = 0
local groupedCheckpointTimes = {}
local checkpointsPerGroup = 0
local currentGroupIndex = 1

function changeRadius(dir)
    if dir == "up" then
        radius = radius + 0.1
    elseif dir == "down" then
        radius = math.max(radius - 0.1, 1.0)
    end
end

function changeRotation(dir)
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    local head = GetEntityHeading(veh)
    if dir == "left" then
        SetEntityHeading(veh, head + 1.0)
    elseif dir == "right" then
        SetEntityHeading(veh, head - 1.0)
    end
end

function updateObjects()
    if object1 == nil then
        return
    end

    local plyPed = PlayerPedId()
    local coords = GetEntityCoords(plyPed)
    local heading = GetEntityHeading(plyPed)
    local objPos1, objPos2 = getCheckpointObjectPositions(coords, radius, heading)

    SetEntityCoords(object1, objPos1, 0.0, 0.0, 0.0, false)
    SetEntityCoords(object2, objPos2, 0.0, 0.0, 0.0, false)
    SetEntityHeading(object1, heading)
    SetEntityHeading(object2, heading + 180.0)

    PlaceObjectOnGroundProperly(object1)
    PlaceObjectOnGroundProperly(object2)
end

function spawnObjects(start)
    if object1 ~= nil then
        cleanupObjects()
    end

    local cpobject = Config.FlagProp

    RequestModelAndLoad(cpobject)

    local plyPed = PlayerPedId()
    local coords = GetEntityCoords(plyPed)
    local heading = GetEntityHeading(plyPed)
    local objPos1, objPos2 = getCheckpointObjectPositions(coords, radius, heading)

    object1 = CreateObjectNoOffset(cpobject, objPos1, false, false, false)
    object2 = CreateObjectNoOffset(cpobject, objPos2, false, false, false)

    PlaceObjectOnGroundProperly(object1)
    PlaceObjectOnGroundProperly(object2)

    SetEntityCollision(object1, false, false)
    SetEntityCollision(object2, false, false)

    SetModelAsNoLongerNeeded(cpobject)
end

function RequestModelAndLoad(hash)
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(0)
    end
end

function getCheckpointObjectPositions(origin, radius, heading)
    if heading == nil then heading = 0.0 end
    local leftObjPos = vector3(origin.x - radius, origin.y, origin.z)
    local rightObjPos = vector3(origin.x + radius, origin.y, origin.z)
    return rotate(origin, leftObjPos, heading), rotate(origin, rightObjPos, heading)
end

function rotate(origin, point, theta)
    if theta == 0.0 then return point end
    local p = point - origin
    local pX, pY = p.x, p.y
    theta = math.rad(theta)
    local cosTheta = math.cos(theta)
    local sinTheta = math.sin(theta)
    local x = pX * cosTheta - pY * sinTheta
    local y = pX * sinTheta + pY * cosTheta
    return vector3(x, y, 0.0) + origin
end

function DrawText3Ds(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(_x, _y)
    local factor = (string.len(text)) / 340
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
end

function addCheckpoint()
    local pos = GetEntityCoords(PlayerPedId())
    local heading = GetEntityHeading(PlayerPedId())
    local leftObjPos, rightObjPos = getCheckpointObjectPositions(pos, radius, heading)

    checkpoints[#checkpoints + 1] = {
      pos = {
          x = tonumber(string.format("%.3f", pos.x)),
          y = tonumber(string.format("%.3f", pos.y)),
          z = tonumber(string.format("%.3f", pos.z)),
      },
      hdg = tonumber(string.format("%.3f", heading)),
      rad = tonumber(string.format("%.3f", radius)),
      leftObjPos = {
          x = tonumber(string.format("%.3f", leftObjPos.x)),
          y = tonumber(string.format("%.3f", leftObjPos.y)),
          z = tonumber(string.format("%.3f", leftObjPos.z)),
      },
      rightObjPos = {
          x = tonumber(string.format("%.3f", rightObjPos.x)),
          y = tonumber(string.format("%.3f", rightObjPos.y)),
          z = tonumber(string.format("%.3f", rightObjPos.z)),
      }
    }


    PlaySound(-1, "3_2_1", "HUD_MINI_GAME_SOUNDSET", 0, 0, 1)

    if #checkpoints == 1 then
        spawnObjects(false)
    end

    local blip = AddBlipForCoord(pos)

    ShowNumberOnBlip(blip, #checkpoints)
    SetBlipDisplay(blip, 8)
    SetBlipScale(blip, 1.0)
    SetBlipAsShortRange(blip, true)

    blips[#blips + 1] = blip

end

function removeCheckpoint()
    if #checkpoints == 0 then
        return
    end

    checkpoints[#checkpoints] = nil

    PlaySound(-1, "CHECKPOINT_NORMAL", "HUD_MINI_GAME_SOUNDSET", 0, 0, 1)

    if #checkpoints < 1 then
        spawnObjects(true)
    end

    RemoveBlip(blips[#blips])
    blips[#blips] = nil

end

function clearCreationBlips()
    for i = 1, #blips do
        RemoveBlip(blips[i])
    end
    blips = {}
end

function startRaceCreation(options)
    options = options or {}
    raceName = options.name or "Unnamed"
    raceType = options.type or "Lap"
    raceMinLaps = options.laps or 1
    creating = true
    spawnObjects(true)
    CreateThread(function()
        while creating do
            if IsControlPressed(0, 172) then
                changeRadius("up")
            end
            if IsControlPressed(0, 173) then
                changeRadius("down")
            end
            if IsControlPressed(0, 174) then
                if GetEntitySpeed(GetVehiclePedIsIn(PlayerPedId(), false)) <= 0 then
                    changeRotation("left")
                end
            end
            if IsControlPressed(0, 175) then
                if GetEntitySpeed(GetVehiclePedIsIn(PlayerPedId(), false)) <= 0 then
                    changeRotation("right")
                end
            end
            if not IsControlPressed(0, 21) and IsControlJustPressed(0, 51) then
                addCheckpoint()
            end
            if IsControlPressed(0, 21) and IsControlJustPressed(0, 51) then
                removeCheckpoint()
            end
            Wait(0)
        end
    end)

    CreateThread(function()
        local ped = PlayerPedId()
        while creating do
            local pos = GetEntityCoords(ped)
            local rot = GetEntityHeading(PlayerPedId())

            DrawMarker(26, pos.x, pos.y, pos.z + 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, rot, radius * 2, radius * 2, 5.0, 255, 128, 0, 25, false, false, 2, nil, nil, false)
            updateObjects()
            Wait(0)
        end
    end)

    CreateThread(function()
        local ped = PlayerPedId()
        while creating do
            local pos = GetEntityCoords(ped)
            local instructions = "#" .. tostring(#checkpoints) .. " | [E] Add | [Shift+E] Remove | ⬆ Radius ⬇ | ⬅ Rotation ➡"
            DrawText3Ds(pos.x, pos.y, pos.z + 1.5, instructions)
            Wait(0)
        end
    end)
end

function finishRaceCreation()
    if not creating then
        return
    end

    TriggerServerEvent("race:recieveCreateData", raceName, raceType, raceMinLaps, checkpoints)
    cleanupCreation()
end

function cancelRaceCreation()
    if not creating then
        return
    end

    cleanupCreation()
end

function cleanupObjects()
    DeleteObject(object1)
    DeleteObject(object2)
    object1, object2 = nil, nil
end

function cleanupCreation()
    creating = false
    radius = 4.0
    raceName = nil
    raceType = nil
    checkpoints = {}
    cleanupObjects()
    clearCreationBlips()
end

RegisterNetEvent("mkr_racing:cmd:racecreate")
AddEventHandler("mkr_racing:cmd:racecreate", function(options)
    if GetVehiclePedIsIn(PlayerPedId(), false) ~= 0 then
        startRaceCreation(options)
        print("01")
    end
end)

RegisterNetEvent("mkr_racing:cmd:racecreatedone")
AddEventHandler("mkr_racing:cmd:racecreatedone", function()
    finishRaceCreation()
    print('02')
end)

RegisterNetEvent("mkr_racing:cmd:racecreatecancel")
AddEventHandler("mkr_racing:cmd:racecreatecancel", function()
    cancelRaceCreation()
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end

    cleanupCreation()
end)

local raceTimeLimit = 5
local forceFPP = "No"
local showPosition = "No"
local totalLaps = 1
local racecheckpoints = nil
local currentLap = 1
local currentCheckpoint = 1
local blips = {}
local raceStarted = false
local raceStartTime = 0
local lapStartTime = 0
local countdownActive = false
local countdownTime = 60
local currentRaceId = nil
local cacheData = {}
local identifier = nil

tabletObject = nil
playerPed = nil

RegisterNetEvent('race:openTablet')
AddEventHandler('race:openTablet', function(data)

    playerPed = PlayerPedId()

    local tabletModel = GetHashKey('prop_cs_tablet')
    RequestModel(tabletModel)
    while not HasModelLoaded(tabletModel) do
        Citizen.Wait(100)
    end

    if tabletObject then
        DeleteEntity(tabletObject)
        tabletObject = nil
    end

    tabletObject = CreateObject(tabletModel, GetEntityCoords(playerPed), true, true, false)
    AttachEntityToEntity(tabletObject, playerPed, GetPedBoneIndex(playerPed, 18905), 0.13, 0.0, 0.03, 0.0, 270.0, 20.0, true, true, false, true, 1, true)

    local animDict = "amb@code_human_in_bus_passenger_idles@female@tablet@base"
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(100)
    end

    TaskPlayAnim(playerPed, animDict, "base", 8.0, -8.0, -1, 50, 0, false, false, false)
    SetNuiFocus(true, true)
    local racesData = {}
    for k, v in pairs(cacheData) do
        if type(v.races) == "table" and next(v.races) ~= nil then
            for _, race in pairs(v.races) do
                table.insert(racesData, race)
            end
        end
    end
    SendNUIMessage({
        type = "open",
        tracks = cacheData['tracks'],
        races = racesData,
        identifier = identifier,
        alias = cacheData['alias'][identifier],
        allAlias = cacheData['alias'],
        raceCreated = creating,
        config = PA
    })
end)

RegisterNetEvent('race:nuiUpdate')
AddEventHandler('race:nuiUpdate', function(data)
    local racesData = {}
    for k, v in pairs(cacheData) do
        if type(v.races) == "table" and next(v.races) ~= nil then
            for _, race in pairs(v.races) do
                table.insert(racesData, race)
            end
        end
    end
    SendNUIMessage({
        type = "update",
        races = racesData
    })
end)

RegisterNetEvent('race:update')
AddEventHandler('race:update', function(raceData)
    cacheData = raceData
end)

RegisterNetEvent('race:trackUpdate', function(data)
    cacheData['tracks'] = data
end)

RegisterNetEvent('race:setClient')
AddEventHandler('race:setClient', function(data)
    cacheData = data
    if cacheData then
        for k, v in pairs(cacheData) do
            id = v.id
            races = v.races
        end
    end
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    racesDataLoaded()
end)

RegisterNetEvent('esx:playerLoaded', function()
    racesDataLoaded()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    TriggerServer('race:removeSource')
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if NetworkIsPlayerActive(PlayerId()) then
            racesDataLoaded()
            break
        end
    end
end)

function racesDataLoaded()
    identifier = GetPlayerIdentifier()
    TriggerServerEvent('race:addSource')
    TriggerServerEvent('race:dataPostClient')
end

RegisterNUICallback('createTrack', function(data, cb)
    TriggerCallback('race:trackItemControl', function(call)
        cb(call)
        if call.type == "success" then
            SetNuiFocus(false, false)
            ClearPedTasks(playerPed)
            DeleteEntity(tabletObject)
            TriggerEvent('mkr_racing:cmd:racecreate', data)
        end
    end, data)
end)

RegisterNUICallback('finishTrack', function(data, cb)
    TriggerEvent('mkr_racing:cmd:racecreatedone')
    SetNuiFocus(false, false)
    ClearPedTasks(playerPed)
    DeleteEntity(tabletObject)
end)

RegisterNUICallback('cancelTrack', function(data, cb)
    TriggerEvent('mkr_racing:cmd:racecreatecancel')
    SetNuiFocus(false, false)
    ClearPedTasks(playerPed)
    DeleteEntity(tabletObject)
end)

RegisterNUICallback('setgps', function(data, cb)
    coords = filterTrackCache(data.id).checkpoints[1].pos
    SetNewWaypoint(coords.x, coords.y)
end)

function filterTrackCache(id)
    local track = nil
    for k, v in pairs(cacheData['tracks']) do
        if v.id == id then
            track = v
        end
    end
    return track
end

function getCarType(playerVehicle)
    local vehicleModel = GetEntityModel(playerVehicle)
    local vehicleClass = GetVehicleClass(playerVehicle)
    local carType

    if vehicleClass == 0 or vehicleClass == 1 or vehicleClass == 2 or vehicleClass == 3 then
        carType = "Open"
    elseif vehicleClass == 4 or vehicleClass == 5 or vehicleClass == 6 then
        carType = "Slow"
    elseif vehicleClass == 7 or vehicleClass == 8 or vehicleClass == 9 then
        carType = "Fast"
    else
        carType = "Open"
    end

    return carType
end

RegisterNUICallback('joinrace', function(data, cb)
    data.id = tonumber(data.id)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local carType = getCarType(vehicle)
    TriggerCallback('race:join', function(call)
        cb(call)
    end, data.id, data.password,carType)
end)

RegisterNUICallback('createRace', function(data, cb)
    data.id = tonumber(data.id)
    myTrack = filterTrackCache(data.currentTrackId)
    local raceData = {
        id = data.id,
        trackId = data.currentTrackId,
        eventName = data.eventname,
        vehicleClass = data.vehicleclass,
        buyIn = data.buyin,
        laps = data.laps,
        countdownStart = data.countdown,
        dnfPosition = data.dnfposition,
        dnfCountdown = data.dnfcountdown,
        password = data.password,
        sendNotification = data.notification,
        reverse = data.reverse,
        showPosition = data.showposition,
        forceFPP = data.forcefpp,
        raceDuration = data.raceduration or 600,
        checkpoints = myTrack.checkpoints,
        type = myTrack.track_data.type,
        distance = myTrack.track_data.distance,
    }
    TriggerCallback('race:create', function(call)
        cb(call)
    end, raceData)
end)

RegisterNUICallback('endrace', function(data, cb)
    TriggerCallback('race:endrace', function(call)
        cb(call)
    end, data.id)
end)

RegisterNUICallback('close', function()
    SetNuiFocus(false, false)
    ClearPedTasks(playerPed)
    DeleteEntity(tabletObject)
end)

RegisterNUICallback('login', function(data, cb)
    TriggerCallback('race:login', function(call)
        cb(call)
    end, data.alias)
end)

RegisterNUICallback('startrace', function(data, cb)
    TriggerCallback('race:start',function(call)
        cb(call)
        if call.type == "success" then
            SetNuiFocus(false, false)
            ClearPedTasks(playerPed)
            DeleteEntity(tabletObject)
        end
    end, data.id)
end)

RegisterNetEvent('race:joined')
AddEventHandler('race:joined', function(race)
    racecheckpoints = race.checkpoints
    checkpointsPerGroup = math.ceil(#racecheckpoints / 4)
    for i = 1, 4 do
      table.insert(groupedCheckpointTimes, {groupIndex = i, totalTime = 0})
    end
    totalLaps = race.laps
    currentCheckpoint = 1
    blips = {}
    raceStarted = false
    currentRaceId = race.id
    NotifyPlayer(Config.Notify['racejoin'])
end)

racerspeds = {}

RegisterNetEvent('race:started')
AddEventHandler('race:started', function(id, racerIds)
    currentRaceId = id
    racerspeds = racerIds
    local raceDataFound = false

    for k, v in pairs(cacheData) do
        if v.races ~= nil then 
            local controlData = v.races[1] or v.races['1']
    
            if controlData and v.id == id then 
                totalLaps = tonumber(controlData.laps)
                raceTimeLimit = tonumber(controlData.raceDuration or 600)
                forceFPP = controlData.forceFPP
                showPosition = controlData.showPosition
                raceDataFound = true
                break 
            end
        end
    end

    if raceDataFound then
        local time = Config.StartTime * 1000
        QBCore.Functions.Notify('Starting in ' .. Config.StartTime .. ' seconds', 'primary', Config.StartTime * 1000)

        local playerVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if playerVehicle ~= 0 then 
            FreezeEntityPosition(playerVehicle, true)
        end
        
        Wait(time)
        
        if playerVehicle ~= 0 then 
            FreezeEntityPosition(playerVehicle, false)
        end

        StartRace()
        raceStarted = true

        if forceFPP == "Yes" then
            Citizen.CreateThread(function()
                SetFollowVehicleCamViewMode(4)
                while raceStarted do
                    Citizen.Wait(0)
                    DisableControlAction(0, 0, true) 
                end
                EnableControlAction(0, 0, true) 
            end)
        end
    else
        -- print("Race data not found for race ID:", id)
    end
end)

local racePositions = {}
RegisterNetEvent('race:positionsUpdated')
AddEventHandler('race:positionsUpdated', function(raceId, players)
    racePositions = players
end)

function SetCollisions(_, bool)
    local racevehicles = {}
    for k,v in pairs(racerspeds) do
        local i = GetPlayerFromServerId(v)
        local ped = GetPlayerPed(i)
        local veh = GetVehiclePedIsIn(ped, false)
        if veh and veh ~= 0 then
            table.insert(racevehicles, veh)
        end
    end
    local userCar = GetVehiclePedIsIn(PlayerPedId(), false)
    local ped = PlayerPedId()
    for _, vehicle in pairs(racevehicles) do
        if vehicle and vehicle ~= -1 then
            if DoesEntityExist(vehicle) and vehicle ~= userCar then
                SetEntityNoCollisionEntity(userCar, vehicle, bool)
            end
        end
    end
end

Citizen.CreateThread(function()
    local lastNUIUpdate = GetGameTimer()
    local lastServerUpdate = GetGameTimer()

    
    while true do
        Citizen.Wait(0)
        if raceStarted then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local checkpointCoords = vector3(racecheckpoints[currentCheckpoint].pos.x, racecheckpoints[currentCheckpoint].pos.y, racecheckpoints[currentCheckpoint].pos.z)
            local checkpointRadius = racecheckpoints[currentCheckpoint].rad

            -- DrawMarker(1, checkpointCoords.x, checkpointCoords.y, checkpointCoords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, checkpointRadius * 2, checkpointRadius * 2, 1.0, 255, 0, 0, 100, false, true, 2, false, nil, nil, false)
            
            if showPosition then 
                SetCollisions(racerspeds, true)            
            end

            if GetDistanceBetweenCoords(playerCoords, checkpointCoords, true) < 5.0 then
                checkpointTime = (GetGameTimer() - raceStartTime) / 1000

                groupedCheckpointTimes[currentGroupIndex].totalTime = checkpointTime

                if currentCheckpoint % checkpointsPerGroup == 0 or currentCheckpoint == #racecheckpoints then
                    currentGroupIndex = currentGroupIndex + 1
                end

                RemoveBlip(blips[currentCheckpoint])
                currentCheckpoint = currentCheckpoint + 1

                if currentCheckpoint <= #racecheckpoints then
                    local nextCheckpoint = racecheckpoints[currentCheckpoint]
                    SetNewWaypoint(nextCheckpoint.pos.x, nextCheckpoint.pos.y)
                end

                if currentCheckpoint > #racecheckpoints then
                    local currentLapTime = (GetGameTimer() - lapStartTime) / 1000
                    if bestLapTime == nil or currentLapTime < bestLapTime then
                        bestLapTime = currentLapTime
                    end
                    lastLapTime = currentLapTime 

                    currentLap = currentLap + 1
                    lapStartTime = GetGameTimer()
                    if currentLap > totalLaps then
                        SendNUIMessage({type="close"})
                        raceStarted = false
                        TriggerServerEvent('race:finish', currentRaceId, racePositions)
                        TriggerEvent('race:finished', true)
                    else
                        currentCheckpoint = 1
                        currentGroupIndex = 1 
                        SetAllCheckpoints()
                    end
                end
            end

            local timeElapsed = GetGameTimer() - raceStartTime
            local timeRemaining = raceTimeLimit - math.floor(timeElapsed / 1000)
            local lapElapsed = math.floor((GetGameTimer() - lapStartTime) / 1000)
            local lapTimeRemaining = (raceTimeLimit / totalLaps) - lapElapsed
            if timeRemaining <= 0 then
                SendNUIMessage({type="close"})
                raceStarted = false
                TriggerServerEvent('race:finish', currentRaceId, racePositions)
                TriggerEvent('race:finished', false)
                cleanupObjects()
            end

            if GetGameTimer() - lastNUIUpdate >= 1000 then
                SendNUIMessage({
                    type = "updateRaceData",
                    time = timeRemaining,
                    lapTime = lapElapsed,
                    lapTimeRemaining = lapTimeRemaining,
                    lap = currentLap,
                    totalLaps = totalLaps,
                    currentCheckpoint = currentCheckpoint,
                    totalCheckpoints = #racecheckpoints,
                    bestLapTime = bestLapTime,
                    lastLapTime = lastLapTime,
                    checkpointTime = checkpointTime, 
                    groupedCheckpointTimes = groupedCheckpointTimes, 
                    racePositions = racePositions,
                    myAlias = cacheData['alias'][identifier]
                })
                lastNUIUpdate = GetGameTimer()
            end

            if GetGameTimer() - lastServerUpdate >= 1000 then
                TriggerServerEvent('race:updatePlayerPosition', 
                currentRaceId, 
                currentLap, 
                currentCheckpoint, 
                checkpointTime, 
                #racecheckpoints,
                bestLapTime,
                currentCarName(),
                getRandomTransmission(),
                getCarPowerByType(getCarType(GetVehiclePedIsIn(PlayerPedId(), false))),
                determineCarCustomization(getCarPowerByType(getCarType(GetVehiclePedIsIn(PlayerPedId(), false))))
            )
                lastServerUpdate = GetGameTimer()
            end
        end
    end
end)

function currentCarName()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local hash = GetEntityModel(vehicle)
    local name = GetDisplayNameFromVehicleModel(hash)
    return name
end

function getRandomTransmission()
    local transmissionTypes = {"Sequential", "Automatic"}
    local selectedTransmission = transmissionTypes[math.random(#transmissionTypes)]
    return selectedTransmission
end

function getCarPowerByType(carType)
    local minPower, maxPower

    if carType == "Open" then
        minPower, maxPower = 100, 200
    elseif carType == "Slow" then
        minPower, maxPower = 200, 300
    elseif carType == "Fast" then
        minPower, maxPower = 300, 500
    else
        minPower, maxPower = 100, 200 
    end

    local carPower = math.random(minPower, maxPower)
    return carPower
end

function determineCarCustomization(carPower)
    if carPower > 300 then
        return "Custom"
    else
        return "Stock"
    end
end

function spawnCheckpointObjects(checkpoint, objectHash, checkpointObjectLimit)
    if checkpointObjectLimit == nil then checkpointObjectLimit = 2 + config.checkpointPropLookahead end
    if checkpoint.rad == nil or checkpoint.hdg == nil then return end
    if #checkpointObjects >= checkpointObjectLimit * 2 then
        deleteFirstCheckpointObjects()
    end
    RequestModelAndLoad(objectHash)
    local leftPos, rightPos = getCheckpointObjectPositions(checkpoint.pos, checkpoint.rad, checkpoint.hdg)
    leftObject = CreateObjectNoOffset(objectHash, leftPos, false, false, false)
    rightObject = CreateObjectNoOffset(objectHash, rightPos, false, false, false)
    checkpointObjects[#checkpointObjects + 1] = leftObject
    checkpointObjects[#checkpointObjects + 1] = rightObject
    PlaceObjectOnGroundProperly(leftObject)
    PlaceObjectOnGroundProperly(rightObject)
    SetEntityHeading(leftObject, checkpoint.hdg)
    SetEntityHeading(rightObject, checkpoint.hdg + 180.0)
    if objectHash == config.startObjectHash then
        SetEntityCollision(leftObject, false)
        SetEntityCollision(rightObject, false)
    end
    SetModelAsNoLongerNeeded(objectHash)
end

local function deleteFirstCheckpointObjects()
    DeleteObject(checkpointObjects[1])
    table.remove(checkpointObjects, 1)
    DeleteObject(checkpointObjects[1])
    table.remove(checkpointObjects, 1)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if raceStarted then
            local playerPed = PlayerPedId()
            if not IsPedInAnyVehicle(playerPed, false) then
                if not countdownActive then
                    countdownActive = true
                    countdownTime = 60
                    NotifyPlayer(Config.Notify["incar"])
                end
                countdownTime = countdownTime - 1
                if countdownTime <= 0 then
                    TriggerServerEvent('race:disqualify', currentRaceId)
                    raceStarted = false
                    ClearAllBlips()
                    NotifyPlayer(Config.Notify["disqualified"])
                end
            else
                countdownActive = false
            end
        end
    end
end)

function StartRace()
    SetAllCheckpoints()
    currentLap = 1
    currentCheckpoint = 1
    raceStartTime = GetGameTimer()
    lapStartTime = GetGameTimer()
end

RegisterNUICallback('racepreview', function(data)
    ClearAllBlips()
  for _, race in ipairs(cacheData) do
      if race.id == data.id then
          if type(race.races) == "string" then
              race.races = json.decode(race.races)
          end

          for _, r in pairs(race.races) do
              if type(r) == "table" then
                  racecheckpoints = r.checkpoints
                  checkpointsPerGroup = math.ceil(#racecheckpoints / 4)
                  for i = 1, 4 do
                    table.insert(groupedCheckpointTimes, {groupIndex = i, totalTime = 0})
                end
              end
          end
      end
  end

  for i, checkpoint in ipairs(racecheckpoints) do
      local blip = AddBlipForCoord(checkpoint.pos.x, checkpoint.pos.y, checkpoint.pos.z)
      SetBlipSprite(blip, 1)
      SetBlipDisplay(blip, 4)
      SetBlipScale(blip, 1.0)
      SetBlipColour(blip, 3)
      SetBlipAsShortRange(blip, true)
      SetBlipFlashes(blip, true)
      BeginTextCommandSetBlipName("STRING")
      AddTextComponentString(tostring(i))
      EndTextCommandSetBlipName(blip)
      ShowNumberOnBlip(blip, i)
      table.insert(blips, blip)
  end

  Wait(5000)

  ClearAllBlips()
end)

function SetAllCheckpoints()
  ClearAllBlips()
  for _, race in ipairs(cacheData) do
      if race.id == currentRaceId then
          if type(race.races) == "string" then
              race.races = json.decode(race.races)
          end

          for _, r in pairs(race.races) do
              if type(r) == "table" then
                  racecheckpoints = r.checkpoints
                  checkpointsPerGroup = math.ceil(#racecheckpoints / 4)
                  for i = 1, 4 do
                    table.insert(groupedCheckpointTimes, {groupIndex = i, totalTime = 0})
                end
              end
          end
      end
  end

  for i, checkpoint in ipairs(racecheckpoints) do
      local blip = AddBlipForCoord(checkpoint.pos.x, checkpoint.pos.y, checkpoint.pos.z)
      SetBlipSprite(blip, 1)
      SetBlipDisplay(blip, 4)
      SetBlipScale(blip, 1.0)
      SetBlipColour(blip, 3)
      SetBlipAsShortRange(blip, true)
      SetBlipFlashes(blip, true)
      BeginTextCommandSetBlipName("STRING")
      AddTextComponentString(tostring(i))
      EndTextCommandSetBlipName(blip)
      ShowNumberOnBlip(blip, i)
      table.insert(blips, blip)

      local cpobject =Config.FlagProp
      RequestModelAndLoad(cpobject)

      local leftObjPos = vector3(checkpoint.leftObjPos.x, checkpoint.leftObjPos.y, checkpoint.leftObjPos.z)
      local rightObjPos = vector3(checkpoint.rightObjPos.x, checkpoint.rightObjPos.y, checkpoint.rightObjPos.z)

      local leftObject = CreateObjectNoOffset(cpobject, leftObjPos, false, false, false)
      local rightObject = CreateObjectNoOffset(cpobject, rightObjPos, false, false, false)

      PlaceObjectOnGroundProperly(leftObject)
      PlaceObjectOnGroundProperly(rightObject)

      SetEntityCollision(leftObject, false, false)
      SetEntityCollision(rightObject, false, false)

      SetModelAsNoLongerNeeded(cpobject)

      table.insert(createdObjects, leftObject)
      table.insert(createdObjects, rightObject)

  end

  if #racecheckpoints > 0 then
      local firstCheckpoint = racecheckpoints[1]
      SetNewWaypoint(firstCheckpoint.pos.x, firstCheckpoint.pos.y)
  end
end

function ClearAllBlips()
    for i, blip in ipairs(blips) do
        RemoveBlip(blip)
    end
    blips = {}
end

RegisterNetEvent('race:finished')
AddEventHandler('race:finished', function(success)
    ClearAllBlips()
    raceStarted = false

    for _, object in ipairs(createdObjects) do
        if DoesEntityExist(object) then
            DeleteObject(object)
        end
    end

    createdObjects = {}

    if success then
        SendNUIMessage({type="close"})
        NotifyPlayer(Config.Notify['raceover'])
    else
        SendNUIMessage({type="close"})
        NotifyPlayer(Config.Notify['raceovertime'])
    end
end)

RegisterNetEvent('race:disqualified')
AddEventHandler('race:disqualified', function()
    ClearAllBlips()
    raceStarted = false
    NotifyPlayer(Config.Notify['disqualified'])
end)

function DrawTextOnScreen(text, x, y)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextScale(0.0, 0.5)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end