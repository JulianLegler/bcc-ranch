---------- Pulling Essentials -------------
VORPcore = {} --Pulls vorp core
TriggerEvent("getCore", function(core)
    VORPcore = core
end)
VORPInv = {}
VORPInv = exports.vorp_inventory:vorp_inventoryApi()
BccUtils = exports['bcc-utils'].initiate()

ServerRPC = exports.vorp_core:ServerRpcCall() --[[@as ServerRPC]] -- for intellisense

ServerRanchControllerInstance = nil --[[@type ServerRanchController]]

Citizen.CreateThread(function()
    while not ServerRanchControllerInstance do
        ServerRanchControllerInstance = ServerRanchController.new()
        Wait(2000)
    end
end)

------ Commands Admin Check --------
RegisterServerEvent('bcc-ranch:AdminCheck', function(nextEvent, servEvent)
    local _source = source
    local character = VORPcore.getUser(_source).getUsedCharacter
    for k, v in pairs(Config.AdminSteamIds) do
        if character.identifier == v.steamid then
            if servEvent then
                TriggerEvent(nextEvent)
            else
                TriggerClientEvent(nextEvent, _source)
            end
        end
    end
end)

ServerRPC.Callback.Register('bcc-ranch:AdminCheckRPC', function(source, cb)
    local _source = source
    local character = VORPcore.getUser(_source).getUsedCharacter
    for k, v in pairs(Config.AdminSteamIds) do
        if character.identifier == v.steamid then
            cb(true)
            return
        end
    end
    cb(false)
end)

CreateThread(function() --Tax handling
    if not Config.UseTax then return end
    local date = os.date("%d")
    local result = MySQL.query.await("SELECT * FROM ranch")
    if tonumber(date) == tonumber(Config.TaxDay) then --for some reason these have to be tonumbered
        if #result > 0 then
            for k, v in pairs(result) do
                local param = { ['ranchid'] = v.ranchid, ['taxamount'] = tonumber(v.taxamount) }
                if v.taxescollected == 'false' then
                    if tonumber(v.ledger) < tonumber(v.taxamount) then
                        exports.oxmysql:execute("UPDATE ranch SET charidentifier=0 WHERE ranchid=@ranchid", param)
                        BccUtils.Discord.sendMessage(Config.Webhooks.Taxes.WebhookLink,
                            _U("ranchIdWebhook") .. tostring(v.ranchid), _U("taxPaidFailedWebhook"))
                    else
                        exports.oxmysql:execute(
                            "UPDATE ranch SET ledger=ledger-@taxamount, taxescollected='true' WHERE ranchid=@ranchid",
                            param)
                        BccUtils.Discord.sendMessage(Config.Webhooks.Taxes.WebhookLink,
                            _U("ranchIdWebhook") .. tostring(v.ranchid), _U("taxPaidWebhook"))
                    end
                end
            end
        end
    elseif tonumber(date) == tonumber(Config.TaxResetDay) then
        if #result > 0 then
            for k, v in pairs(result) do
                local param = { ['ranchid'] = v.ranchid }
                exports.oxmysql:execute("UPDATE ranch SET taxes_collected='false' WHERE ranchid=@ranchid", param)
            end
        end
    end
end)

--------- Check is herding --------------
RegisterServerEvent('bcc-ranch:CheckAnimalsOut', function(ranchId)
    local _source = source

    local ranch = ServerRanchControllerInstance:getRanch(ranchId)

    if not ranch then
        print(string.format("['bcc-ranch:CheckAnimalsOut'] Ranch %s not found", ranchId))
        return
    end
    
    if ranch.isherding then
        TriggerClientEvent('bcc-ranch:AnimalsOutCl', _source, ranch.isherding)
    else
        TriggerClientEvent('bcc-ranch:AnimalsOutCl', _source, false)
        ranch:setIsHerding(true)
    end
end)

--------- Put Animals Back --------------
RegisterServerEvent('bcc-ranch:PutAnimalsBack', function(ranchId)
    local ranch = ServerRanchControllerInstance:getRanch(ranchId)

    if not ranch then
        print(string.format("['bcc-ranch:PutAnimalsBack'] Ranch %s not found", ranchId))
        return
    end

    ranch:setIsHerding(false)
end)

--------- Open Inv Handler --------------
RegisterServerEvent('bcc-ranch:OpenInv', function(ranchid)
    local _source = source
    VORPInv.OpenInv(_source, 'Player_' .. ranchid .. '_bcc-ranchinv')
end)

-------- Adding Items ----------
RegisterServerEvent('bcc-ranch:AddItem', function(item, amount)
    local _source = source
    VORPInv.addItem(_source, item, amount)
end)

------ Create Ranch Db Handler -----
RegisterServerEvent('bcc-ranch:InsertCreatedRanchIntoDB',
    function(ranchName, ranchRadius, ownerStaticId, coords, taxes, ownerSource)
        local _source = source
        local param = {
            ['ranchname'] = ranchName,
            ['ranch_radius_limit'] = ranchRadius,
            ['charidentifier'] = ownerStaticId,
            ['ranchcoords'] = json.encode(coords),
            ['taxamount'] = taxes
        }
        local result = MySQL.query.await("SELECT * FROM ranch WHERE charidentifier=@charidentifier", param)
        if #result >= 1 then
            VORPcore.NotifyRightTip(_source, _U("AlreadyOwnRanch"), 4000)
        else
            -- Create ranch and get created ranchid
            local create_ranch_query = "INSERT INTO ranch ( `charidentifier`,`ranchcoords`,`ranchname`,`ranch_radius_limit` ,`taxamount`) VALUES ( @charidentifier,@ranchcoords,@ranchname,@ranch_radius_limit,@taxamount )"
            local ranchid = MySQL.insert.await(create_ranch_query, param)
                
            if not Config.useCharacterJob then
                -- Update owners ranchid in characters
                local update_characters_query = "UPDATE characters SET ranchid=@ranchid WHERE charidentifier=@charidentifier"
                local update_characters_param = {
                    ranchid = ranchid,
                    charidentifier = ownerStaticId
                }
                
                MySQL.query.await(update_characters_query, update_characters_param)
            end
            
            local character = VORPcore.getUser(_source).getUsedCharacter
            VORPcore.NotifyRightTip(_source, _U("RanchMade"), 4000)
            BccUtils.Discord.sendMessage(Config.Webhooks.RanchCreation.WebhookLink, 'BCC Ranch',
                'https://gamespot.com/a/uploads/original/1179/11799911/3383938-duck.jpg',
                Config.Webhooks.RanchCreation.TitleText .. tostring(character.charIdentifier),
                Config.Webhooks.RanchCreation.Text .. tostring(ownerStaticId))
            TriggerEvent('bcc-ranch:CheckIfRanchIsOwned', ownerSource)
        end
    end)

