------------ Export Area ------------------
-- Check If player owns ranch exports
exports('CheckIfRanchIsOwned', function(charIdentifier) --credit to the whole bcc dev team for help with this
    local param = { ['charidentifier'] = charIdentifier }
    local result = MySQL.query.await("SELECT * FROM ranch WHERE charidentifier=@charidentifier", param)
    if #result > 0 then
        return true
    else
        return false
    end
end)

--Increase Ranch Condition Export
exports('IncreaseRanchCondition', function(charIdentifier, amount)
    local param = { ['charidentifier'] = charIdentifier, ['amount'] = amount }
    exports.oxmysql:execute('UPDATE ranch SET `ranchCondition`=ranchCondition+@amount WHERE charidentifier=@charidentifier', param)
end)

--Decrease Ranch Condition Export
exports('DecreaseRanchCondition', function(charIdentifier, amount)
    local param = { ['charidentifier'] = charIdentifier, ['amount'] = amount }
    exports.oxmysql:execute('UPDATE ranch SET `ranchCondition`=ranchCondition-@amount WHERE charidentifier=@charidentifier', param)
end)

--Check if player works at a ranch
exports('DoesPlayerWorkAtRanch', function(charidentifier)
    local character = VORPcore.getUser(_source).getUsedCharacter
    local param = {}
    local sqlString = ""
    if Config.useCharacterJob then
        param = { ['job'] = character.job }
        sqlString = "SELECT ranchid FROM ranch WHERE job=@job"
    else
        param = { ['charid'] = charidentifier }
        sqlString = "SELECT ranchid FROM ranch WHERE charidentifier=@charid"
    end
    local result = MySQL.query.await(sqlString, param)
    if #result > 0 then
        return true
    else
        return false
    end
end)