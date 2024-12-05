-- HUD十字线
local crosshair_lines = {
    ['BananaHUDFrameCrosshairTop'] = 'V',
    ['BananaHUDFrameCrosshairBottom'] = 'V',
    ['BananaHUDFrameCrosshairLeft'] = 'H',
    ['BananaHUDFrameCrosshairRight'] = 'H'
}
local function on_combat(combat)
    local t, r, g, b
    if combat then
        t, r, g, b = 2, 1, 0, 0
    else
        t, r, g, b = 1, 0, 0, 0
    end
    for line_name, orientation in pairs(crosshair_lines) do
        local line = getglobal(line_name)
        if orientation == 'V' then
            line:SetWidth(t)
        else
            line:SetHeight(t)
        end
        line:SetTexture(r, g, b)
    end
end
function BananaHUDFrame_OnLoad(self)
    UIParent:HookScript(
        'OnShow',
        function()
            self:Show()
        end
    )
    UIParent:HookScript(
        'OnHide',
        function()
            self:Hide()
        end
    )
    if UIParent:IsShown() then
        self:Show()
    else
        self:Hide()
    end
    self:RegisterEvent('PLAYER_REGEN_DISABLED')
    self:RegisterEvent('PLAYER_REGEN_ENABLED')
    on_combat(UnitAffectingCombat('player'))
end
function BananaHUDFrame_OnEvent(self, event, ...)
    if event == 'PLAYER_REGEN_DISABLED' then
        on_combat(true)
    elseif event == 'PLAYER_REGEN_ENABLED' then
        on_combat(false)
    end
end