-------- Chore Coord Insertion(Citas pr) -------
RegisterServerEvent('bcc-ranch:ChoreInsertIntoDB', function(coords, RanchId, type)
    local _source = source

    local databaseUpdate = {
        ['shovehaycoords'] = function()
            local param = { ['shovehaycoords'] = json.encode(coords), ['ranchid'] = RanchId }
            exports.oxmysql:execute("UPDATE ranch SET shovehaycoords = @shovehaycoords WHERE ranchid=@ranchid", param)
            VORPcore.NotifyRightTip(_source, _U("ShoveHaySave"), 4000)
        end,
        ['wateranimalcoords'] = function()
            local param = { ['wateranimalcoords'] = json.encode(coords), ['ranchid'] = RanchId }
            exports.oxmysql:execute("UPDATE ranch SET wateranimalcoords = @wateranimalcoords WHERE ranchid=@ranchid",
                param)
            VORPcore.NotifyRightTip(_source, _U("WaterAnimalSave"), 4000)
        end,
        ['repairtroughcoords'] = function()
            local param = { ['repairtroughcoords'] = json.encode(coords), ['ranchid'] = RanchId }
            exports.oxmysql:execute("UPDATE ranch SET repairtroughcoords = @repairtroughcoords WHERE ranchid=@ranchid",
                param)
            VORPcore.NotifyRightTip(_source, _U("RepairTroughSave"), 4000)
        end,
        ['scooppoopcoords'] = function()
            local param = { ['scooppoopcoords'] = json.encode(coords), ['ranchid'] = RanchId }
            exports.oxmysql:execute("UPDATE ranch SET scooppoopcoords = @scooppoopcoords WHERE ranchid=@ranchid", param)
            VORPcore.NotifyRightTip(_source, _U("ScoopPoopSave"), 4000)
        end
    }

    if databaseUpdate[type] then
        databaseUpdate[type]()
    end
end)

RegisterServerEvent('bcc-ranch:AnimalLocationDbInserts', function(coords, RanchId, type)
    local _source = source

    local databaseUpdate = { --utilizing good indexing to trigger functions instead of using elseif more optimal skips straight to the funt instead of going through all the elseif statements thanks to apo for the tip
        ['herdcoords'] = function()
            local param = { ['herdlocation'] = json.encode(coords), ['ranchid'] = RanchId }
            exports.oxmysql:execute("UPDATE ranch SET herdlocation = @herdlocation WHERE ranchid=@ranchid", param)
            VORPcore.NotifyRightTip(_source, _U("Coordsset"), 4000)
        end,
        ['pigcoords'] = function()
            local param = { ['pigcoords'] = json.encode(coords), ['ranchid'] = RanchId }
            exports.oxmysql:execute("UPDATE ranch SET pigcoords = @pigcoords WHERE ranchid=@ranchid", param)
            VORPcore.NotifyRightTip(_source, _U("Coordsset"), 4000)
        end,
        ['cowcoords'] = function()
            local param = { ['cowcoords'] = json.encode(coords), ['ranchid'] = RanchId }
            exports.oxmysql:execute("UPDATE ranch SET cowcoords = @cowcoords WHERE ranchid=@ranchid", param)
            VORPcore.NotifyRightTip(_source, _U("Coordsset"), 4000)
        end,
        ['goatcoords'] = function()
            local param = { ['goatcoords'] = json.encode(coords), ['ranchid'] = RanchId }
            exports.oxmysql:execute("UPDATE ranch SET goatcoords = @goatcoords WHERE ranchid=@ranchid", param)
            VORPcore.NotifyRightTip(_source, _U("Coordsset"), 4000)
        end,
        ['chickencoords'] = function()
            local param = { ['chickencoords'] = json.encode(coords), ['ranchid'] = RanchId }
            exports.oxmysql:execute("UPDATE ranch SET chickencoords = @chickencoords WHERE ranchid=@ranchid", param)
            VORPcore.NotifyRightTip(_source, _U("Coordsset"), 4000)
        end,
        ['feedwagoncoords'] = function()
            local param = { ['wagonfeedcoords'] = json.encode(coords), ['ranchid'] = RanchId }
            exports.oxmysql:execute("UPDATE ranch SET wagonfeedcoords = @wagonfeedcoords WHERE ranchid=@ranchid", param)
            VORPcore.NotifyRightTip(_source, _U("Coordsset"), 4000)
        end
    }

    if databaseUpdate[type] then
        databaseUpdate[type]()
    end
end)
---- (End Citas pr) -----

RegisterServerEvent('bcc-ranch:CheckisOwner', function()
    local _source = source
    local character = VORPcore.getUser(_source).getUsedCharacter
    local result = exports['bcc-ranch']:CheckIfRanchIsOwned(character.charIdentifier)
    TriggerClientEvent('bcc-ranch:IsOwned', _source, result)
end)

------ Ledger Area ------
RegisterServerEvent('bcc-ranch:GetLedger', function(ranchid)
    local _source = source
    local param = { ['ranchid'] = ranchid }

    local result = MySQL.query.await("SELECT ledger FROM ranch WHERE ranchid=@ranchid", param)
    if #result > 0 then
        TriggerClientEvent('bcc-ranch:LedgerMenu', _source, result[1].ledger)
    end
end)

