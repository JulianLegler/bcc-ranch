------------ Animals Wandering Setup --------------
local cows, chickens, goats, pigs = {}, {}, {}, {}
local waitTicksBetweenWanderingDistanceChecks = 10000
local spawnDistanceForWanderingAnimals = 250
local maxPedScale = 1.2
local minPedScale = 0.7

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
    local animalAge = 0
    if animalType == 'Cows' then
        animalSpawn = ranch.cowcoords
        animalAge = ranch.cows_age
    elseif animalType == 'Chickens' then
        animalSpawn = ranch.chickencoords
        animalAge = ranch.chickens_age
    elseif animalType == 'Goats' then
        animalSpawn = ranch.goatcoords
        animalAge = ranch.goats_age
    elseif animalType == 'Pigs' then
        animalSpawn = ranch.pigcoords
        animalAge = ranch.pigs_age
    end

    if animalAge > Config.RanchSetup.AnimalGrownAge then
        animalAge = Config.RanchSetup.AnimalGrownAge
    end
 
    local gradient = (maxPedScale - minPedScale) / Config.RanchSetup.AnimalGrownAge
    local animalSize = minPedScale + gradient * animalAge

    repeat
        local createdPed = spawnRoamingPed(animalSpawn, Config.RanchSetup.RanchAnimalSetup[animalType].Model, Config.RanchSetup.RanchAnimalSetup[animalType].RoamingRadius, animalSize)
        ranch:addWanderingAnimalHandler(animalType, createdPed)
        numberAnimalsSpawned = numberAnimalsSpawned + 1
    until numberAnimalsSpawned >= Config.RanchSetup.RanchAnimalSetup[animalType].AmountSpawned
end

spawnRoamingPed = function(coords, model, roamDist, size)
    if coords == nil then
        coords = RanchCoords
    end
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(100)
    end
    -- local spawnCoords = { x = RanchCoords.x + math.random(10, 20), y = RanchCoords.y + math.random(10, 30), z = RanchCoords.z }
    local spawnCoords = { x = coords.x + math.random(1, 1), y = coords.y + math.random(1, 1), z = coords.z } -- now spawning near their set location instead of the Ranch changed by Little Creek
    local createdPed = CreatePed(model, spawnCoords.x, spawnCoords.y, spawnCoords.z, 50, false, false)
    Citizen.InvokeNative(0x283978A15512B2FE, createdPed, true)
    Citizen.InvokeNative(0x9587913B9E772D29, createdPed, true)
    Citizen.InvokeNative(0xE054346CA3A0F315, createdPed, spawnCoords.x, spawnCoords.y, spawnCoords.z, roamDist, tonumber(1077936128), tonumber(1086324736), 1)
    SetPedScale(createdPed, size)
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

local function updateAnimalScale(animalType, ranch)
    local size = ranch:getAnimalScale(animalType)
    print(string.format('[Wandering] Updating animal scale for %s to %s', animalType, size))
    if not ranch.wanderingAnimals or not ranch.wanderingAnimals[animalType] then
        return
    end
    for _, animalHandle in pairs(ranch.wanderingAnimals[animalType]) do
        if DoesEntityExist(animalHandle) then
            SetPedScale(animalHandle, size)
        end
    end
end
AddEventHandler('bcc-ranch:ranchDataChangedClient', function (ranchid)
    local ranch = RanchControllerInstance:getRanch(ranchid)
    if ranch then
        updateAnimalScale('Cows', ranch)
        updateAnimalScale('Chickens', ranch)
        updateAnimalScale('Goats', ranch)
        updateAnimalScale('Pigs', ranch)
    else
        print(string.format('[Wandering] Ranch %s not found', ranchid))
    end
end)


initWanderingAnimals()