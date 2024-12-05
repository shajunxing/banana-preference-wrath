local function nameplate_on_load(frame, info)
    -- print('nameplate_on_load', frame)
    local health_bar, cast_bar = frame:GetChildren()
    health_bar:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
    cast_bar:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
    local _, _, _, _, _, _, name = frame:GetRegions()
    name:SetFont(NAMEPLATE_FONT, 14)
    name:SetShadowOffset(1.4, -1.4)
end

local function nameplate_on_show(frame, info)
    -- print('nameplate_on_show', frame)
    -- select(4, frame:GetRegions()):Show() -- 施法条
end

local function nameplate_on_update(frame, info)
    -- print('nameplate_on_update', frame)
end

local target_guid = nil
local target_nameplate = nil
-- 存在一个问题，某些不可攻击的目标，转变为可攻击之后本身姓名版因为尺寸太大不可见，那么BananaTargetFrame并不会转为显示
local target_attackable = nil

local function on_target_changed()
    -- print('on_target_changed', target_guid, target_nameplate)
    if target_guid then
        if target_nameplate then
            BananaTargetNameplate:SetParent(target_nameplate)
            BananaTargetNameplate:SetPoint('BOTTOMLEFT')
            BananaTargetNameplate:SetPoint('TOPRIGHT')
            BananaTargetNameplate:Show()
            BananaTargetFrame:Hide() -- BananaTargetFrame的显隐逻辑移到这里
        else
            BananaTargetNameplate:Hide()
            if (not UnitIsDead('target')) and target_attackable then
                BananaTargetFrame:Show()
            else
                BananaTargetFrame:Hide()
            end
        end
    else
        BananaTargetNameplate:Hide()
        BananaTargetFrame:Hide()
    end
end

local children_info = {}
local prev_target_guid = nil
local prev_target_nameplate = nil
local prev_target_attackable = nil

local function scan_children(...)
    local num_visible, num_opaque, first_opaque = 0, 0, nil
    for i = 1, select('#', ...) do
        local frame = select(i, ...)
        local info = children_info[frame]
        if not info then
            info = {}
            children_info[frame] = info
            local flash = frame:GetRegions()
            if flash and flash:GetObjectType() == 'Texture' and flash:GetTexture() == 'Interface\\TargetingFrame\\UI-TargetingFrame-Flash' then
                info.is_nameplate = true
                info.pending_on_show = true
                nameplate_on_load(frame, info)
            end
        end
        if info.is_nameplate then
            if frame:IsShown() then
                num_visible = num_visible + 1
                if frame:GetAlpha() == 1 then
                    num_opaque = num_opaque + 1
                    if not first_opaque then
                        first_opaque = frame
                    end
                end
                if info.pending_on_show then
                    nameplate_on_show(frame, info)
                    info.pending_on_show = false
                end
                nameplate_on_update(frame, info)
            else
                info.pending_on_show = true
            end
        end
    end
    -- 去重
    target_guid = UnitGUID('target')
    if target_guid ~= prev_target_guid then
        -- print('target_guid:', target_guid)
        on_target_changed()
        prev_target_guid = target_guid
    end
    target_nameplate = target_guid and first_opaque
    if target_nameplate ~= prev_target_nameplate then
        -- print('target_nameplate:', target_nameplate)
        on_target_changed()
        prev_target_nameplate = target_nameplate
    end
    target_attackable = UnitCanAttack('player', 'target')
    if target_attackable ~= prev_target_attackable then
        -- print('target_attackable:', target_attackable)
        on_target_changed()
        prev_target_attackable = target_attackable
    end
end

function BananaNameplateScanner_OnLoad(Self)
    on_target_changed()
end

function BananaNameplateScanner_OnUpdate(self)
    scan_children(WorldFrame:GetChildren())
end

function BananaTargetNameplate_OnLoad(self)
    self:RegisterEvent('PLAYER_ENTERING_WORLD')
    self:RegisterEvent('UNIT_HEALTH')
    self:RegisterEvent('UNIT_MAXHEALTH')
    self:RegisterEvent('UNIT_MANA')
    self:RegisterEvent('UNIT_RAGE')
    self:RegisterEvent('UNIT_FOCUS')
    self:RegisterEvent('UNIT_ENERGY')
    self:RegisterEvent('UNIT_HAPPINESS')
    self:RegisterEvent('UNIT_RUNIC_POWER')
    self:RegisterEvent('UNIT_MAXMANA')
    self:RegisterEvent('UNIT_MAXRAGE')
    self:RegisterEvent('UNIT_MAXFOCUS')
    self:RegisterEvent('UNIT_MAXENERGY')
    self:RegisterEvent('UNIT_MAXHAPPINESS')
    self:RegisterEvent('UNIT_MAXRUNIC_POWER')
    self:RegisterEvent('UNIT_DISPLAYPOWER')
    self:RegisterEvent('UNIT_AURA')
    self:RegisterEvent('PLAYER_TARGET_CHANGED')
end

local aura_size, aura_small_size, aura_spacing = 24, 16, 26

function BananaTargetNameplate_OnEvent(self, event, unit)
    local update_mana = false
    local update_auras = false
    if event == 'PLAYER_ENTERING_WORLD' or event == 'PLAYER_TARGET_CHANGED' then
        update_mana = true
        update_auras = true
    elseif unit == 'target' then
        if event == 'UNIT_AURA' then
            update_auras = true
        else
            update_mana = true
        end
    end
    if update_mana then
        BananaUpdateHealth(self, 'target')
        BananaUpdateMana(self, 'target')
    end
    if update_auras then
        BananaUpdateAuras(self, 'target', false, true, aura_size, nil, aura_spacing, 6, nil, nil, 'BOTTOMLEFT', self, 'TOPLEFT', 0, 4)
        BananaUpdateAuras(self, 'target', true, false, aura_size, nil, aura_spacing, 6, nil, true, 'TOPLEFT', self, 'BOTTOMLEFT', 0, -32)
    end
end
