----- Close Menu When Backspaced Out(Creation menu needed to seperate them if you owna  ranch dont close via distance check while making a ranch) -----
Inmenu, CreationMenu = false, false
local charid, ownerSource = nil, nil

------ Creating Ranch Menu ------
RegisterNetEvent('bcc-ranch:CreateRanchmenu', function()
    CreateRanchMen()
end)

function CreateRanchMen()
    local ranchName, ranchRadius, taxes
    local coords = GetEntityCoords(PlayerPedId())
    Inmenu = true
    CreationMenu = true

    local elements = {
        { label = _U("StaticId"),         value = 'staticid',    desc = _U("StaticId_desc") },
        { label = _U("NameRanch"),        value = 'nameranch',   desc = _U("NameRanch_desc") },
        { label = _U("RanchRadiusLimit"), value = 'radiuslimit', desc = _U("RanchRadiusLimit_desc") },
        { label = _U("TaxAmount"),        value = 'taxes',       desc = _U("TaxAmount") },
        { label = _U("Confirm"),          value = 'confirm',     desc = _U("Confirm_desc") }
    }

    MenuData.Open('default', GetCurrentResourceName(), 'menuapi',
        {
            title = _U("CreateRanchTitle"),
            align = 'top-left',
            elements = elements,
        },
        function(data, menu)
            if data.current == 'backup' then
                _G[data.trigger]()
            end
            local selectedOption = {
                ['staticid'] = function()
                    menu.close()
                    PlayerList()
                end,
                ['nameranch'] = function()
                    local myInput = {
                        type = "enableinput",                                               -- don't touch
                        inputType = "textarea",                                             -- input type
                        button = _U("Confirm"),                                             -- button name
                        placeholder = _U("NameRanch"),                                      -- placeholder name
                        style = "block",                                                    -- don't touch
                        attributes = {
                            inputHeader = "",                                               -- header
                            type = "text",                                                  -- inputype text, number,date,textarea ETC
                            pattern = "[A-Za-z]+",                                          --  only numbers "[0-9]" | for letters only "[A-Za-z]+"
                            title = _U("InvalidInput"),                                     -- if input doesnt match show this message
                            style = "border-radius: 10px; background-color: ; border:none;" -- style
                        }
                    }
                    TriggerEvent("vorpinputs:advancedInput", json.encode(myInput), function(result)
                        if result ~= '' and result then
                            ranchName = result
                            VORPcore.NotifyRightTip(_U("nameSet"), 4000)
                        else
                            VORPcore.NotifyRightTip(_U("InvalidInput"), 4000)
                        end
                    end)
                end,
                ['taxes'] = function()
                    local myInput = {
                        type = "enableinput",                                               -- don't touch
                        inputType = "textarea",                                             -- input type
                        button = _U("Confirm"),                                             -- button name
                        placeholder = _U("TaxAmount"),                                      -- placeholder name
                        style = "block",                                                    -- don't touch
                        attributes = {
                            inputHeader = "",                                               -- header
                            type = "number",                                                -- inputype text, number,date,textarea ETC
                            pattern = "[0-9]",                                              --  only numbers "[0-9]" | for letters only "[A-Za-z]+"
                            title = _U("InvalidInput"),                                     -- if input doesnt match show this message
                            style = "border-radius: 10px; background-color: ; border:none;" -- style
                        }
                    }
                    TriggerEvent("vorpinputs:advancedInput", json.encode(myInput), function(result)
                        if result ~= '' and result then
                            taxes = result
                            VORPcore.NotifyRightTip(_U("taxesSet"), 4000)
                        else
                            VORPcore.NotifyRightTip(_U("InvalidInput"), 4000)
                        end
                    end)
                end,
                ['radiuslimit'] = function()
                    local myInput = {
                        type = "enableinput",                                               -- don't touch
                        inputType = "input",                                                -- input type
                        button = _U("Confirm"),                                             -- button name
                        placeholder = _U("RanchRadiusLimit"),                               -- placeholder name
                        style = "block",                                                    -- don't touch
                        attributes = {
                            inputHeader = "",                                               -- header
                            type = "number",                                                -- inputype text, number,date,textarea ETC
                            pattern = "[0-9]",                                              --  only numbers "[0-9]" | for letters only "[A-Za-z]+"
                            title = _U("InvalidInput"),                                     -- if input doesnt match show this message
                            style = "border-radius: 10px; background-color: ; border:none;" -- style
                        }
                    }
                    TriggerEvent("vorpinputs:advancedInput", json.encode(myInput), function(result)
                        if tonumber(result) > 0 then
                            ranchRadius = tonumber(result)
                            VORPcore.NotifyRightTip(_U("radiusSet"), 4000)
                        else
                            VORPcore.NotifyRightTip(_U("InvalidInput"), 4000)
                        end
                    end)
                end,
                ['confirm'] = function()
                    TriggerServerEvent('bcc-ranch:InsertCreatedRanchIntoDB', ranchName, ranchRadius, charid, coords,
                        taxes, ownerSource)
                    charid = nil
                    Inmenu = false
                    CreationMenu = false
                    MenuData.CloseAll()
                end
            }

            if selectedOption[data.current.value] then
                selectedOption[data.current.value]()
            end
        end,
        function(data, menu)
            CreationMenu = false
            Inmenu = false
            menu.close()
        end)
end

--------- Show the player list credit to vorp admin for this
function PlayerList()
    MenuData.CloseAll()
    local elements = {}
    local players = GetPlayers()

    table.sort(players, function(a, b)
        return a.serverId < b.serverId
    end)

    for k, playersInfo in pairs(players) do
        elements[#elements + 1] = {
            label = playersInfo.PlayerName .. "<br> " .. _U("CharacterStaticId") .. ' ' .. playersInfo.staticid,
            value = "players" .. k,
            desc = _U("StaticId") .. "<span style=color:MediumSeaGreen;> ",
            info = playersInfo
        }
    end

    MenuData.Open('default', GetCurrentResourceName(), 'menuapi',
        {
            title      = _U("StaticId"),
            subtext    = _U("StaticId_desc"),
            align      = 'top-left',
            elements   = elements,
            lastmenu   = 'CreateRanchMen',
            itemHeight = "4vh",
        },
        function(data, menu)
            if data.current == 'backup' then
                _G[data.trigger]()
            end
            if data.current.value then
                charid = data.current.info.staticid
                ownerSource = data.current.info.serverId
                VORPcore.NotifyRightTip(_U("OwnerSet"), 4000)
                menu.close() --if this is not here this will cause an error dunno why menuapi sucks menuapi is better end of discussion
                CreateRanchMen()
            end
        end,
        function(data, menu)
            menu.close()
            CreateRanchMen()
        end)
end
