---@class RanchModel
---@field ranchid number
---@field charidentifier string
---@field ranchcoords table
---@field ranchname string
---@field ranch_radius_limit number
---@field ranchCondition number
---@field cows boolean
---@field pigs boolean
---@field chickens boolean
---@field goats boolean
---@field cowcoords table
---@field pigcoords table
---@field chickencoords table
---@field goatcoords table
---@field isherding boolean
---@field cows_age number
---@field pigs_age number
---@field chickens_age number
---@field goats_age number
---@field wanderingAnimals table[]
---@field getAnimalScale function

RanchModel = {}
RanchModel.__index = RanchModel

---@enum AnimalType @The type of animal
AnimalType = {
    Cows,
    Pigs,
    Chicken,
    Goats
}

--- Get a RanchModel object from the database
---@param ranchid any
---@return nil
function RanchModel.initFromDB(ranchid)
    local self = setmetatable({}, RanchModel)
    self.ranchid = ranchid
    if not self:updateFromServer() then
        return nil
    end
    return self
end

--- Get a RanchModel object from the database
---@param ranchDataModel RanchDataModel
---@return RanchModel
function RanchModel.initFromRanchDataModel(ranchDataModel)
    local self = setmetatable({}, RanchModel)
    self.ranchid = ranchDataModel.ranchid
    self.charidentifier = ranchDataModel.charidentifier
    self.ranchcoords = ranchDataModel.ranchcoords
    self.ranchname = ranchDataModel.ranchname
    self.ranch_radius_limit = ranchDataModel.ranch_radius_limit
    self.ranchCondition = ranchDataModel.ranchCondition
    self.cows = ranchDataModel.cows
    self.pigs = ranchDataModel.pigs
    self.chickens = ranchDataModel.chickens
    self.goats = ranchDataModel.goats
    self.cowcoords = ranchDataModel.cowcoords or self.ranchcoords
    self.pigcoords = ranchDataModel.pigcoords or self.ranchcoords
    self.chickencoords = ranchDataModel.chickencoords or self.ranchcoords
    self.goatcoords = ranchDataModel.goatcoords or self.ranchcoords
    self.isherding = ranchDataModel.isherding
    self.cows_age = ranchDataModel.cows_age
    self.pigs_age = ranchDataModel.pigs_age
    self.chickens_age = ranchDataModel.chickens_age
    self.goats_age = ranchDataModel.goats_age
    return self
end

function RanchModel:updateFromServer()
    local rpcCallResult = ClientRPC.Callback.TriggerAwait("bcc-ranch:getRanchData", self.ranchid) ---@type RanchDataModel
    if not rpcCallResult then
        print("RanchModel:updateFromServer() - ClientRPC.Callback.TriggerAwait('bcc-ranch:getRanchData') returned false")
        return false
    end

    self.charidentifier = rpcCallResult.charidentifier
    self.ranchcoords = rpcCallResult.ranchcoords
    self.ranchname = rpcCallResult.ranchname
    self.ranch_radius_limit = rpcCallResult.ranch_radius_limit
    self.ranchCondition = rpcCallResult.ranchCondition
    self.cows = rpcCallResult.cows
    self.pigs = rpcCallResult.pigs
    self.chickens = rpcCallResult.chickens
    self.goats = rpcCallResult.goats
    self.cowcoords = rpcCallResult.cowcoords
    self.pigcoords = rpcCallResult.pigcoords
    self.chickencoords = rpcCallResult.chickencoords
    self.goatcoords = rpcCallResult.goatcoords
    self.isherding = rpcCallResult.isherding
    self.cows_age = rpcCallResult.cows_age
    self.pigs_age = rpcCallResult.pigs_age
    self.chickens_age = rpcCallResult.chickens_age
    self.goats_age = rpcCallResult.goats_age
    return true
end

function RanchModel:updateFromRanchDataModel(ranchDataModel)
    self.charidentifier = ranchDataModel.charidentifier
    self.ranchcoords = ranchDataModel.ranchcoords
    self.ranchname = ranchDataModel.ranchname
    self.ranch_radius_limit = ranchDataModel.ranch_radius_limit
    self.ranchCondition = ranchDataModel.ranchCondition
    self.cows = ranchDataModel.cows
    self.pigs = ranchDataModel.pigs
    self.chickens = ranchDataModel.chickens
    self.goats = ranchDataModel.goats
    self.cowcoords = ranchDataModel.cowcoords
    self.pigcoords = ranchDataModel.pigcoords
    self.chickencoords = ranchDataModel.chickencoords
    self.goatcoords = ranchDataModel.goatcoords
    self.isherding = ranchDataModel.isherding
    self.cows_age = ranchDataModel.cows_age
    self.pigs_age = ranchDataModel.pigs_age
    self.chickens_age = ranchDataModel.chickens_age
    self.goats_age = ranchDataModel.goats_age
end

function RanchModel:addWanderingAnimalHandler(animalType, pedHandler)
    self.wanderingAnimals = self.wanderingAnimals or {}
    if not self.wanderingAnimals[animalType] then
        self.wanderingAnimals[animalType] = {}
    end
    table.insert(self.wanderingAnimals[animalType], pedHandler)
end

function RanchModel:deleteWanderingAnimalHandler(animalType)
    self.wanderingAnimals = self.wanderingAnimals or {}
    if not self.wanderingAnimals[animalType] then
        return
    end
    self.wanderingAnimals[animalType] = nil
end

function RanchModel:isWanderingAnimalCurrentlySpawned(animalType)
    if self.wanderingAnimals and self.wanderingAnimals[animalType] and #self.wanderingAnimals[animalType] > 0 then
        return true
    end
    return false
end

--- get scale of animal based on age
---@param animalType enum AnimalType
---@return number
function RanchModel:getAnimalScale(animalType)
    local maxPedScale = 1.2
    local minPedScale = 0.7
    local animalAge = self[string.lower(animalType) .. "_age"]
    if animalAge > Config.RanchSetup.AnimalGrownAge then
        animalAge = Config.RanchSetup.AnimalGrownAge
    end
    local gradient = (maxPedScale - minPedScale) / Config.RanchSetup.AnimalGrownAge
    local animalSize = minPedScale + gradient * animalAge
    return animalSize
end