-- 弹出对话框贴顶并移除边框
-- 测试代码：/run StaticPopup_Show("TAKE_GM_SURVEY");StaticPopup_Show("CONFIRM_RESET_INSTANCES");message("foo")
function StaticPopup_SetUpPosition(dialog)
    if (not tContains(StaticPopup_DisplayedFrames, dialog)) then
        local lastFrame = StaticPopup_DisplayedFrames[#StaticPopup_DisplayedFrames]
        if (lastFrame) then
            dialog:SetPoint('TOP', lastFrame, 'BOTTOM', 0, 0)
        else
            dialog:SetPoint('TOP', UIParent, 'TOP', 0, 0)
        end
        tinsert(StaticPopup_DisplayedFrames, dialog)
    end
end
local backdrop = {
    bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background',
    insets = {left = 5, right = 6, top = 6, bottom = 5}
}
for i = 1, STATICPOPUP_NUMDIALOGS do
    local dialog = _G['StaticPopup' .. i]
    dialog:SetBackdrop(backdrop)
end
BasicScriptErrors:SetBackdrop(backdrop)
BasicScriptErrors:ClearAllPoints()
BasicScriptErrors:SetPoint('TOP', 0, 0)

-- 提示信息置顶
-- 测试代码：/run UIErrorsFrame:AddMessage("UIErrorTest", 1.0, 0.1, 0.1);RaidNotice_AddMessage(RaidWarningFrame, "Raid Warning Test", ChatTypeInfo["RAID_WARNING"]);RaidNotice_AddMessage(RaidBossEmoteFrame, "Boss Emote Test", ChatTypeInfo["RAID_WARNING"])
UIErrorsFrame:SetPoint('TOP', 0, 0)
RaidWarningFrame:SetPoint('TOP', UIErrorsFrame, 'BOTTOM', 0, 0)
RaidBossEmoteFrame:SetPoint('TOP', RaidWarningFrame, 'BOTTOM', 0, 0)
ZoneTextFrame:ClearAllPoints() -- 默认是BOTTOM
ZoneTextFrame:SetPoint('TOP', 0, 0)
SubZoneTextFrame:ClearAllPoints() -- 默认是BOTTOM
SubZoneTextFrame:SetPoint('TOP', 0, 0)

-- 聊天框无需Alt键
function ChatEdit_ActivateChat(editBox)
    if (ACTIVE_CHAT_EDIT_BOX and ACTIVE_CHAT_EDIT_BOX ~= editBox) then
        ChatEdit_DeactivateChat(ACTIVE_CHAT_EDIT_BOX)
    end
    ACTIVE_CHAT_EDIT_BOX = editBox
    ChatEdit_SetLastActiveWindow(editBox)
    UIFrameFadeRemoveFrame(editBox)
    editBox:Show()
    editBox:SetFocus()
    editBox:SetFrameStrata('DIALOG')
    editBox:Raise()
    editBox.header:Show()
    editBox.focusLeft:Show()
    editBox.focusRight:Show()
    editBox.focusMid:Show()
    editBox:SetAlpha(1.0)
    ChatEdit_UpdateHeader(editBox)
    if (CHAT_SHOW_IME) then
        _G[editBox:GetName() .. 'Language']:Show()
    end
    editBox:SetAltArrowKeyMode(false) -- PATCH
end

-- 稍微增大迷你地图并调整相关部件
function GetMaxUIPanelsWidth()
    -- UIPanel.lua:2005
    -- PATCH 删掉MinimapCluster:GetLeft()相关，会减少能摆放的面板数量，否则比如同时打开商人界面和角色界面会出现bug
    return UIParent:GetRight() - UIParent:GetAttribute('RIGHT_OFFSET_BUFFER')
end
-- 注意MInimap偏心的问题，不能修正，否则打开“旋转迷你地图”选项更会偏
MinimapBorderTop:SetAlpha(0)
MinimapBorder:ClearAllPoints()
MinimapBorder:SetPoint('CENTER', Minimap, 'CENTER', 0, 0)
MinimapBorder:SetWidth(145)
MinimapBorder:SetHeight(145)
MinimapBorder:SetTexture('Interface\\AddOns\\BananaPreference\\Res\\MinimapBorder')
MinimapBorder:SetTexCoord(0, 1, 0, 1)
Minimap:SetMaskTexture('Interface\\AddOns\\BananaPreference\\Res\\MinimapMask')
MinimapCompassTexture:ClearAllPoints()
MinimapCompassTexture:SetPoint('CENTER', Minimap, 'CENTER', 0, 0)
local function scale_minimap()
    local use_ui_scale = GetCVar('useuiscale')
    local ui_scale = use_ui_scale == '1' and GetCVar('uiscale') or 0.9
    -- print('ui_scale=', ui_scale)
    local minimap_scale = (1.4 / ui_scale) * (1 - (1 - ui_scale) * 0.5)
    MinimapCluster:SetScale(minimap_scale)
    local buff_x_offset = -180 - MinimapCluster:GetWidth() * (minimap_scale - 1)
    ConsolidatedBuffs:SetPoint('TOPRIGHT', buff_x_offset, -13)
end
hooksecurefunc(
    'SetCVar',
    function(cvar, value, event)
        -- 只有这个有用，CVAR_UPDATE不一定fire，参见https://wowpedia.fandom.com/wiki/API_C_CVar.SetCVar?oldid=2222689，第三个参数不填则不会fire，hook UIParent的SetScale也没用
        -- cvar不区分大小写，但是这里因为是钩子函数，需要看blizzard代码写的什么，参见VideoOptionsPanels.xml:159,174
        -- print(cvar, value, event)
        if cvar == 'useUiScale' or cvar == 'uiscale' then
            scale_minimap()
        end
    end
)
scale_minimap()
Minimap:SetPlayerTexture('Interface\\AddOns\\BananaPreference\\Res\\MinimapArrow')
Minimap:SetScript(
    'OnMouseWheel',
    function(self, delta)
        if delta == 1 then
            MinimapZoomIn:Click()
        elseif delta == -1 then
            MinimapZoomOut:Click()
        end
    end
)
Minimap:EnableMouseWheel(true)
MinimapZoomIn:Hide()
MinimapZoomOut:Hide()
LoadAddOn('Blizzard_TimeManager')
TimeManagerClockButton:SetPoint('CENTER', 0, -70)
local clock_background_tex = 'Interface\\AddOns\\BananaPreference\\Res\\ClockBackground'
TimeManagerClockButton:GetRegions():SetTexture(clock_background_tex)
TimeManagerAlarmFiredTexture:SetTexture(clock_background_tex)
TimeManagerClockTicker:SetTextHeight(10) -- 中文版字体过大，修正为与英文版一致
-- TimeManagerAlarmFiredTexture:Show()
local tracking_border_tex = 'Interface\\AddOns\\BananaPreference\\Res\\MinimapTrackingBorder'
MiniMapMailBorder:SetTexture(tracking_border_tex)
MiniMapBattlefieldBorder:SetTexture(tracking_border_tex)
MiniMapWorldBorder:SetTexture(tracking_border_tex)
MiniMapWorldMapButtonIcon:SetSize(23, 23)
MiniMapTrackingButtonBorder:SetTexture(tracking_border_tex)
MiniMapTrackingIcon:ClearAllPoints()
MiniMapTrackingIcon:SetPoint('CENTER', MiniMapTracking, 'CENTER', 0, 1)
MiniMapTrackingIcon:SetSize(19, 19)
MiniMapTrackingButton:SetScript(
    'OnMouseDown',
    function()
        MiniMapTrackingIcon:SetPoint('CENTER', MiniMapTracking, 'CENTER', 1, 0)
        MiniMapTrackingIconOverlay:Show()
    end
)
MiniMapTrackingButton:SetScript(
    'OnMouseUp',
    function()
        MiniMapTrackingIcon:SetPoint('CENTER', MiniMapTracking, 'CENTER', 0, 1)
        MiniMapTrackingIconOverlay:Hide()
    end
)
MiniMapLFGFrameBorder:SetTexture(tracking_border_tex)
MiniMapLFGFrameIcon:ClearAllPoints()
MiniMapLFGFrameIcon:SetPoint('CENTER', 0, 1)
MiniMapRecordingBorder:SetTexture(tracking_border_tex)
MiniMapVoiceChatFrameBorder:SetTexture(tracking_border_tex)

-- 隐藏动作条装饰
MainMenuBarLeftEndCap:SetAlpha(0)
MainMenuBarRightEndCap:SetAlpha(0)

-- 调整宏界面字体
LoadAddOn('Blizzard_MacroUI')
MacroFrameText:SetFontObject('NumberFontNormal')

-- 放大世界地图玩家箭头
PlayerArrowEffectFrame:SetAlpha(1)
PlayerArrowEffectFrame:SetModelScale(1.4)
