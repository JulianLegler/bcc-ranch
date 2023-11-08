---@class CooldownController
---@field ranchid number
---@field shovelhay_timestamp number
---@field repairtrough_timestamp number
---@field scooppoop_timestamp number


CooldownController = {}
CooldownController.__index = CooldownController

--- CooldownController.get - Get a CooldownController object from the database
---@param ranchid number - The ranchid of the ranch to get the cooldowns from
---@return CooldownController|nil - The CooldownController object or nil if not found
function CooldownController.init(ranchid)
    local self = setmetatable({}, CooldownController)
    self.ranchid = ranchid
    if not self:initCooldownsFromDB() then
        error(string.format("CooldownController.init() - Failed to init CooldownController for ranchid %s", ranchid))
        return nil
    end
    return self
end

function CooldownController:initCooldownsFromDB()
    local ranch = MySQL.Sync.fetchAll("SELECT * FROM ranch WHERE ranchid = @ranchid", {['@ranchid'] = self.ranchid})
    if not ranch[1] then
        print(string.format("CooldownController:initRanchFromDB() - Ranch with ranchid %s not found", self.ranchid))
        return false
    end
    local ranch = ranch[1]
    self.shovelhay_timestamp = math.ceil(ranch.shovelhay_timestamp / 1000)
    self.repairtrough_timestamp = math.ceil(ranch.repairtrough_timestamp / 1000)
    self.scooppoop_timestamp = math.ceil(ranch.scooppoop_timestamp / 1000)
    self.wateranimal_timestamp = math.ceil(ranch.wateranimal_timestamp / 1000)

    self.feed_pigs_timestamp = math.ceil(ranch.feed_pigs_timestamp / 1000)
    self.feed_cows_timestamp = math.ceil(ranch.feed_cows_timestamp / 1000)
    self.feed_chickens_timestamp = math.ceil(ranch.feed_chickens_timestamp / 1000)
    self.feed_goats_timestamp = math.ceil(ranch.feed_goats_timestamp / 1000)

    self.herd_pigs_timestamp = math.ceil(ranch.herd_pigs_timestamp / 1000 )
    self.herd_cows_timestamp = math.ceil(ranch.herd_cows_timestamp / 1000)
    self.herd_chickens_timestamp = math.ceil(ranch.herd_chickens_timestamp / 1000 )
    self.herd_goats_timestamp = math.ceil(ranch.herd_goats_timestamp / 1000)
    return true
end

--- check if the animal feed interaction is on cooldown
---@param animal string
---@param interaction string
---@return boolean
function CooldownController:isAnimalFeedInteractionOnCooldown(animal)
    local cooldownName = string.format("feed_%s_timestamp", animal)
    local configCooldown = Config.RanchSetup.RanchAnimalSetup[animal].FeedingCooldown or Config.RanchSetup.FeedCooldown
    return not self:isTimestampExpired(cooldownName, configCooldown)
end

function CooldownController:startAnimalFeedInteractionCooldown(animal)
    local cooldownName = string.format("feed_%s_timestamp", animal)
    self:updateTimestamp(cooldownName)
end

function CooldownController:isRanchInteractionOnCooldown(interaction)
    local cooldownName = ""
    local configCooldown = 0
    if interaction == "shovelhay" then
        configCooldown = Config.RanchSetup.ShovelHayCooldown or Config.RanchSetup.ChoreCooldown
        cooldownName = "shovelhay_timestamp"
    elseif interaction == "repairfeedtrough" then
        configCooldown = Config.RanchSetup.RepairTroughCooldown or Config.RanchSetup.ChoreCooldown
        cooldownName = "repairtrough_timestamp"
    elseif interaction == "scooppoop" then
        configCooldown = Config.RanchSetup.ScoopPoopCooldown or Config.RanchSetup.ChoreCooldown
        cooldownName = "scooppoop_timestamp"
    elseif interaction == "wateranimals" then
        configCooldown = Config.RanchSetup.WaterAnimalCooldown or Config.RanchSetup.ChoreCooldown
        cooldownName = "wateranimal_timestamp"
    else
        error(string.format("CooldownController:isRanchInteractionOnCooldown() - Invalid interaction %s", interaction))
        return true
    end

    return not self:isTimestampExpired(cooldownName, configCooldown)
end