RegisterServerEvent('bcc-ranch:AffectLedger', function(ranchid, type, amount)
    local _source = source
    local character = VORPcore.getUser(_source).getUsedCharacter
    local param = { ['ranchid'] = ranchid, ['amount'] = amount }
    local result = MySQL.query.await("SELECT ledger FROM ranch WHERE ranchid=@ranchid", param)
    if #result > 0 then
        if type == 'withdraw' then
            if tonumber(amount) <= tonumber(result[1].ledger) then
                exports.oxmysql:execute("UPDATE ranch SET ledger= ledger-@amount WHERE ranchid=@ranchid", param)
                character.addCurrency(0, amount)
                VORPcore.NotifyRightTip(_source, _U("TookLedger") .. amount .. _U("FromtheLedger"), 4000)
            else
                VORPcore.NotifyRightTip(_source, _U("Notenough"), 4000)
            end
        else
            exports.oxmysql:execute("UPDATE ranch SET ledger= ledger+@amount WHERE ranchid=@ranchid", param)
            character.removeCurrency(0, amount)
            VORPcore.NotifyRightTip(_source, _U("PutLedger") .. amount .. _U("IntheLedger"), 4000)
        end
    end
end)

----- Checking If Character Owns a ranch -----
RegisterServerEvent('bcc-ranch:CheckIfRanchIsOwned')
AddEventHandler('bcc-ranch:CheckIfRanchIsOwned',
    function(ownerSource) --Done this way so can be called server or client side
        local _source = nil
        if ownerSource ~= nil or false then
            _source = ownerSource
        else
            _source = source
        end
        local character = VORPcore.getUser(_source).getUsedCharacter
        local param = { ['charidentifier'] = character.charIdentifier }
        local result = MySQL.query.await("SELECT * FROM ranch WHERE charidentifier=@charidentifier", param)
        if #result > 0 then
            VORPInv.removeInventory('Player_' .. result[1].ranchid .. '_bcc-ranchinv')
            Wait(50)
            VORPInv.registerInventory('Player_' .. result[1].ranchid .. '_bcc-ranchinv', Config.RanchSetup.InvName,
                Config.RanchSetup.InvLimit, true, true, true)
            TriggerClientEvent('bcc-ranch:HasRanchHandler', _source, result[1])
        end
    end)

--------- Employee Area -----------
RegisterServerEvent('bcc-ranch:CheckIfInRanch')
AddEventHandler('bcc-ranch:CheckIfInRanch', function(employeeSource)
    local _source = nil
    if employeeSource ~= nil or false then
        _source = employeeSource
    else
        _source = source
    end
    local character = VORPcore.getUser(_source).getUsedCharacter
    local param = {}
    local sqlQuery = ""
    if Config.useCharacterJob then
        param = { ['job'] = character.job }
        sqlQuery = "SELECT ranchid FROM ranch WHERE job=@job"
    else
        param = { ['charidentifier'] = character.charIdentifier }
        sqlQuery = "SELECT ranchid FROM characters WHERE charidentifier=@charidentifier"
    end
    local result = MySQL.query.await(sqlQuery, param)
    if #result > 0 then
        if result[1].ranchid ~= nil and 0 then
            local ranchid = result[1].ranchid
            local param2 = { ["ranchid"] = ranchid }
            exports.oxmysql:execute("SELECT * FROM ranch WHERE ranchid=@ranchid", param2, function(result2)
                if result2[1] then
                    if result2[1].ranchid == ranchid then
                        VORPInv.removeInventory('Player_' .. result[1].ranchid .. '_bcc-ranchinv')
                        Wait(50)
                        VORPInv.registerInventory('Player_' .. result[1].ranchid .. '_bcc-ranchinv',
                            Config.RanchSetup.InvName, Config.RanchSetup.InvLimit, true, true, true)
                        TriggerClientEvent('bcc-ranch:HasRanchHandler', _source, result2[1])
                    end
                end
            end)
        end
    end
end)

RegisterServerEvent('bcc-ranch:HireEmployee', function(ranchId, charid, employeeSource)
    local param = { ['charidentifier'] = charid, ['ranchid'] = ranchId }
    MySQL.query.await('UPDATE characters SET ranchid=@ranchid WHERE charidentifier=@charidentifier', param)
    TriggerEvent('bcc-ranch:CheckIfInRanch', employeeSource)
    BccUtils.Discord.sendMessage(Config.Webhooks.RanchCreation.WebhookLink, 'BCC Ranch',
        'https://gamespot.com/a/uploads/original/1179/11799911/3383938-duck.jpg',
        Config.Webhooks.RanchCreation.TitleText .. tostring(charid),
        Config.Webhooks.RanchCreation.Text .. tostring(charid))
end)

RegisterServerEvent('bcc-ranch:FireEmployee', function(charid)
    local param = { ['charidentifier'] = charid }
    exports.oxmysql:execute('UPDATE characters SET ranchid=0 WHERE charidentifier=@charidentifier', param)
    BccUtils.Discord.sendMessage(Config.Webhooks.RanchCreation.WebhookLink, 'BCC Ranch',
        'https://gamespot.com/a/uploads/original/1179/11799911/3383938-duck.jpg',
        Config.Webhooks.RanchCreation.TitleText .. tostring(charid),
        Config.Webhooks.RanchCreation.Text .. tostring(charid))
end)

RegisterServerEvent("bcc-ranch:GetEmployeeList")
AddEventHandler("bcc-ranch:GetEmployeeList", function(ranchid)
    local _source = source
    local result = MySQL.query.await(
        "SELECT firstname, lastname, charidentifier FROM characters WHERE ranchid = @ranchid", { ["ranchid"] = ranchid })
    TriggerClientEvent('bcc-ranch:ViewEmployeeMenu', _source, result)
end)

---- Event To Check for Ranchcondition For chores ----
RegisterServerEvent('bcc-ranch:ChoreCheckRanchCondition', function(ranchid, chore)
    local _source = source
    local param = { ['ranchid'] = ranchid }
    local result = MySQL.query.await("SELECT ranchCondition FROM ranch WHERE ranchid=@ranchid", param)
    if #result > 0 then
        if result[1].ranchCondition >= 100 then
            VORPcore.NotifyRightTip(_source, _U("ConditionMax"), 4000)
        else
            TriggerEvent('bcc-ranch:ChoreCooldownSV',_source, ranchid, nil, chore, nil)
        end
    end
end)

