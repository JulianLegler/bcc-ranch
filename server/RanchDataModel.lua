---@class RanchDataModel
---@field charidentifier string
---@field ranchid number
---@field ranchname string
---@field ranchcoords table
---@field ranch_radius_limit number
---@field ranchCondition number
---@field cows string
---@field cows_cond number
---@field pigs string
---@field pigs_cond number
---@field chickens string
---@field chickens_cond number
---@field goats string
---@field goats_cond number
---@field cows_age number
---@field chickens_age number
---@field goats_age number
---@field pigs_age number
---@field chicken_coop string
---@field chicken_coop_coords table
---@field shovehaycoords table
---@field wateranimalcoords table
---@field repairtroughcoords table
---@field scooppoopcoords table
---@field cowcoords table
---@field pigcoords table
---@field chickencoords table
---@field goatcoords table
---@field herdlocation table
---@field wagonfeedcoords table
---@field ledger number
---@field isherding number
---@field job string
---@field getCooldownController function
---@field increaseRanchCondition function
---@field decreaseRanchCondition function
---@field increaseAnimalCondition function
---@field setIsHerding function



RanchDataModel = {}
RanchDataModel.__index = RanchDataModel



--- RanchDataModel.get - Get a RanchDataModel object from the database
---@param ranchid number - The ranchid of the ranch to get
---@return RanchDataModel|nil - The RanchDataModel object or nil if not found
function RanchDataModel.get(ranchid)
    local self = setmetatable({}, RanchDataModel)
    self.ranchid = ranchid
    if not self:initRanchFromDB() then
        return nil
    end
    self.cooldownController = CooldownController.init(self.ranchid)
    return self
end

function RanchDataModel:initRanchFromDB()
    local ranch = MySQL.Sync.fetchAll("SELECT * FROM ranch WHERE ranchid = @ranchid", {['@ranchid'] = self.ranchid})
    if not ranch[1] then
        print(string.format("RanchDataModel:initRanchFromDB() - Ranch with ranchid %s not found", self.ranchid))
        return false
    end
    local ranch = ranch[1]
    if not ranch.charidentifier then
        print(string.format("RanchDataModel:initRanchFromDB() - Ranch with ranchid %s has no charidentifier", self.ranchid))
        return false
    end
    if not ranch.ranchcoords then
        print(string.format("RanchDataModel:initRanchFromDB() - Ranch with ranchid %s has no ranchcoords", self.ranchid))
        return false
    end
    if not ranch.ranchname then
        print(string.format("RanchDataModel:initRanchFromDB() - Ranch with ranchid %s has no ranchname", self.ranchid))
        return false
    end
    if not ranch.ranch_radius_limit then
        print(string.format("RanchDataModel:initRanchFromDB() - Ranch with ranchid %s has no ranch_radius_limit", self.ranchid))
        return false
    end
    if not ranch.ranchCondition then
        print(string.format("RanchDataModel:initRanchFromDB() - Ranch with ranchid %s has no ranchCondition", self.ranchid))
        return false
    end

    self.charidentifier = ranch.charidentifier
    self.ranchcoords = handleVectorFromDB(ranch.ranchcoords)
    self.ranchname = ranch.ranchname
    self.ranch_radius_limit = ranch.ranch_radius_limit
    self.ranchCondition = ranch.ranchCondition
    self.cows = handleBoolean(ranch.cows)
    self.cows_cond = ranch.cows_cond
    self.pigs = handleBoolean(ranch.pigs)
    self.pigs_cond = ranch.pigs_cond
    self.chickens = handleBoolean(ranch.chickens)
    self.chickens_cond = ranch.chickens_cond
    self.goats = handleBoolean(ranch.goats)
    self.goats_cond = ranch.goats_cond
    self.cows_age = ranch.cows_age
    self.chickens_age = ranch.chickens_age
    self.goats_age = ranch.goats_age
    self.pigs_age = ranch.pigs_age
    self.chicken_coop = ranch.chicken_coop
    self.chicken_coop_coords = handleVectorFromDB(ranch.chicken_coop_coords) or {}
    self.shovehaycoords = handleVectorFromDB(ranch.shovehaycoords) or {}
    self.wateranimalcoords = handleVectorFromDB(ranch.wateranimalcoords) or {}
    self.repairtroughcoords = handleVectorFromDB(ranch.repairtroughcoords) or {}
    self.scooppoopcoords = handleVectorFromDB(ranch.scooppoopcoords) or {}
    self.herdlocation = handleVectorFromDB(ranch.herdlocation) or {}
    self.pigcoords = handleVectorFromDB(ranch.pigcoords) or {}
    self.cowcoords = handleVectorFromDB(ranch.cowcoords) or {}
    self.chickencoords = handleVectorFromDB(ranch.chickencoords) or {}
    self.goatcoords = handleVectorFromDB(ranch.goatcoords) or {}
    self.wagonfeedcoords = handleVectorFromDB(ranch.wagonfeedcoords) or {}
    self.ledger = ranch.ledger
    self.isherding = handleBoolean(ranch.isherding)
    self.taxamount = ranch.taxamount
    self.job = ranch.job
    return true
end

function handleVectorFromDB(vectorJson)
    if not vectorJson then
        return {}
    end
    local vector = json.decode(vectorJson)
    if not vector then
        return {}
    end
    return vector3(vector.x, vector.y, vector.z)
