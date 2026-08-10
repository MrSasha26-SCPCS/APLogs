local GameObject = CS.UnityEngine.GameObject
local Vector2 = CS.UnityEngine.Vector2
local Vector3 = CS.UnityEngine.Vector3

-- Local funcs
local function split(inputstr, sep)
   if sep == nil then
      sep = "%s"
   end
   local t = {}
   for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
      table.insert(t, str)
   end
   return t
end

local function toTable(g)
    local myTable = {}
    for i = 0, g.Count - 1 do
        table.insert(myTable, g[i])
    end
    return myTable
end

local function getIndex(tab, val)
    for i, value in ipairs(tab) do
        if value == val then
            return i
        end
    end
    return -1
end
--

APLogs = {}

-- server
APLogs.connectedPlayers = {}

-- client
APLogs.logs = {}

function APLogs:Init()
    if self.main.adminPanel.isServer then
        -- Other hoooks
        CS.HookManager.Add(self.main.adminPanel.gameObject, "onPlayerCreated", function(obj)
            self.main:Invoke(function() 
                if obj[0] == nil then return end

                CS.HookManager.Run("APLog", "<color=yellow>" .. obj[0].accountName .. "</color> <color=red>[" .. obj[0].accountUID .. "]</color> присоединился к игре")
            end, 0.5)
        end)
        CS.HookManager.Add(self.main.adminPanel.gameObject, "onPlayerDeath", function(obj)
            if obj[0] == nil or obj[1] == nil then return end
            if obj[1].killer == nil then return end

            local diedPly = "<color=yellow>" .. obj[0].accountName .. "</color> <color=green>[" .. obj[0].accountUID .. "]</color>"
            local killer = "<color=yellow>" .. obj[1].killer.accountName .. "</color> <color=red>[" .. obj[1].killer.accountUID .. "]</color>"

            CS.HookManager.Run("APLog", "Игрок " .. diedPly .. " был убит " .. killer, 
            "ID аккаунта <color=red>убийцы</color>|ID устройства <color=red>убийцы</color>|IP <color=red>убийцы</color>", 
            obj[1].killer.accountUID .. "|" .. obj[1].killer.deviceID[0] .. "|" .. obj[1].killer.connectionToClient.address)
        end)
        
        -- Main hook
        CS.HookManager.Add(self.main.adminPanel.gameObject, "APLog", function(obj)
            local text = obj[0]  
            local copyNames = nil
            local copyStrs = nil
            if obj.Length >= 3 then
                copyNames = obj[1]
                copyStrs = obj[2]
            end
            if text == nil then return end

            local players = GameObject.FindObjectsOfType(typeof(CS.Player))
            for i = 0, players.Length - 1 do
                local ply = players[i]
                if ply.rights == nil then goto continue end
                if getIndex(toTable(ply.rights), "logs") ~= -1 or getIndex(toTable(ply.rights), "all") ~= -1 then 
                    if copyNames ~= nil and copyStrs ~= nil then
                        self.main:SendToClient("AddLog", ply.connectionToClient, text, copyNames, copyStrs)
                    else
                        self.main:SendToClient("AddLog", ply.connectionToClient, text)
                    end
                end
                ::continue::
            end
        end)
    end
end

function APLogs:GetName()
    return "LOGS"
end

function APLogs:OnOpen()
    if not self.main.adminPanel.isClient then return end
    if #self.logs == 0 then 
        self.main.adminPanel:CreateText("<size=21><color=#BBBBBB>Пока-что логов нет</color></size>"):GetComponent(typeof(CS.UnityEngine.UI.Text)).alignment = CS.UnityEngine.TextAnchor.MiddleCenter
    else
        for _, info in ipairs(self.logs) do
            local txt = info[1]
            local btnsNames = info[2]
            local copys = info[3]

            if txt == nil then return end

            local text_obj = self.main.adminPanel:CreateText(txt)
            local text_text = text_obj:GetComponent(typeof(CS.UnityEngine.UI.Text))
            text_text.alignment = CS.UnityEngine.TextAnchor.MiddleLeft
            text_text.fontSize = 17

            local CSF = text_obj.gameObject:AddComponent(typeof(CS.UnityEngine.UI.ContentSizeFitter))
            CSF.verticalFit = CS.UnityEngine.UI.ContentSizeFitter.FitMode.PreferredSize 

            if btnsNames == nil or copys == nil then goto continue end

            self.main.adminPanel:CreateText("<size=21>Копировать...</size>"):GetComponent(typeof(CS.UnityEngine.UI.Text)).alignment = CS.UnityEngine.TextAnchor.MiddleCenter

            local layout_tr = self.main.adminPanel:CreateHorizontalGroup().transform

            for i, name in ipairs(btnsNames) do    
                local btn = self.main.adminPanel:CreateButton(name, layout_tr)

                CS.UIManager.BindAction(btn:GetComponent(typeof(CS.UnityEngine.UI.Button)).onClick, 
                function() 
                    CS.UnityEngine.GUIUtility.systemCopyBuffer = copys[i] 
                end)
            end

            ::continue::
        end
    end
end

-- CLIENT
function APLogs:AddLog(msg, copyNames_str, copyStrs_str)
    local copyNames = nil
    local copyStrs = nil
    if copyNames_str ~= nil and copyStrs_str ~= nil then
        copyNames = split(copyNames_str, "|")
        copyStrs = split(copyStrs_str, "|")
    end
    table.insert(self.logs, {msg, copyNames, copyStrs})
end

return APLogs