ServerRPC.Callback.Register('bcc-ranch:doChore', function( source, cb, ranchId, chore)
    local _source = source
    local ranch = ServerRanchControllerInstance:getRanch(ranchId)
    if not ranch then
        cb(false)
        return
    end
    local cooldownController = ranch:getCooldownController()
    local isOnCooldown = cooldownController:isRanchInteractionOnCooldown(chore)

    if isOnCooldown then
        VORPcore.NotifyRightTip(_source, _U("TooSoon"), 4000)
        print(string.format("Player %s tried to do chore %s too soon", _source, chore))
        cb(false)
        return 
    end

    local ranch = ServerRanchControllerInstance:getRanch(ranchId)
    if not ranch then
        cb(false)
        return
    end


    if ranch.ranchCondition >= 100 then
        VORPcore.NotifyRightTip(_source, _U("ConditionMax"), 4000)
        cb(false)
        return
    end
    
    cooldownController:startRanchInteractionCooldown(chore)
    TriggerClientEvent('bcc-ranch:startChore', _source, chore)

end)

---- Event To Increase Ranch Condition Upon Chore Completion -----
RegisterServerEvent('bcc-ranch:RanchConditionIncrease', function(increaseAmount, ranchid)
    local ranch = ServerRanchControllerInstance:getRanch(ranchid)
    if not ranch then
        return
    end
    local result = ranch:increaseRanchCondition(increaseAmount)

    if not result then
        VORPcore.NotifyRightTip(_source, "DB Update error. Desync state imminent.", 4000)
    end
end)

---- Event To Display Ranch Condition To Player -----
RegisterServerEvent('bcc-ranch:DisplayRanchCondition', function(ranchid)
    local _source = source
    local ranch = ServerRanchControllerInstance:getRanch(ranchid)
    if not ranch then
        return
    end
    VORPcore.NotifyRightTip(_source, tostring(ranch.ranchCondition), 4000)
end)

---- Buy Animals Event ----
RegisterServerEvent('bcc-ranch:BuyAnimals', function(ranchid, animalType)
    local discord = BccUtils.Discord.setup(Config.Webhooks.AnimalBought.WebhookLink, 'BCC Ranch',
        'https://gamespot.com/a/uploads/original/1179/11799911/3383938-duck.jpg')
    local _source = source
    local character = VORPcore.getUser(_source).getUsedCharacter
    local param = { ['ranchid'] = ranchid }

    local buyAnimalsHandler = {
        ['cows'] = function()
            if character.money >= Config.RanchSetup.RanchAnimalSetup.Cows.Cost then
                local result = MySQL.query.await("SELECT cows FROM ranch WHERE ranchid=@ranchid", param)
                if #result > 0 then
                    if result[1].cows == 'false' then
                        --TriggerEvent('bcc-ranch:IndAnimalAgeStart', 'cows', _source)
                        local ranch = ServerRanchControllerInstance:getRanch(ranchid)
                        if not ranch then
                            VORPcore.NotifyRightTip(_source, _U("Failed"), 4000)
                            return
                        end
                        local result = ranch:setAnimalOwnedState('cows', 'true')
                        if not result then
                            VORPcore.NotifyRightTip(_source, _U("Failed"), 4000)
                            return
                        end
                        AnimalBoughtHandle(Config.RanchSetup.RanchAnimalSetup.Cows.Cost,
                            Config.Webhooks.AnimalBought.TitleText, Config.Webhooks.AnimalBought.DescText,
                            Config.Webhooks.AnimalBought.Cows, _source, ranchid, discord, character)
                    else
                        VORPcore.NotifyRightTip(_source, _U("AlreadyOwnAnimal"), 4000)
                    end
                end
            else
                VORPcore.NotifyRightTip(_source, _U("Notenoughmoney"), 4000)
            end
        end,
        ['pigs'] = function()
            if character.money >= Config.RanchSetup.RanchAnimalSetup.Pigs.Cost then
                local result = MySQL.query.await("SELECT pigs FROM ranch WHERE ranchid=@ranchid", param)
                if #result > 0 then
                    if result[1].pigs == 'false' then
                        --TriggerEvent('bcc-ranch:IndAnimalAgeStart', 'pigs', _source)
                        local ranch = ServerRanchControllerInstance:getRanch(ranchid)
                        if not ranch then
                            VORPcore.NotifyRightTip(_source, _U("Failed"), 4000)
                            return
                        end
                        local result = ranch:setAnimalOwnedState('pigs', 'true')
                        if not result then
                            VORPcore.NotifyRightTip(_source, _U("Failed"), 4000)
                            return
                        end
                        AnimalBoughtHandle(Config.RanchSetup.RanchAnimalSetup.Pigs.Cost,
                            Config.Webhooks.AnimalBought.TitleText, Config.Webhooks.AnimalBought.DescText,
                            Config.Webhooks.AnimalBought.Pigs, _source, ranchid, discord, character)
                    else
                        VORPcore.NotifyRightTip(_source, _U("AlreadyOwnAnimal"), 4000)
                    end
                end
            else
                VORPcore.NotifyRightTip(_source, _U("Notenoughmoney"), 4000)
            end
        end,
        ['goats'] = function()
            if character.money >= Config.RanchSetup.RanchAnimalSetup.Goats.Cost then
                local result = MySQL.query.await("SELECT goats FROM ranch WHERE ranchid=@ranchid", param)
                if #result > 0 then
                    if result[1].goats == 'false' then
                        --TriggerEvent('bcc-ranch:IndAnimalAgeStart', 'goats', _source)
                        local ranch = ServerRanchControllerInstance:getRanch(ranchid)
                        if not ranch then
                            VORPcore.NotifyRightTip(_source, _U("Failed"), 4000)
                            return
                        end
                        local result = ranch:setAnimalOwnedState('goats', 'true')
                        if not result then
                            VORPcore.NotifyRightTip(_source, _U("Failed"), 4000)
                            return
                        end
                        AnimalBoughtHandle(Config.RanchSetup.RanchAnimalSetup.Goats.Cost,
                            Config.Webhooks.AnimalBought.TitleText, Config.Webhooks.AnimalBought.DescText,
                            Config.Webhooks.AnimalBought.Goats, _source, ranchid, discord, character)
                    else
                        VORPcore.NotifyRightTip(_source, _U("AlreadyOwnAnimal"), 4000)
                    end
                end
            else
                VORPcore.NotifyRightTip(_source, _U("Notenoughmoney"), 4000)
            end
        end,
        ['chickens'] = function()
            if character.money >= Config.RanchSetup.RanchAnimalSetup.Chickens.Cost then
                local result = MySQL.query.await("SELECT chickens FROM ranch WHERE ranchid=@ranchid", param)
                if #result > 0 then
                    if result[1].chickens == 'false' then
                        --TriggerEvent('bcc-ranch:IndAnimalAgeStart', 'chickens', _source)
                        local ranch = ServerRanchControllerInstance:getRanch(ranchid)
                        if not ranch then
                            VORPcore.NotifyRightTip(_source, _U("Failed"), 4000)
                            return
                        end
                        local result = ranch:setAnimalOwnedState('chickens', 'true')
                        if not result then
                            VORPcore.NotifyRightTip(_source, _U("Failed"), 4000)
                            return
                        end
                        AnimalBoughtHandle(Config.RanchSetup.RanchAnimalSetup.Chickens.Cost,
                            Config.Webhooks.AnimalBought.TitleText, Config.Webhooks.AnimalBought.DescText,
                            Config.Webhooks.AnimalBought.Chickens, _source, ranchid, discord, character)
                    else
                        VORPcore.NotifyRightTip(_source, _U("AlreadyOwnAnimal"), 4000)
                    end
                end
            else
                VORPcore.NotifyRightTip(_source, _U("Notenoughmoney"), 4000)
            end
        end
    }

    if buyAnimalsHandler[animalType] then
        buyAnimalsHandler[animalType]()
    end
end)