end

function handleBoolean(value)
    if value == 'true' then
        return true
    end
    return false
end

function RanchDataModel:dataChanged()
    ServerRPC.Callback.TriggerAsync('bcc-ranch:ranchDataChanged', -1, function () end, self)
end

--- changes the animal owned state for the ranch in the db
---@param animalType string
---@param state string - 'true' or 'false'
---@return boolean - true if successful, false if not
function RanchDataModel:setAnimalOwnedState(animalType, state)
    local result = MySQL.Sync.execute("UPDATE ranch SET " .. animalType .. " = @state WHERE ranchid = @ranchid", {['@state'] = state, ['@ranchid'] = self.ranchid})
    if result == 0 then
        print(string.format("RanchDataModel:setAnimalOwnedState() - Failed to update %s state for ranch with ranchid %s", animalType, self.ranchid))
        return false
    end
    self[animalType] = handleBoolean(state)
    print(string.format("RanchDataModel:setAnimalOwnedState() - Updated %s state for ranch with ranchid %s", animalType, self.ranchid))
    self:dataChanged()
    return true
end

--- changes the isherding state for the ranch in the db
---@param state number
---@return boolean
function RanchDataModel:setIsHerding(state)
    local result = MySQL.Sync.execute("UPDATE ranch SET isherding = @state WHERE ranchid = @ranchid", {['@state'] = state, ['@ranchid'] = self.ranchid})
    if result == 0 then
        print(string.format("RanchDataModel:setIsHerding() - Failed to update isherding state for ranch with ranchid %s", self.ranchid))
        return false
    end
    self.isherding = state
    print(string.format("RanchDataModel:setIsHerding() - Updated isherding state for ranch with ranchid %s", self.ranchid))
    self:dataChanged()
    return true
end

--- returns the cooldown controller for the ranch
---@return CooldownController - the cooldown controller
function RanchDataModel:getCooldownController()
    return self.cooldownController
end

function RanchDataModel:increaseRanchCondition(increaseAmount)
    local result = MySQL.Sync.execute("UPDATE ranch SET ranchCondition = ranchCondition + @increaseAmount WHERE ranchid = @ranchid", {['@increaseAmount'] = increaseAmount, ['@ranchid'] = self.ranchid})
    if result == 0 then
        print(string.format("RanchDataModel:increaseRanchCondition() - Failed to increase ranch condition for ranch with ranchid %s", self.ranchid))
        return false
    end
    self.ranchCondition = self.ranchCondition + increaseAmount
    print(string.format("RanchDataModel:increaseRanchCondition() - Increased ranch condition for ranch with ranchid %s", self.ranchid))
    self:dataChanged()
    return true
end

function RanchDataModel:decreaseRanchCondition(decreaseAmount)
    if self.ranchCondition - decreaseAmount < 0 then
        decreaseAmount = self.ranchCondition
    end
    local result = MySQL.Sync.execute("UPDATE ranch SET ranchCondition = ranchCondition - @decreaseAmount WHERE ranchid = @ranchid", {['@decreaseAmount'] = decreaseAmount, ['@ranchid'] = self.ranchid})
    if result == 0 then
        print(string.format("RanchDataModel:decreaseRanchCondition() - Failed to decrease ranch condition for ranch with ranchid %s", self.ranchid))
        return false
    end
    self.ranchCondition = self.ranchCondition - decreaseAmount
    print(string.format("RanchDataModel:decreaseRanchCondition() - Decreased ranch condition for ranch with ranchid %s", self.ranchid))
    self:dataChanged()
    return true
end

function RanchDataModel:increaseAnimalCondition(animalType, increaseAmount)
    local animalType = string.lower(animalType)
    local fieldName = animalType .. '_cond'
    local result = MySQL.Sync.execute("UPDATE ranch SET " .. fieldName .. " = " .. fieldName .. " + @increaseAmount WHERE ranchid = @ranchid", {['@increaseAmount'] = increaseAmount, ['@ranchid'] = self.ranchid})
    if result == 0 then
        print(string.format("RanchDataModel:increaseAnimalCondition() - Failed to increase animal %s condition for ranch with ranchid %s", animalType, self.ranchid))
        return false
    end
    self[fieldName] = self[fieldName] + increaseAmount
    print(string.format("RanchDataModel:increaseAnimalCondition() - Increased %s condition for ranch with ranchid %s", animalType, self.ranchid))
    self:dataChanged()
    return true
end

function RanchDataModel:increaseAnimalAge(animalType, increaseAmount)
    local animalType = string.lower(animalType)
    local fieldName = animalType .. '_age'
    local result = MySQL.Sync.execute("UPDATE ranch SET " .. fieldName .. " = " .. fieldName .. " + @increaseAmount WHERE ranchid = @ranchid", {['@increaseAmount'] = increaseAmount, ['@ranchid'] = self.ranchid})
    if result == 0 then
        print(string.format("RanchDataModel:increaseAnimalAge() - Failed to increase animal %s age for ranch with ranchid %s", animalType, self.ranchid))
        return false
    end
    self[fieldName] = self[fieldName] + increaseAmount
    print(string.format("RanchDataModel:increaseAnimalAge() - Increased %s age for ranch with ranchid %s", animalType, self.ranchid))
    self:dataChanged()
    return true
end