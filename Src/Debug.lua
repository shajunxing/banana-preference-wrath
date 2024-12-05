local result = {}
local inspect

local function inspect_property(blank, obj)
    if obj.GetTexture then
        table.insert(result, blank .. '    GetTexture()= ' .. tostring(obj:GetTexture()))
    end
    if obj.GetText then
        table.insert(result, blank .. '    GetText()= ' .. tostring(obj:GetText()))
    end
    if obj.GetFont then
        local fname, fheight, fflags = obj:GetFont()
        if fname then
            table.insert(result, blank .. '    GetFont()= ' .. fname .. ' ' .. fheight .. ' ' .. fflags)
        end
    end
    if obj.GetNumPoints then
        for i = 1, obj:GetNumPoints() do
            local p, r, rp, x, y = obj:GetPoint(i)
            table.insert(result, blank .. '    GetPoint(' .. i .. ')= ' .. p .. ' ' .. tostring(r) .. ' ' .. rp .. ' ' .. x .. ' ' .. y)
        end
    end
    if obj.GetWidth then
        table.insert(result, blank .. '    GetWidth()= ' .. tostring(obj:GetWidth()))
    end
    if obj.GetHeight then
        table.insert(result, blank .. '    GetHeight()= ' .. tostring(obj:GetHeight()))
    end
    if obj.GetScale then
        table.insert(result, blank .. '    GetScale()= ' .. tostring(obj:GetScale()))
    end
    if obj.IsShown then
        table.insert(result, blank .. '    IsShown()= ' .. tostring(obj:IsShown()))
    end
    if obj.GetAlpha then
        table.insert(result, blank .. '    GetAlpha()= ' .. tostring(obj:GetAlpha()))
    end
    if obj.GetVertexColor then
        local r, g, b, a = obj:GetVertexColor()
        table.insert(result, blank .. '    GetVertexColor()= ' .. string.format('%d, %d, %d, %d', r, g, b, a))
    end
    if obj.GetDrawLayer then
        table.insert(result, blank .. '    GetDrawLayer()= ' .. tostring(obj:GetDrawLayer()))
    end
    if obj.GetFrameStrata then
        table.insert(result, blank .. '    GetFrameStrata()= ' .. tostring(obj:GetFrameStrata()))
    end
    if obj.GetFrameLevel then
        table.insert(result, blank .. '    GetFrameLevel()= ' .. tostring(obj:GetFrameLevel()))
    end
    if obj.GetScript then
        table.insert(result, blank .. '    OnLoad= ' .. tostring(obj:GetScript('OnLoad')))
        table.insert(result, blank .. '    OnShow= ' .. tostring(obj:GetScript('OnShow')))
        table.insert(result, blank .. '    OnUpdate= ' .. tostring(obj:GetScript('OnUpdate')))
    end
end

local function inspect_regions(level, ...)
    local blank = string.rep(' ', level * 4)
    for i = 1, select('#', ...) do
        local region = select(i, ...)
        local type = region:GetObjectType()
        local line = blank .. '<' .. tostring(type) .. '> ' .. tostring(region:GetName()) .. ' ' .. tostring(region)
        table.insert(result, line)
        inspect_property(blank, region)
    end
end

local function inspect_children(level, ...)
    for i = 1, select('#', ...) do
        inspect(level, select(i, ...))
    end
end

inspect = function(level, widget)
    local blank = string.rep(' ', level * 4)
    table.insert(result, blank .. '<' .. tostring(widget:GetObjectType()) .. '> ' .. tostring(widget:GetName()) .. ' ' .. tostring(widget))
    inspect_property(blank, widget)
    if widget.GetRegions then
        inspect_regions(level + 1, widget:GetRegions())
    end
    if widget.GetChildren then
        inspect_children(level + 1, widget:GetChildren())
    end
end

function BananaInspect(name)
    local frame = getglobal(name)
    if frame then
        inspect(0, frame)
        BananaOutputFrameEditorScrollFrameEditBox:SetText(table.concat(result, '|n'))
    else
        BananaOutputFrameEditorScrollFrameEditBox:SetText('"' .. name .. '" Not Found')
    end
    BananaOutputFrame:Show()
    result = {}
end

function BananaAddSlashCommand(callback, ...)
    local nargs = select('#', ...)
    assert(nargs > 0)
    local arg1 = select(1, ...)
    assert(string.len(arg1) > 1)
    assert(string.sub(arg1, 1, 1) == '/')
    local name = string.upper(string.sub(arg1, 2))
    SlashCmdList[name] = callback
    for i = 1, nargs do
        setglobal('SLASH_' .. name .. i, select(i, ...))
    end
