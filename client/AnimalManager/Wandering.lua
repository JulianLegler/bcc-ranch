------------ Animals Wandering Setup --------------
local cows, chickens, goats, pigs = {}, {}, {}, {}
local waitTicksBetweenWanderingDistanceChecks = 10000
local spawnDistanceForWanderingAnimals = 250

local handleWanderingAnimals
local despawnWanderingAnimals
local spawnWanderingAnimals
local spawnRoamingPed

local function initWanderingAnimals()
    while not RanchControllerInstance do
        Wait(100)
    end
    for _, ranch in pairs(RanchControllerInstance:getListOfRanches()) do
        -- print(json.encode(ranch))
        handleWanderingAnimals(ranch)
    end
end

--- Handle wandering animals for a ranch
---@param ranch RanchModel
handleWanderingAnimals = function (ranch)
    Citizen.CreateThread(function ()
        while true do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local ranchCoords = ranch.ranchcoords -- assumption: animal spawns are near the ranch
            local distance = #(playerCoords - ranchCoords)
            if distance < spawnDistanceForWanderingAnimals then
                print(string.format('Player is within %s meters of ranch %s, spawning wandering animals. cows: %s, chickens: %s, goats: %s, pigs: %s', distance, ranch.ranchname, ranch.cows, ranch.chickens, ranch.goats, ranch.pigs))
                if ranch.cows then
                    spawnWanderingAnimals('Cows', ranch)
                else
                    despawnWanderingAnimals('Cows', ranch)
                end
                if ranch.chickens then
                    spawnWanderingAnimals('Chickens', ranch)
                else
                    despawnWanderingAnimals('Chickens', ranch)
                end
                if ranch.goats then
                    spawnWanderingAnimals('Goats', ranch)
                else
                    despawnWanderingAnimals('Goats', ranch)
                end
                if ranch.pigs then
                    spawnWanderingAnimals('Pigs', ranch)
                else
                    despawnWanderingAnimals('Pigs', ranch)
                end
            else
                despawnWanderingAnimals('Cows', ranch)
                despawnWanderingAnimals('Chickens', ranch)
                despawnWanderingAnimals('Goats', ranch)
                despawnWanderingAnimals('Pigs', ranch)
            end
            Wait(waitTicksBetweenWanderingDistanceChecks)
        end
    end)
end

spawnWanderingAnimals = function(animalType, ranch)
    if ranch:isWanderingAnimalCurrentlySpawned(animalType) then
        return
    end
    local numberAnimalsSpawned = 0
    local animalSpawn = ranch.ranchcoords
    if animalType == 'Cows' then
        animalSpawn = ranch.cowcoords
    elseif animalType == 'Chickens' then
        animalSpawn = ranch.chickencoords
    elseif animalType == 'Goats' then
        animalSpawn = ranch.goatcoords
    elseif animalType == 'Pigs' then
        animalSpawn = ranch.pigcoords
    end
    repeat
        local createdPed = spawnRoamingPed(animalSpawn, Config.RanchSetup.RanchAnimalSetup[animalType].Model, Config.RanchSetup.RanchAnimalSetup[animalType].RoamingRadius)
        ranch:addWanderingAnimalHandler(animalType, createdPed)
        numberAnimalsSpawned = numberAnimalsSpawned + 1
    until numberAnimalsSpawned >= Config.RanchSetup.RanchAnimalSetup[animalType].AmountSpawned
end

spawnRoamingPed = function(coords, model, roamDist)
    if coords == nil then
        coords = RanchCoords
    end
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(100)
    end
    -- local spawnCoords = { x = RanchCoords.x + math.random(10, 20), y = RanchCoords.y + math.random(10, 30), z = RanchCoords.z }
    local spawnCoords = { x = coords.x + math.random(1, 5), y = coords.y + math.random(1, 5), z = coords.z } -- now spawning near their set location instead of the Ranch changed by Little Creek
    local createdPed = CreatePed(model, spawnCoords.x, spawnCoords.y, spawnCoords.z, 50, false, false)
    Citizen.InvokeNative(0x283978A15512B2FE, createdPed, true)
    Citizen.InvokeNative(0x9587913B9E772D29, createdPed, true)
    Citizen.InvokeNative(0xE054346CA3A0F315, createdPed, spawnCoords.x, spawnCoords.y, spawnCoords.z, roamDist, tonumber(1077936128), tonumber(1086324736), 1)
    relationshipsetup(createdPed, 1)
    SetBlockingOfNonTemporaryEvents(createdPed, true)
    return createdPed
end

despawnWanderingAnimals = function(animalType, ranch)
    if not ranch:isWanderingAnimalCurrentlySpawned(animalType) then
        return
    end
    for _, wanderingAnimal in pairs(ranch.wanderingAnimals[animalType]) do
        if DoesEntityExist(wanderingAnimal) then
            DeleteEntity(wanderingAnimal)
        end
    end
    ranch:deleteWanderingAnimalHandler(animalType)
end

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end
    for _, ranch in pairs(RanchControllerInstance:getListOfRanches()) do
        despawnWanderingAnimals('Cows', ranch)
        despawnWanderingAnimals('Chickens', ranch)
        despawnWanderingAnimals('Goats', ranch)
        despawnWanderingAnimals('Pigs', ranch)
    end
  end)


  initWanderingAnimals()