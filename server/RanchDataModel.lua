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

RanchDataModel = {}
RanchDataModel.__index = RanchDataModel



--[[
CREATE TABLE `ranch` (
	`charidentifier` VARCHAR(50) NOT NULL COLLATE 'utf8mb4_general_ci',
	`ranchcoords` LONGTEXT NOT NULL COLLATE 'utf8mb4_general_ci',
	`ranchname` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_general_ci',
	`ranch_radius_limit` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_general_ci',
	`ranchid` INT(11) NOT NULL AUTO_INCREMENT,
	`ranchCondition` INT(10) NOT NULL DEFAULT '0',
	`cows` VARCHAR(50) NOT NULL DEFAULT 'false' COLLATE 'utf8mb4_general_ci',
	`cows_cond` INT(10) NOT NULL DEFAULT '0',
	`pigs` VARCHAR(50) NOT NULL DEFAULT 'false' COLLATE 'utf8mb4_general_ci',
	`pigs_cond` INT(10) NOT NULL DEFAULT '0',
	`chickens` VARCHAR(50) NOT NULL DEFAULT 'false' COLLATE 'utf8mb4_general_ci',
	`chickens_cond` INT(10) NOT NULL DEFAULT '0',
	`goats` VARCHAR(50) NOT NULL DEFAULT 'false' COLLATE 'utf8mb4_general_ci',
	`goats_cond` INT(10) NOT NULL DEFAULT '0',
	`cows_age` INT(10) NULL DEFAULT '0',
	`chickens_age` INT(10) NULL DEFAULT '0',
	`goats_age` INT(10) NULL DEFAULT '0',
	`pigs_age` INT(10) NULL DEFAULT '0',
	`chicken_coop` VARCHAR(50) NULL DEFAULT 'none' COLLATE 'utf8mb4_general_ci',
	`chicken_coop_coords` LONGTEXT NULL DEFAULT 'none' COLLATE 'utf8mb4_general_ci',
	`shovehaycoords` LONGTEXT NULL DEFAULT 'none' COLLATE 'utf8mb4_general_ci',
	`wateranimalcoords` LONGTEXT NULL DEFAULT 'none' COLLATE 'utf8mb4_general_ci',
	`repairtroughcoords` LONGTEXT NULL DEFAULT 'none' COLLATE 'utf8mb4_general_ci',
	`scooppoopcoords` LONGTEXT NULL DEFAULT 'none' COLLATE 'utf8mb4_general_ci',
	`herdlocation` LONGTEXT NULL DEFAULT 'none' COLLATE 'utf8mb4_general_ci',
	`pigcoords` LONGTEXT NULL DEFAULT 'none' COLLATE 'utf8mb4_general_ci',
	`cowcoords` LONGTEXT NULL DEFAULT 'none' COLLATE 'utf8mb4_general_ci',
	`chickencoords` LONGTEXT NULL DEFAULT 'none' COLLATE 'utf8mb4_general_ci',
	`goatcoords` LONGTEXT NULL DEFAULT 'none' COLLATE 'utf8mb4_general_ci',
	`wagonfeedcoords` LONGTEXT NULL DEFAULT 'none' COLLATE 'utf8mb4_general_ci',
	`ledger` INT(10) NULL DEFAULT '0',
	`isherding` INT(10) NULL DEFAULT '0',
	`taxamount` INT(10) NULL DEFAULT '0',
	`job` VARCHAR(50) NULL DEFAULT 'none' COLLATE 'utf8mb4_general_ci',
	PRIMARY KEY (`ranchid`) USING BTREE,
	UNIQUE INDEX `charidentifier` (`charidentifier`) USING BTREE
)
COLLATE='utf8mb4_general_ci'
ENGINE=InnoDB
AUTO_INCREMENT=6
;

]]

--- RanchDataModel.get - Get a RanchDataModel object from the database
---@param ranchid number - The ranchid of the ranch to get
---@return nil|RanchDataModel
function RanchDataModel.get(ranchid)
    local self = setmetatable({}, RanchDataModel)
    self.ranchid = ranchid
    if not self:initRanchFromDB() then
        return nil
    end
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
    self.isherding = ranch.isherding
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

ServerRPC.Callback.Register('bcc-ranch:getRanchData', function(source, cb, ranchid)
    local ranch = RanchDataModel.get(ranchid)
    if not ranch then
        cb(false)
        return
    end
    cb(ranch)
end)

ServerRPC.Callback.Register('bcc-ranch:getAllRanchData', function(source, cb)
    local ranches = {}
    local ranchids = MySQL.Sync.fetchAll("SELECT ranchid FROM ranch")
    for _, ranchid in pairs(ranchids or {}) do
        local ranch = RanchDataModel.get(ranchid.ranchid)
        if ranch then
            table.insert(ranches, ranch)
        end
    end
    cb(ranches)
end)