function CooldownController:startRanchInteractionCooldown(interaction)
    local cooldownName = ""
    if interaction == "shovelhay" then
        cooldownName = "shovelhay_timestamp"
    elseif interaction == "repairfeedtrough" then
        cooldownName = "repairtrough_timestamp"
    elseif interaction == "scooppoop" then
        cooldownName = "scooppoop_timestamp"
    elseif interaction == "wateranimals" then
        cooldownName = "wateranimal_timestamp"
    else
        error(string.format("CooldownController:startRanchInteractionCooldown() - Invalid interaction %s", interaction))
        return
    end
    self:updateTimestamp(cooldownName)
end


function CooldownController:isHerdingInteractionOnCooldown(animal) 
    local cooldownName = ""
    local configCooldown = 0
    if animal == "pigs" then
        configCooldown = Config.RanchSetup.RanchAnimalSetup.Pigs.HerdingCooldown or Config.RanchSetup.ChoreCooldown
        cooldownName = "herd_pigs_timestamp"
    elseif animal == "cows" then
        configCooldown = Config.RanchSetup.RanchAnimalSetup.Cows.HerdingCooldown or Config.RanchSetup.ChoreCooldown
        cooldownName = "herd_cows_timestamp"
    elseif animal == "chickens" then
        configCooldown = Config.RanchSetup.RanchAnimalSetup.Chickens.HerdingCooldown or Config.RanchSetup.ChoreCooldown
        cooldownName = "herd_chickens_timestamp"
    elseif animal == "goats" then
        configCooldown = Config.RanchSetup.RanchAnimalSetup.Goats.HerdingCooldown or Config.RanchSetup.ChoreCooldown
        cooldownName = "herd_goats_timestamp"
    else
        error(string.format("CooldownController:isHerdingInteractionOnCooldown() - Invalid animal %s", animal))
        return true
    end

    return not self:isTimestampExpired(cooldownName, configCooldown)
end

function CooldownController:startHerdingInteractionCooldown(animal)
    local cooldownName = ""
    if animal == "pigs" then
        cooldownName = "herd_pigs_timestamp"
    elseif animal == "cows" then
        cooldownName = "herd_cows_timestamp"
    elseif animal == "chickens" then
        cooldownName = "herd_chickens_timestamp"
    elseif animal == "goats" then
        cooldownName = "herd_goats_timestamp"
    else
        error(string.format("CooldownController:startHerdingInteractionCooldown() - Invalid animal %s", animal))
        return
    end
    self:updateTimestamp(cooldownName)
end


-- Assuming os.time() is used for the current timestamp and os.difftime() to calculate the difference in seconds.

--- Checks if a timestamp is more than X seconds ago.
---@param timestampField string - The name of the timestamp field to check.
---@param seconds number - The number of seconds to check against.
---@return boolean - True if the timestamp is more than X seconds ago, false otherwise.
function CooldownController:isTimestampExpired(timestampField, seconds)
    local currentTimestamp = os.time()
    local timestampField = string.lower(timestampField)
    local timestampToCheck = self[timestampField]
    if not timestampToCheck then
        error(string.format("Timestamp field '%s' does not exist on CooldownController", timestampField))
        return false
    end

    print(string.format("CooldownController:isTimestampExpired() - Current timestamp is %s", currentTimestamp))
    print(string.format("CooldownController:isTimestampExpired() - Timestamp '%s' is %s", timestampField, timestampToCheck))


    local timeDiff = os.difftime(currentTimestamp, timestampToCheck)
    print(string.format("CooldownController:isTimestampExpired() - Timestamp '%s' is %s seconds old and cooldown can be triggered after %s", timestampField, timeDiff, seconds))
    return timeDiff > seconds
end

--- Updates the specified timestamp to the current time.
---@param timestampField string - The name of the timestamp field to update.
function CooldownController:updateTimestamp(timestampField)
    local timestampField = string.lower(timestampField)
    if not self[timestampField] then
        error(string.format("Timestamp field '%s' does not exist on CooldownController", timestampField))
        return false
    end

    -- Assuming os.date() in the format below is compatible with MySQL TIMESTAMP format
    self[timestampField] = os.time()

    -- Update the timestamp in the database. 
    -- WARNING: The query is not safe against SQL injections and should be properly parameterized.
    local updateQuery = string.format("UPDATE ranch SET %s = @newTimestamp WHERE ranchid = @ranchid", timestampField)
    local result = MySQL.Sync.execute(updateQuery, {['@newTimestamp'] = os.date("%Y-%m-%d %H:%M:%S", os.time()), ['@ranchid'] = self.ranchid})
    if result == 0 then
        error(string.format("CooldownController:updateTimestamp() - Failed to update timestamp '%s' for ranchid %s", timestampField, self.ranchid))
        return false
    end
    return true
end
