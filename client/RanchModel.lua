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
---@field wanderingAnimals table[]

RanchModel = {}
RanchModel.__index = RanchModel


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
    return true
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