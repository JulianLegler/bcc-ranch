---@class RanchController
---@field ranchList RanchModel[]
RanchController = {}
RanchController.__index = RanchController



function RanchController.new()
    local self = setmetatable({}, RanchController)
    self.ranchList = {}
    local result = ClientRPC.Callback.TriggerAwait('bcc-ranch:getAllRanchData') ---@type RanchDataModel[]
    if not result then
        print("RanchController.new() - ClientRPC.Callback.TriggerAwait('bcc-ranch:getAllRanchData') returned false")
        return nil
    end
    print(string.format("RanchController.new() - ClientRPC.Callback.TriggerAwait('bcc-ranch:getAllRanchData') returned %s ranches", #result))
    for _, ranchDataModel in pairs(result) do
        table.insert(self.ranchList, RanchModel.initFromRanchDataModel(ranchDataModel))
    end
    return self
end

---comment
---@param ranchid number
---@return RanchModel |nil
function RanchController:getRanch(ranchid)
    for _, ranchModel in pairs(self.ranchList) do
        if ranchModel.ranchid == ranchid then
            return ranchModel
        end
    end
    return nil
end

---comment
---@return RanchModel[]
function RanchController:getListOfRanches()
    return self.ranchList
end

ClientRPC.Callback.Register('bcc-ranch:ranchDataChanged', function (cb, ranchDataModel)
    print(string.format("RanchController: ranchDataChanged - ranchid: %s, data: %s, ", ranchDataModel.ranchid, json.encode(ranchDataModel)))
    local ranchModel = RanchControllerInstance:getRanch(ranchDataModel.ranchid)
    if ranchModel then
        ranchModel:updateFromRanchDataModel(ranchDataModel)
    else
        table.insert(RanchController.ranchList, RanchModel.initFromRanchDataModel(ranchDataModel))
    end
end)