end

BananaAddSlashCommand(BananaInspect, '/tinspect')

-- PATCH：E服地下城查找器确认进入时候的错误 Message: Interface\FrameXML\LFDFrame.lua:609: SetPortraitToTexture(): Couldn't find texture named '(null)'
function LFDDungeonReadyDialogReward_SetReward(button, dungeonID, rewardIndex)
    local name, texturePath, quantity = GetLFGDungeonRewardInfo(dungeonID, rewardIndex)
    if texturePath then
        pcall(SetPortraitToTexture, button.texture, texturePath)
    end
    button.rewardID = rewardIndex
    button:Show()
end

-- dump所有spell id和name，制作中英文字典用于自动翻译宏，中文复制粘贴需要用老版本ANSI版的记事本，否则都是乱码
BananaAddSlashCommand(
    function(...)
        local from, to = string.match(..., '(%d+)%s+(%d+)')
        if not from then
            print('Usage: /spellnames <from> <to>, from and to indicate spell id range.')
            return
        end
        local result = {}
        for id = tonumber(from), tonumber(to) do
            local name = GetSpellInfo(id)
            if name then
                name = string.gsub(name, "(['\"])", '\\%1')
                table.insert(result, string.format("[%d]='%s'", id, name))
            end
        end
        table.insert(result, '')
        BananaOutputFrameEditorScrollFrameEditBox:SetText(table.concat(result, ','))
        BananaOutputFrame:Show()
    end,
    '/spellnames'
)

BananaAddSlashCommand(
    function(...)
        print('测试')
    end,
    '/test'
)

-- PATCH：AzerothCore退出随机地下城队列的错误 Message: Interface\FrameXML\LFGFrame.lua:337: Unknown role: UNKNOWN
function GetTexCoordsForRole(role)
    local textureHeight, textureWidth = 256, 256
    local roleHeight, roleWidth = 67, 67
    if (role == 'GUIDE') then
        return GetTexCoordsByGrid(1, 1, textureWidth, textureHeight, roleWidth, roleHeight)
    elseif (role == 'TANK') then
        return GetTexCoordsByGrid(1, 2, textureWidth, textureHeight, roleWidth, roleHeight)
    elseif (role == 'HEALER') then
        return GetTexCoordsByGrid(2, 1, textureWidth, textureHeight, roleWidth, roleHeight)
    elseif (role == 'DAMAGER') then
        return GetTexCoordsByGrid(2, 2, textureWidth, textureHeight, roleWidth, roleHeight)
    else
        return GetTexCoordsByGrid(1, 1, textureWidth, textureHeight, roleWidth, roleHeight)
    end
end

-- 随机地下城确认对话框自动倒计时
-- 没用，会打印INTERFACE_ACTION_BLOCKED消息
-- https://wowpedia.fandom.com/wiki/API_AcceptProposal?oldid=2219351
-- (3.3.3: HW event required)
-- LFDDungeonReadyDialog:SetScript(
--     'OnShow',
--     function(self)
--         self.countdown = 6
--     end
-- )
-- LFDDungeonReadyDialog:SetScript(
--     'OnUpdate',
--     function(self, elapsed)
--         local countdown = self.countdown - elapsed
--         self.countdown = countdown
--         LFDDungeonReadyDialogEnterDungeonButton:SetText(string.format('Enter in %d s', math.ceil(countdown)))
--         if countdown < 0 then
--             AcceptProposal()
--         end
--     end
-- )

-- PATCH: Warmane服务器清楚目标会弹出游戏菜单，别的服务器不会，猜是不是ClearTarget()的返回值问题？
local prev_target_exists = UnitExists('target')
local target_exists = prev_target_exists
local frame = CreateFrame('Frame', nil, UIParent)
frame:SetScript(
    'OnEvent',
    function(self, event, ...)
        if event == 'PLAYER_TARGET_CHANGED' then
            prev_target_exists = target_exists
            target_exists = UnitExists('target')
        end
    end
)
frame:RegisterEvent('PLAYER_TARGET_CHANGED')
hooksecurefunc(
    'ToggleGameMenu',
    function()
        if prev_target_exists and not target_exists and GameMenuFrame:IsShown() then
            HideUIPanel(GameMenuFrame)
        end
        -- 此处需要把两个变量置空
        prev_target_exists = nil
        target_exists = nil
    end
)