--Funct for removing money notiying and webhooking
function AnimalBoughtHandle(cost, webhookTitle, webhookDesc, animalWebhookName, _source, ranchid, discord, character)
    character.removeCurrency(0, cost)
    VORPcore.NotifyRightTip(_source, _U("AnimalBought"), 4000)
    discord:sendMessage(webhookTitle .. tostring(ranchid), webhookDesc .. animalWebhookName)
end

---- Event To Check If Animals Are Owned ----
RegisterServerEvent('bcc-ranch:CheckIfAnimalsAreOwned', function(ranchid, animalType)
    local param = { ['ranchid'] = ranchid }
    local eventTriggger, _source = false, source
    local animalCondition, ranchCond
    local result = MySQL.query.await("SELECT * FROM ranch WHERE ranchid=@ranchid", param)
    if #result > 0 then
        ranchCond = result[1].ranchCondition
        local ownedChecks = {
            ['cows'] = function()
                if result[1].cows ~= 'false' then
                    eventTriggger = true
                    animalCondition = result[1].cows_cond
                else
                    VORPcore.NotifyRightTip(_source, _U("AnimalNotOwned"), 4000)
                end
            end,
            ['pigs'] = function()
                if result[1].pigs ~= 'false' then
                    eventTriggger = true
                    animalCondition = result[1].pigs_cond
                else
                    VORPcore.NotifyRightTip(_source, _U("AnimalNotOwned"), 4000)
                end
            end,
            ['chickens'] = function()
                if result[1].chickens ~= 'false' then
                    eventTriggger = true
                    animalCondition = result[1].chickens_cond
                else
                    VORPcore.NotifyRightTip(_source, _U("AnimalNotOwned"), 4000)
                end
            end,
            ['goats'] = function()
                if result[1].goats ~= 'false' then
                    eventTriggger = true
                    animalCondition = result[1].goats_cond
                else
                    VORPcore.NotifyRightTip(_source, _U("AnimalNotOwned"), 4000)
                end
            end
        }

        if ownedChecks[animalType] then
            ownedChecks[animalType]()
        end

        if eventTriggger then
            TriggerClientEvent('bcc-ranch:OwnedAnimalManagerMenu', _source, animalCondition, animalType, ranchCond)
        end
    end
end)

----- Event that will pay player and delete thier animals from db upon sell ------
RegisterServerEvent('bcc-ranch:AnimalsSoldHandler', function(payAmount, animalType, ranchid)
    local ranch = ServerRanchControllerInstance:getRanch(ranchid)
    if not ranch then
        VORPcore.NotifyRightTip(_source, _U("Failed"), 4000)
        return
    end

    local param = { ['ranchid'] = ranchid }
    local discord = BccUtils.Discord.setup(Config.Webhooks.AnimalSold.WebhookLink, 'BCC Ranch',
        'https://i.imgur.com/vLy5jKH.png')
    local ledger

    local result = MySQL.query.await("SELECT * FROM ranch WHERE ranchid=@ranchid", param)
    if #result > 0 then
        ledger = result[1].ledger
        local result = MySQL.Sync.execute("UPDATE ranch SET ledger=@1 WHERE ranchid=@id",
            { ["@id"] = ranchid, ["@1"] = ledger + tonumber(payAmount) })
        if not result then
            VORPcore.NotifyRightTip(_source, _U("Failed"), 4000)
            return
        end
    end

    local soldFuncts = {
        ['cows'] = function()
            discord:sendMessage(Config.Webhooks.AnimalSold.TitleText .. tostring(ranchid),
                Config.Webhooks.AnimalSold.Sold .. Config.Webhooks.AnimalSold.Cows .. tostring(payAmount))
           ranch:setAnimalOwnedState('cows', 'false')
        end,
        ['chickens'] = function()
            discord:sendMessage(Config.Webhooks.AnimalSold.TitleText .. tostring(ranchid),
                Config.Webhooks.AnimalSold.Sold .. Config.Webhooks.AnimalSold.Chickens .. tostring(payAmount))
                ranch:setAnimalOwnedState('chickens', 'false')
        end,
        ['pigs'] = function()
            discord:sendMessage(Config.Webhooks.AnimalSold.TitleText .. tostring(ranchid),
                Config.Webhooks.AnimalSold.Sold .. Config.Webhooks.AnimalSold.Pigs .. tostring(payAmount))
                ranch:setAnimalOwnedState('pigs', 'false')
        end,
        ['goats'] = function()
            discord:sendMessage(Config.Webhooks.AnimalSold.TitleText .. tostring(ranchid),
                Config.Webhooks.AnimalSold.Sold .. Config.Webhooks.AnimalSold.Goats .. tostring(payAmount))
                ranch:setAnimalOwnedState('goats', 'false')
        end
    }

    if soldFuncts[animalType] then
        soldFuncts[animalType]()
    end
end)

------ Raises animal cond upon herd success ------------
RegisterServerEvent('bcc-ranch:AnimalCondIncrease', function(animalType, amounToInc, ranchid)
    local ranch = ServerRanchControllerInstance:getRanch(ranchid)
    if not ranch then
        return
    end

    local result = ranch:increaseAnimalCondition(animalType, amounToInc)

    if not result then
        print(string.format('Failed to increase animal condition for %s at ranch %s', animalType, ranchid))
    end
    
end)

