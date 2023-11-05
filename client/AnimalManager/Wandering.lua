------------ Animals Wandering Setup --------------
local cows, chickens, goats, pigs = {}, {}, {}, {}



RegisterNetEvent('bcc-ranch:CowsWander', function(ranchId, ranchCoords, animalCoords)
    --print("CowsWander for " .. ranchId)
    --print(json.encode(ranchCoords))
    --print(json.encode(animalCoords))
    local ranchCoords = json.decode(ranchCoords)
    local animalCoords = json.decode(animalCoords)
    --print("CowsWander ranchCoords: " .. ranchCoords.x .. ", " .. ranchCoords.y .. ", " .. ranchCoords.z)
    --print("CowsWander animalCoords: " .. animalCoords.x .. ", " .. animalCoords.y .. ", " .. animalCoords.z)
    if not cows[ranchId] then
        cows[ranchId] = {}
    end
    local deleted = true
	local spawnCoords -- added by Little Creek
	spawnCoords = animalCoords -- added by Little Creek
    if spawnCoords == nil then
        spawnCoords = ranchCoords
    end
    if spawnCoords ~= 'none' then
        -- spawnWanderingAnimals('cows')
        while true do
            --print("CowsWander loop for " .. ranchId)
            --print("CowsWander loop spawnCoords: " .. spawnCoords.x .. ", " .. spawnCoords.y .. ", " .. spawnCoords.z)
            local pl = GetEntityCoords(PlayerPedId())
            local dist = GetDistanceBetweenCoords(pl.x, pl.y, pl.z, spawnCoords.x, spawnCoords.y, spawnCoords.z, false)
            --print("CowsWander loop dist: " .. dist)
            --print("CowsWander loop deleted: " .. tostring(deleted))
            if dist > 250 and not deleted then
                print("Cows are gone")
                deleted = true
                DelPedsForTable(cows[ranchId])
            elseif dist <= 250 and deleted then
                print("Cows are back")
                deleted = false
                spawnWanderingAnimals('cows', ranchId, animalCoords)
            end
            Wait(10000)
        end
    end
end)

RegisterNetEvent('bcc-ranch:ChickensWander', function(ranchId, ranchCoords, animalCoords)
    if not chickens[ranchId] then
        chickens[ranchId] = {}
    end
    local deleted = true
	local spawnCoords -- added by Little Creek
	spawnCoords = animalCoords -- added by Little Creek
    if spawnCoords == nil then
        spawnCoords = ranchCoords
    end
    if spawnCoords ~= 'none' then
        while true do
            local pl = GetEntityCoords(PlayerPedId())
            local dist = GetDistanceBetweenCoords(pl.x, pl.y, pl.z, spawnCoords.x, spawnCoords.y, spawnCoords.z, false)
            if dist > 250 and not deleted then
                print("Chickens are gone")
                deleted = true
                DelPedsForTable(chickens[ranchId])
            elseif dist <= 250 and deleted then
                print("Chickens are back")
                deleted = false
                spawnWanderingAnimals('chickens', ranchId, animalCoords)
            end
            Wait(10000)
        end
    end
end)

RegisterNetEvent('bcc-ranch:GoatsWander', function(ranchId, ranchCoords, animalCoords)
    if not goats[ranchId] then
        goats[ranchId] = {}
    end
    local deleted = true
	local spawnCoords -- added by Little Creek
	spawnCoords = animalCoords -- added by Little Creek
    if spawnCoords == nil then
        spawnCoords = ranchCoords
    end
    if spawnCoords ~= 'none' then
        while true do
            local pl = GetEntityCoords(PlayerPedId())
            local dist = GetDistanceBetweenCoords(pl.x, pl.y, pl.z, spawnCoords.x, spawnCoords.y, spawnCoords.z, false)
            if dist > 250 and not deleted then
                print("Goats are gone")
                deleted = true
                DelPedsForTable(goats[ranchId])
            elseif dist <= 250 and deleted then
                print("Goats are back")
                deleted = false
                spawnWanderingAnimals('goats', ranchId, animalCoords)
            end
            Wait(10000)
        end
    end
end)

