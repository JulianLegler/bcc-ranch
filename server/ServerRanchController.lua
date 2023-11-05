---@class ServerRanchController
---@field ranchList RanchDataModel[]
ServerRanchController = {}
ServerRanchController.__index = ServerRanchController



function ServerRanchController.new()
    local self = setmetatable({}, ServerRanchController)
    self.ranchList = {}
    self:loadAllRanches()
    return self
end

---comment
---@param ranchid number
---@return RanchDataModel |nil
function ServerRanchController:getRanch(ranchid)
    for _, ranchModel in pairs(self.ranchList) do
        if ranchModel.ranchid == ranchid then
            return ranchModel
        end
    end
    return nil
end

---comment
---@return RanchDataModel[]
function ServerRanchController:getListOfRanches()
    return self.ranchList
end

function ServerRanchController:loadAllRanches()
    local ranches = {}
    local ranchids = MySQL.Sync.fetchAll("SELECT ranchid FROM ranch")
    for _, ranchid in pairs(ranchids or {}) do
        local ranch = RanchDataModel.get(ranchid.ranchid)
        if ranch then
            table.insert(ranches, ranch)
        end
    end
    self.ranchList = ranches
end

ServerRPC.Callback.Register('bcc-ranch:getRanchData', function(source, cb, ranchid)
    while not ServerRanchControllerInstance do
        Wait(100)
    end
    cb(ServerRanchControllerInstance:getRanch(ranchid))
end)

ServerRPC.Callback.Register('bcc-ranch:getAllRanchData', function(source, cb)
    while not ServerRanchControllerInstance do
        Wait(100)
    end
    cb(ServerRanchControllerInstance:getListOfRanches())
end)