-------- Remove Animals from db after butcher -------
RegisterServerEvent('bcc-ranch:ButcherAnimalHandler', function(animalType, ranchid, table)
    local param = { ['ranchid'] = ranchid }
    local _source = source

    local ButcherFuncts = {
        ['cows'] = function()
            exports.oxmysql:execute(
                'UPDATE ranch SET `cows`="false", `cows_cond`=0, `cows_age`=0 WHERE ranchid=@ranchid', param)
        end,
        ['chickens'] = function()
            exports.oxmysql:execute(
                'UPDATE ranch SET `chickens`="false", `chickens_cond`=0, `chickens_age`=0 WHERE ranchid=@ranchid', param)
        end,
        ['pigs'] = function()
            exports.oxmysql:execute(
                'UPDATE ranch SET `pigs`="false", `pigs_cond`=0, `pigs_age`=0 WHERE ranchid=@ranchid', param)
        end,
        ['goats'] = function()
            exports.oxmysql:execute(
                'UPDATE ranch SET `goats`="false", `goats_cond`=0, `goats_age`=0 WHERE ranchid=@ranchid', param)
        end
    }

    if ButcherFuncts[animalType] then
        ButcherFuncts[animalType]()
    end

    for k, v in pairs(table.ButcherItems) do
        VORPInv.addItem(_source, v.name, v.count)
    end

end)

------ Decrease ranch cond over time ------------
RegisterServerEvent('bcc-ranch:DecranchCondIncrease', function(ranchid)

    local ranch = ServerRanchControllerInstance:getRanch(ranchid)
    if not ranch then
        print('Ranch cond decrease failed for ranch ' .. ranchid)
        VORPcore.NotifyRightTip(_source, "DB Update error. Desync state imminent.", 4000)
        return
    end
    local result = ranch:decreaseRanchCondition(Config.RanchSetup.RanchCondDecreaseAmount )

    if not result then
        print('Ranch cond decrease failed for ranch ' .. ranchid)
        VORPcore.NotifyRightTip(_source, "DB Update error. Desync state imminent.", 4000)
    end
end)

------------- Get Players Function Credit to vorp admin for this ------------------
--get players info list
PlayersTable = {}
RegisterServerEvent('bcc-ranch:GetPlayers')
AddEventHandler('bcc-ranch:GetPlayers', function()
    local _source = source
    local data = {}

    for _, player in ipairs(PlayersTable) do
        local User = VORPcore.getUser(player)
        if User then
            local Character = User.getUsedCharacter                             --get player info

            local playername = Character.firstname .. ' ' .. Character.lastname --player char name

            data[tostring(player)] = {
                serverId = player,
                PlayerName = playername,
                staticid = Character.charIdentifier,
            }
        end
    end
    TriggerClientEvent("bcc-ranch:SendPlayers", _source, data)
end)

