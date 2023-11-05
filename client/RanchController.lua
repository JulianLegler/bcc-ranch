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
    for _, ranchDataModel in pairs(result) do
        table.insert(self.ranchList, RanchModel.initFromRanchDataModel(ranchDataModel))
    end
    return self
end

---comment
---@param ranchid number
---@return RanchModel |nil
function RanchController:getRanch(ranchid)
    for _, ranchModel in pairs(RanchController.ranchList) do
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