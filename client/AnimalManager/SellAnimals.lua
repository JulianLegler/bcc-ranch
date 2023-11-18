local peds = {}

-------- Function to sell animals -----------
function SellAnimals(animalType, animalCond)
    TriggerEvent('bcc-ranch:ChoreDeadCheck')
    local tables, model
    local spawnCoords = nil

    local ranch = RanchControllerInstance:getRanch(RanchId)
    if not ranch then
        error(string.format("ButcherAnimals() - RanchControllerInstance:getRanch(RanchId) returned nil"))
        return
    end

    local selectAnimalFuncts = {
        ['cows'] = function()
            if ranch.cows_age < Config.RanchSetup.AnimalGrownAge then
                VORPcore.NotifyRightTip(_U("TooYoung"), 4000)
            else
                tables = Config.RanchSetup.RanchAnimalSetup.Cows
                model = 'a_c_cow'
                spawnCoords = ranch.cowcoords
            end
        end,
        ['chickens'] = function()
            if ranch.chickens_age < Config.RanchSetup.AnimalGrownAge then
                VORPcore.NotifyRightTip(_U("TooYoung"), 4000)
            else
                tables = Config.RanchSetup.RanchAnimalSetup.Chickens
                model = 'a_c_chicken_01'
                spawnCoords = ranch.chickencoords
            end
        end,
        ['goats'] = function()
            if ranch.goats_age < Config.RanchSetup.AnimalGrownAge then
                VORPcore.NotifyRightTip(_U("TooYoung"), 4000)
            else
                tables = Config.RanchSetup.RanchAnimalSetup.Goats
                model = 'A_C_Sheep_01'
                spawnCoords = ranch.goatcoords
            end
        end,
        ['pigs'] = function()
            if ranch.pigs_age < Config.RanchSetup.AnimalGrownAge then
                VORPcore.NotifyRightTip(_U("TooYoung"), 4000)
            else
                tables = Config.RanchSetup.RanchAnimalSetup.Pigs
                model = 'a_c_pig_01'
                spawnCoords = ranch.pigcoords
            end
        end
    }

    if selectAnimalFuncts[animalType] then
        selectAnimalFuncts[animalType]()
    end
    if spawnCoords == nil then return end --used to end the sell here if the age is below the needed amount
    local result = ClientRPC.Callback.TriggerAwait('bcc-ranch:setIsHerding', ranch, true)
    if not result then
        print("SellAnimals() - ClientRPC.Callback.TriggerAwait('bcc-ranch:setIsHerding', ranch, true) returned false")
        return
    end

    InMission = true

    --Detecting Closest Sale Barn Setup Credit to vorp_core for this bit of code, and jannings for pointing this out to me
    local finalSaleCoords
    local pl2 = GetEntityCoords(PlayerPedId())
    local closestDistance = math.huge
    for k, v in pairs(Config.SaleLocations) do
        local currentDistance = GetDistanceBetweenCoords(pl2.x, pl2.y, pl2.z, v.Coords.x, v.Coords.y, v.Coords.z, true)

        if currentDistance < closestDistance then
            closestDistance = currentDistance
            finalSaleCoords = v.Coords
        end
    end


    local catch = 0
    repeat
        local createdPed = BccUtils.Ped.CreatePed(model, spawnCoords.x + math.random(1, 5), spawnCoords.y + math.random(1, 5), spawnCoords.z, true, true, false)
        SetBlockingOfNonTemporaryEvents(createdPed, true)
        Citizen.InvokeNative(0x9587913B9E772D29, createdPed, true)
        SetEntityHealth(createdPed, tables.Health, 0)
        table.insert(peds, createdPed)
        catch = catch + 1
    until catch == tables.AmountSpawned
    SetRelAndFollowPlayer(peds)
    VORPcore.NotifyRightTip(_U("LeadAnimalsToSale"), 4000)
    BccUtils.Misc.SetGps(finalSaleCoords.x, finalSaleCoords.y, finalSaleCoords.z)

    local animalsNear, doOnce = false, false
    local createdPed, createdPed2
    while true do
        Wait(50)
        for k, v in pairs(peds) do
            local cp = GetEntityCoords(v)
            if GetDistanceBetweenCoords(cp.x, cp.y, cp.z, finalSaleCoords.x, finalSaleCoords.y, finalSaleCoords.z, true) < 15 then
                animalsNear = true
            else
                animalsNear = false
            end
            if IsEntityDead(v) then
                catch = catch - 1
            end
        end
        if catch == 0 or PlayerDead == true then break end

        local plc = GetEntityCoords(PlayerPedId())
        local dist = GetDistanceBetweenCoords(plc.x, plc.y, plc.z, finalSaleCoords.x, finalSaleCoords.y, finalSaleCoords.z, true)
        if dist < 15 and animalsNear == true then
            if animalCond > tables.MaxCondition then
                animalCond = tables.MaxCondition
            end
            local gradient = (tables.MaxConditionPay - tables.BasePay) / tables.MaxCondition
            local pay = tables.BasePay + gradient * animalCond

            -- Adjust for the case where catch is not equal to tables.AmountSpawned
            if catch ~= tables.AmountSpawned then
                pay = tables.LowPay
            end
            TriggerServerEvent('bcc-ranch:AnimalsSoldHandler', pay, animalType, RanchId)
            VORPcore.NotifyRightTip(_U("AnimalsSold") .. " " .. tostring(pay) .. "$", 4000) break
        elseif dist < 400 and doOnce == false then
            doOnce = true
            if Config.RanchSetup.WolfAttacks then
                if math.random(1, 4) == 1 or 2 then
                    createdPed = BccUtils.Ped.CreatePed('A_C_Wolf', plc.x + math.random(25, 50), plc.y + math.random(25, 50), plc.z, true, true, false)
                    createdPed2 = BccUtils.Ped.CreatePed('A_C_Wolf', plc.x + math.random(25, 50), plc.y + math.random(25, 50), plc.z, true, true, false)
                    Citizen.InvokeNative(0x23f74c2fda6e7c61, 953018525, createdPed)
                    Citizen.InvokeNative(0x23f74c2fda6e7c61, 953018525, createdPed2)
                    TaskCombatPed(createdPed, PlayerPedId())
                    TaskCombatPed(createdPed2, PlayerPedId())
                end
            end
        end
    end
    ClearGpsMultiRoute()
    if PlayerDead == true or catch == 0 then
        if doonce then
            DeletePed(createdPed)
            DeletePed(createdPed2)
        end
        VORPcore.NotifyRightTip(_U("PlayerDead"), 4000)
    end
    TriggerServerEvent('bcc-ranch:PutAnimalsBack',RanchId)
    DelPedsForTable(peds)
    InMission = false
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        DelPedsForTable(peds)
        peds = {}
    end
end)