-- check if staff is available
RegisterServerEvent("bcc-ranch:getPlayersInfo", function(source)
    local _source = source
    PlayersTable[#PlayersTable + 1] = _source -- add all players
end)

------- Removing Animal From DB -----------
RegisterServerEvent('bcc-ranch:RemoveAnimalFromDB', function(ranchid, animalType)
    local param = { ['ranchid'] = ranchid }

    local removeAnimalFuncts = {
        ['cows'] = function()
            exports.oxmysql:execute(
                'UPDATE ranch SET `cows`="false", `cows_cond`=0, `cows_age`=0 WHERE ranchid=@ranchid', param)
        end,
        ['chickens'] = function()
            exports.oxmysql:execute(
                'UPDATE ranch SET `chickens`="false", `chickens_cond`=0, `chickens_age`=0 WHERE ranchid=@ranchid', param)
        end,
        ['pigs'] = function()
            exports.oxmysql:execute(
                'UPDATE ranch SET `pigs`="false", `pigs_cond`=0, `pigs_age`=0 WHERE ranchid=@ranchid', param)
        end,
        ['goats'] = function()
            exports.oxmysql:execute(
                'UPDATE ranch SET `goats`="false", `goats_cond`=0, `goats_age`=0 WHERE ranchid=@ranchid', param)
        end
    }

    if removeAnimalFuncts[animalType] then
        removeAnimalFuncts[animalType]()
    end
end)

------- Animal Wandering Setup Area -----------
local wanderingBools = {}
RegisterServerEvent('bcc-ranch:WanderingSetup', function(ranchid)
    local alreadySpawned = false
    if #wanderingBools > 0 then
        for k, v in pairs(wanderingBools) do
            if v.ranchId == ranchid and v.status then
                alreadySpawned = true
            end
        end
    end

    print(string.format("alreadySpawned: %s for ranchid: %s", alreadySpawned, ranchid))

    if not alreadySpawned then
        local param = { ['ranchid'] = ranchid }
        table.insert(wanderingBools, { ranchId = ranchid, status = true })
        local _source = source
        local result = MySQL.query.await("SELECT * FROM ranch WHERE ranchid=@ranchid", param)
        if #result > 0 then
            if result[1].cows == 'true' then
                TriggerClientEvent('bcc-ranch:CowsWander', -1, result[1].ranchid, result[1].ranchcoords, result[1].cowcoords)
            end
            if result[1].chickens == 'true' then
                TriggerClientEvent('bcc-ranch:ChickensWander', -1, result[1].ranchid, result[1].ranchcoords, result[1].chickencoords)
            end
            if result[1].goats == 'true' then
                TriggerClientEvent("bcc-ranch:GoatsWander", -1, result[1].ranchid, result[1].ranchcoords, result[1].goatcoords)
            end
            if result[1].pigs == 'true' then
                TriggerClientEvent("bcc-ranch:PigsWander", -1, result[1].ranchid, result[1].ranchcoords, result[1].pigcoords)
            end
        end
    end
end)

---------- Ageing Setup -----------------------
--[[ RegisterServerEvent('bcc-ranch:AgeCheck', function(ranchid)
    local _source = source
    local param = { ['ranchid'] = ranchid }
    local result = MySQL.query.await("SELECT * FROM ranch WHERE ranchid=@ranchid", param)
    if #result > 0 then
        if result[1].cows == 'true' then
            TriggerClientEvent('bcc-ranch:CowsAgeing', _source, result[1].cows_age)
        end
        if result[1].chickens == 'true' then
            TriggerClientEvent('bcc-ranch:ChickensAgeing', _source, result[1].chickens_age)
        end
        if result[1].goats == 'true' then
            TriggerClientEvent('bcc-ranch:GoatsAgeing', _source, result[1].goats_age)
        end
        if result[1].pigs == 'true' then
            TriggerClientEvent('bcc-ranch:PigsAgeing', _source, result[1].pigs_age)
        end
    end
end) ]]

--[[ AddEventHandler('bcc-ranch:IndAnimalAgeStart', function(animalType, _source)
    if animalType == 'cows' then
        TriggerClientEvent('bcc-ranch:CowsAgeing', _source, 0)
    end
    if animalType == 'chickens' then
        TriggerClientEvent('bcc-ranch:ChickensAgeing', _source, 0)
    end
    if animalType == 'goats' then
        TriggerClientEvent('bcc-ranch:GoatsAgeing', _source, 0)
    end
    if animalType == 'pigs' then
        TriggerClientEvent('bcc-ranch:PigsAgeing', _source, 0)
    end
end) ]]

RegisterServerEvent('bcc-ranch:AgeIncrease', function(animalType, ranchid)
    print('Age Increase')
    local ageIncFuncts = {
        ['cows'] = function()
            local param = {
                ['ranchid'] = ranchid,
                ['increaseamount'] = Config.RanchSetup.RanchAnimalSetup.Cows.AgeIncreaseAmount
            }
            exports.oxmysql:execute("UPDATE ranch SET `cows_age`=cows_age+@increaseamount WHERE ranchid=@ranchid", param)
        end,
        ['chickens'] = function()
            local param = {
                ['ranchid'] = ranchid,
                ['increaseamount'] = Config.RanchSetup.RanchAnimalSetup.Chickens.AgeIncreaseAmount
            }
            exports.oxmysql:execute(
                "UPDATE ranch SET `chickens_age`=chickens_age+@increaseamount WHERE ranchid=@ranchid", param)
        end,
        ['goats'] = function()
            local param = {
                ['ranchid'] = ranchid,
                ['increaseamount'] = Config.RanchSetup.RanchAnimalSetup.Goats.AgeIncreaseAmount
            }
            exports.oxmysql:execute("UPDATE ranch SET `goats_age`=goats_age+@increaseamount WHERE ranchid=@ranchid",
                param)
        end,
        ['pigs'] = function()
            local param = {
                ['ranchid'] = ranchid,
                ['increaseamount'] = Config.RanchSetup.RanchAnimalSetup.Pigs.AgeIncreaseAmount
            }
            exports.oxmysql:execute("UPDATE ranch SET `pigs_age`=pigs_age+@increaseamount WHERE ranchid=@ranchid", param)
        end
    }

    if ageIncFuncts[animalType] then
        ageIncFuncts[animalType]()
    end
end)

------ Coop Setup -----
RegisterServerEvent('bcc-ranch:CoopDBStorage', function(ranchId, coopCoords) --storing coop to db
    local param = { ['ranchid'] = ranchId, ['coopcoords'] = json.encode(coopCoords) }
    exports.oxmysql:execute(
        "UPDATE ranch SET `chicken_coop`='true', `chicken_coop_coords`=@coopcoords WHERE ranchid=@ranchid", param)
end)

RegisterServerEvent('bcc-ranch:ChickenCoopFundsCheck', function() --Checking money to buy coop
    local _source = source
    local character = VORPcore.getUser(_source).getUsedCharacter
    if character.money >= Config.RanchSetup.RanchAnimalSetup.Chickens.CoopCost then
        character.removeCurrency(0, Config.RanchSetup.RanchAnimalSetup.Chickens.CoopCost)
        TriggerClientEvent('bcc-ranch:PlaceChickenCoop', _source)
    else
        VORPcore.NotifyRightTip(_source, _U("Notenoughmoney"), 4000)
    end
end)

--------- Main Cooldown Area ---------
local coopCooldowns = {} --Coop Collection Cooldown
RegisterServerEvent('bcc-ranch:CoopCollectionCooldown', function(ranchId)
    local _source = source
    local shopid = ranchId
    if coopCooldowns[shopid] then
        if os.difftime(os.time(), coopCooldowns[shopid]) >= Config.RanchSetup.RanchAnimalSetup.Chickens.CoopCollectionCooldownTime then
            coopCooldowns[shopid] = os.time()
            TriggerClientEvent('bcc-ranch:ChickenCoopHarvest', _source)
        else
            VORPcore.NotifyRightTip(_source, _U("HarvestedTooSoon"), 4000)
        end
    else
        coopCooldowns[shopid] = os.time()                           --Store the current time
        TriggerClientEvent('bcc-ranch:ChickenCoopHarvest', _source) --Robbery is not on cooldown
    end
end)

local cowMilkingCooldowns = {} --Cow Milking Cooldown
RegisterServerEvent('bcc-ranch:CowMilkingCooldown', function(ranchId)
    local _source = source
    local shopid = ranchId
    if cowMilkingCooldowns[shopid] then
        if os.difftime(os.time(), cowMilkingCooldowns[shopid]) >= Config.RanchSetup.RanchAnimalSetup.Cows.MilkingCooldown then
            cowMilkingCooldowns[shopid] = os.time()
            TriggerClientEvent('bcc-ranch:MilkCows', _source)
        else
            VORPcore.NotifyRightTip(_source, _U("HarvestedTooSoonCow"), 4000)
        end
    else
        cowMilkingCooldowns[shopid] = os.time()           --Store the current time
        TriggerClientEvent('bcc-ranch:MilkCows', _source) --Robbery is not on cooldown
    end
end)


ServerRPC.Callback.Register('bcc-ranch:feedAnimal', function(source, cb, ranchId, animal)
    local _source = source

    local ranch = ServerRanchControllerInstance:getRanch(ranchId)
    if not ranch then
        VORPcore.NotifyRightTip(_source, "Something went bad ...", 4000)
        return
    end

    local cooldownController = ranch:getCooldownController()

    local interaction = 'chore'
    if feed then
        interaction = 'feed'
    end
    local isOnCooldown = cooldownController:isAnimalFeedInteractionOnCooldown(animal)

    if isOnCooldown then
        VORPcore.NotifyRightTip(_source, _U("TooSoon"), 4000)
        return
    end

    local result = exports.vorp_inventory:subItem(source, Config.RanchSetup.RanchAnimalSetup[animal].FoodItem, Config.RanchSetup.RanchAnimalSetup[animal].FoodAmount, nil)
    if not result then
        VORPcore.NotifyRightTip(_source, _U("NotEnoughFood"), 4000)
        return
    end

    cooldownController:startAnimalFeedInteractionCooldown(animal)
    ranch:setIsHerding(true)
    TriggerClientEvent('bcc-ranch:FeedAnimals', _source, animal)

end)

ServerRPC.Callback.Register('bcc-ranch:doHerding', function(source, cb, ranchId, animalType)
    local _source = source

    local ranch = ServerRanchControllerInstance:getRanch(ranchId)
    if not ranch then
        VORPcore.NotifyRightTip(_source, "Something went bad ...", 4000)
        print(string.format('ranchId %s not found', ranchId))
        cb(false)
        return
    end

    local cooldownController = ranch:getCooldownController()

    local isOnCooldown = cooldownController:isHerdingInteractionOnCooldown(animalType)

    if isOnCooldown then
        VORPcore.NotifyRightTip(_source, _U("TooSoon"), 4000)
        print(string.format('ranchId %s is on cooldown for herding %s', ranchId, animalType))
        cb(false)
        return
    end


    if ranch.isherding then
        VORPcore.NotifyRightTip(_U("AnimalsOut"), 4000)
        print(string.format('ranchId %s is already herding %s', ranchId, animalType))
        cb(false)
        return
    end

    ranch:setIsHerding(true)
    TriggerClientEvent('bcc-ranch:AnimalsOutCl', _source, ranch.isherding)

    cooldownController:startHerdingInteractionCooldown(animalType)
    cb(true)

end)

--[[ local choreCooldowns = {} --Chore and feeding Cooldown
RegisterServerEvent('bcc-ranch:ChoreCooldownSV', function(source,ranchId, feed, chore, animal)
    local _source = source
    local shopid = ranchId
    local cooldown
    if feed then
        if animal == 'cows' then
            cooldown = Config.RanchSetup.RanchAnimalSetup.Cows.FeedCooldown or Config.RanchSetup.FeedCooldown
        elseif animal == 'chickens' then
            cooldown = Config.RanchSetup.RanchAnimalSetup.Chickens.FeedCooldown or Config.RanchSetup.FeedCooldown
        elseif animal == 'goats' then
            cooldown = Config.RanchSetup.RanchAnimalSetup.Goats.FeedCooldown or Config.RanchSetup.FeedCooldown
        elseif animal == 'pigs' then
            cooldown = Config.RanchSetup.RanchAnimalSetup.Pigs.FeedCooldown or Config.RanchSetup.FeedCooldown
        else 
            cooldown = Config.RanchSetup.FeedCooldown
        end
    else
        if animal == 'cows' then
            cooldown = Config.RanchSetup.RanchAnimalSetup.Cows.ChoreCooldown or Config.RanchSetup.ChoreCooldown
        elseif animal == 'chickens' then
            cooldown = Config.RanchSetup.RanchAnimalSetup.Chickens.ChoreCooldown or Config.RanchSetup.ChoreCooldown
        elseif animal == 'goats' then
            cooldown = Config.RanchSetup.RanchAnimalSetup.Goats.ChoreCooldown or Config.RanchSetup.ChoreCooldown
        elseif animal == 'pigs' then
            cooldown = Config.RanchSetup.RanchAnimalSetup.Pigs.ChoreCooldown or Config.RanchSetup.ChoreCooldown
        else
            cooldown = Config.RanchSetup.ChoreCooldown
        end
    end
    if choreCooldowns[shopid] then
        if os.difftime(os.time(), choreCooldowns[shopid]) >= cooldown then
            choreCooldowns[shopid] = os.time()
            if feed then
                TriggerClientEvent('bcc-ranch:FeedAnimals', _source, animal)
            else
                TriggerClientEvent('bcc-ranch:ShovelHay', _source, chore)
            end
        else
            VORPcore.NotifyRightTip(_source, _U("TooSoon"), 4000)
        end
    else
        choreCooldowns[shopid] = os.time() --Store the current time
        if feed then
            TriggerClientEvent('bcc-ranch:FeedAnimals', _source, animal)
        else
            TriggerClientEvent('bcc-ranch:ShovelHay', _source, chore)
        end
    end
end) ]]

-- TODO: refactoring needed!
-- Will reset isHerding to 0 if any player working at the ranch leaves the server even when others are still working.
AddEventHandler('playerDropped', function()
    local character = VORPcore.getUser(source).getUsedCharacter
    local charid = character.charIdentifier

    local select_ranchid_param = { ['charid'] = charid }
    local sqlString = "SELECT ranchid FROM characters WHERE charidentifier=@charid"
    if Config.useCharacterJob then
        select_ranchid_param = { ['job'] = character.job }
        sqlString = "SELECT ranchid FROM ranch WHERE job=@job"
    end

    --print("select_ranchid_param: " .. tostring(select_ranchid_param) .. ": " .. json.encode(select_ranchid_param))
    local ranch = MySQL.query.await(sqlString, select_ranchid_param )

    if ranch and #ranch > 0 and tonumber(ranch[1].ranchid) > 0 then
        local ranchObject = ServerRanchControllerInstance:getRanch(ranch[1].ranchid)
        if not ranchObject then
            print(string.format('[playerDropped] ranchId %s not found', ranch[1].ranchid))
         end
         ranchObject:setIsHerding(false)
    end
end)

----- Version Check ----
BccUtils.Versioner.checkRelease(GetCurrentResourceName(), 'https://github.com/BryceCanyonCounty/bcc-ranch')


AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end
    exports.oxmysql:execute("UPDATE ranch SET isherding = 0")
end)

ServerRPC.Callback.Register('bcc-ranch:removeFroodFromInventoryIfAvailable', function(source, cb, foodItem, foodAmount)
    local result = exports.vorp_inventory:subItem(source, foodItem, foodAmount, nil)
    if not result then
        cb(false)
        return
    end
    cb(true)
end)