RegisterNetEvent('bcc-ranch:PigsWander', function(ranchId, ranchCoords, animalCoords)
    if not pigs[ranchId] then
        pigs[ranchId] = {}
    end
    local deleted = true
	local spawnCoords -- added by Little Creek
	spawnCoords = animalCoords -- added by Little Creek
    if spawnCoords == nil then
        spawnCoords = ranchCoords
    end
    if spawnCoords ~= 'none' then
        while true do
            local pl = GetEntityCoords(PlayerPedId())
            local dist = GetDistanceBetweenCoords(pl.x, pl.y, pl.z, spawnCoords.x, spawnCoords.y, spawnCoords.z, false)
            if dist > 250 and not deleted then
                print("Pigs are gone")
                deleted = true
                DelPedsForTable(pigs[ranchId])
            elseif dist <= 250 and deleted then
                print("Pigs are back")
                deleted = false
                spawnWanderingAnimals('pigs', ranchId, animalCoords)
            end
            Wait(10000)
        end
    end
end)

function spawnWanderingAnimals(animalType, ranchId, animalCoords)
    if #cows[ranchId] > 0 and #chickens[ranchId] > 0 and #goats[ranchId] > 0 and #pigs[ranchId] > 0 then
        return
    end
    local repAmount = 0
	local spawnCoords
    local selectedAnimal = {
        ['cows'] = function()
            spawnCoords = animalCoords -- added by Little Creek
            local model = joaat('a_c_cow')
            repeat
                repAmount = repAmount + 1
                local createdPed = spawnpedsroam(spawnCoords, model, Config.RanchSetup.RanchAnimalSetup.Cows.RoamingRadius)
                table.insert(cows[ranchId], createdPed)
            until repAmount >= Config.RanchSetup.RanchAnimalSetup.Cows.AmountSpawned
        end,
        ['chickens'] = function()
            spawnCoords = animalCoords -- added by Little Creek
            local model = joaat('a_c_chicken_01')
            repeat
                repAmount = repAmount + 1
                local createdPed = spawnpedsroam(spawnCoords, model, Config.RanchSetup.RanchAnimalSetup.Chickens.RoamingRadius)
                table.insert(chickens[ranchId], createdPed)
            until repAmount >= Config.RanchSetup.RanchAnimalSetup.Chickens.AmountSpawned
        end,
        ['goats'] = function()
            spawnCoords = animalCoords -- added by Little Creek
            local model = joaat('A_C_Sheep_01')
            repeat
                repAmount = repAmount + 1
                local createdPed = spawnpedsroam(spawnCoords, model, Config.RanchSetup.RanchAnimalSetup.Goats.RoamingRadius)
                table.insert(goats[ranchId], createdPed)
            until repAmount >= Config.RanchSetup.RanchAnimalSetup.Goats.AmountSpawned
        end,
        ['pigs'] = function()
            spawnCoords = animalCoords -- added by Little Creek
            local model = joaat('a_c_pig_01')
            repeat
                repAmount = repAmount + 1
                local createdPed = spawnpedsroam(spawnCoords, model, Config.RanchSetup.RanchAnimalSetup.Pigs.RoamingRadius)
                table.insert(pigs[ranchId], createdPed)
            until repAmount >= Config.RanchSetup.RanchAnimalSetup.Pigs.AmountSpawned
        end
    }

    if selectedAnimal[animalType] then
        selectedAnimal[animalType]()
    end
end

function spawnpedsroam(coords, model, roamDist)
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

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end
    for k, v in pairs(cows) do
        DelPedsForTable(v)
    end
    for k, v in pairs(chickens) do
        DelPedsForTable(v)
    end
    for k, v in pairs(goats) do
        DelPedsForTable(v)
    end
    for k, v in pairs(pigs) do
        DelPedsForTable(v)
    end

    
  end)