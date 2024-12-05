function BananaUpdateAuras(frame, unit, is_debuff, include_others, size_by_player, size_by_others, spacing, num_per_row, right_to_left, up_to_down, ...)
    local frame_name = frame:GetName()
    local aura_prefix = frame_name .. unit:gsub('^%l', string.upper) .. (is_debuff and 'Debuff' or 'Buff')
    local aura_func = is_debuff and UnitDebuff or UnitBuff
    size_by_player = size_by_player or 32
    spacing = spacing or 36
    num_per_row = num_per_row or 3
    local i = 1
    local first_aura
    while true do
        local name, rank, icon, count, debuff_type, duration, expir_time, caster, is_stealable = aura_func(unit, i)
        -- print(unit, i, name, icon)
        if not icon then
            break
        end
        local is_others = not (caster == 'player' or caster == 'pet' or caster == 'vehicle')
        if is_others and (not include_others) then
            break
        end
        local aura_name = aura_prefix .. i
        local aura = _G[aura_name]
        if not aura then
            aura = CreateFrame('Frame', aura_name, frame, 'BananaAuraFrameTemplate')
            aura:SetParent(frame)
        end
        -- 设置图标位置
        if i == 1 then
            if ... then
                aura:SetPoint(...)
            else
                aura:SetPoint('CENTER')
            end
            first_aura = aura
        else
            -- https://stackoverflow.com/questions/9695697/lua-replacement-for-the-operator
            local row = math.floor((i - 1) / num_per_row)
            local col = (i - 1) - row * num_per_row
            local offs_x = col * spacing * (right_to_left and -1 or 1)
            local offs_y = row * spacing * (up_to_down and -1 or 1)
            aura:SetPoint('CENTER', first_aura, 'CENTER', offs_x, offs_y)
        end
        -- 设置图标内容
        _G[aura_name .. 'Icon']:SetTexture(icon)
        aura_count = _G[aura_name .. 'Count']
        if count > 1 then
            aura_count:SetText(count)
            aura_count:Show()
        else
            aura_count:Hide()
        end
        aura_cooldown = _G[aura_name .. 'Cooldown']
        if (duration > 0) then
            aura_cooldown:Show()
            CooldownFrame_SetTimer(aura_cooldown, expir_time - duration, duration, 1)
        else
            aura_cooldown:Hide()
        end
        local aura_border = _G[aura_name .. 'Border']
        if is_debuff then
            local color
            if (debuff_type) then
                color = DebuffTypeColor[debuff_type]
            else
                color = DebuffTypeColor['none']
            end
            aura_border:SetVertexColor(color.r, color.g, color.b)
            aura_border:Show()
        else
            aura_border:Hide()
        end
        local aura_stealable = _G[aura_name .. 'Stealable']
        if is_stealable then
            aura_stealable:Show()
        else
            aura_stealable:Hide()
        end
        if size_by_others and is_others then
            aura:SetSize(size_by_others, size_by_others)
        else
            aura:SetSize(size_by_player, size_by_player)
        end
        -- 显示图标
        aura:Show()
        i = i + 1
    end
    while true do
        -- 隐藏剩余的图标
        local aura_name = aura_prefix .. i
        local aura = _G[aura_name]
        if aura then
            aura:Hide()
        else
            break
        end
        i = i + 1
    end
end

-- 调整颜色，红色减弱，绿色大量减弱，蓝色加亮
local function adjust_color(r, g, b)
    -- 把颜色值钳制入某个范围（0->pmin, 1->pmax）
    local function clamp(v, pmin, pmax)
        return pmin + (pmax - pmin) * v
    end
    return clamp(r, 0.1, 0.9), clamp(g, 0.1, 0.8), clamp(b, 0, 1)
end

function BananaUpdateHealth(frame, unit)
    local frame_name = frame:GetName()
    local health_bar = _G[frame_name .. 'HealthBar']
    health_bar:SetMinMaxValues(0, UnitHealthMax(unit))
    local health = UnitHealth(unit)
    health_bar:SetValue(health)
    _G[frame_name .. 'HealthBarText']:SetText(health == 0 and '' or health)
    local r, g, b = 0, 0, 1 -- 默认蓝色，加亮
    if UnitPlayerControlled(unit) then
        if unit == 'player' or unit == 'pet' or UnitIsUnit(unit, 'player') then -- 自己和宠物
            r, g, b = 0, 1, 0
        elseif UnitIsFriend('player', unit) and (not UnitIsPlayer(unit)) then -- 友方宠物
            r, g, b = 0, 1, 0
        elseif UnitIsEnemy('player', unit) then -- 敌方玩家和宠物
            if UnitIsPlayer(unit) and GetCVar('ShowClassColorInNameplate') == '1' then
                local color = RAID_CLASS_COLORS[select(2, UnitClass(unit))]
                if color then
                    r, g, b = color.r, color.g, color.b
                else
                    r, g, b = 1, 0, 0
                end
            else
                r, g, b = 1, 0, 0
            end
        end
    elseif (UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit)) then
        r, g, b = 0.5, 0.5, 0.5
    else
        -- local reaction = UnitReaction(unit, 'player')
        -- if reaction then
        --     r = FACTION_BAR_COLORS[reaction].r
        --     g = FACTION_BAR_COLORS[reaction].g
        --     b = FACTION_BAR_COLORS[reaction].b
        -- end
        -- TargetFrame.lua:268
        r, g, b = UnitSelectionColor(unit)
    end
    health_bar:SetStatusBarColor(r, g, b)
end

-- UnitFrame.lua:2
local power_bar_colors = {}
power_bar_colors['MANA'] = {r = 0.04, g = 0.44, b = 0.95} -- 10.0浅色风格
power_bar_colors['RAGE'] = {r = 1.00, g = 0.00, b = 0.00}
power_bar_colors['FOCUS'] = {r = 1.00, g = 0.50, b = 0.25}
power_bar_colors['ENERGY'] = {r = 1.00, g = 1.00, b = 0.00}
power_bar_colors['HAPPINESS'] = {r = 0.00, g = 1.00, b = 1.00}
power_bar_colors['RUNES'] = {r = 0.50, g = 0.50, b = 0.50}
power_bar_colors['RUNIC_POWER'] = {r = 0.00, g = 0.82, b = 1.00}
power_bar_colors['AMMOSLOT'] = {r = 0.80, g = 0.60, b = 0.00}
power_bar_colors['FUEL'] = {r = 0.0, g = 0.55, b = 0.5}
power_bar_colors[0] = power_bar_colors['MANA']
power_bar_colors[1] = power_bar_colors['RAGE']
power_bar_colors[2] = power_bar_colors['FOCUS']
power_bar_colors[3] = power_bar_colors['ENERGY']
power_bar_colors[4] = power_bar_colors['HAPPINESS']
power_bar_colors[5] = power_bar_colors['RUNES']
power_bar_colors[6] = power_bar_colors['RUNIC_POWER']

function BananaUpdateMana(frame, unit)
    local frame_name = frame:GetName()
    local mana_bar = _G[frame_name .. 'ManaBar']
    mana_bar:SetMinMaxValues(0, UnitManaMax(unit))
    local mana = UnitMana(unit)
    mana_bar:SetValue(mana)
    _G[frame_name .. 'ManaBarText']:SetText(mana == 0 and '' or mana)
    -- 参考：UnitFrame.lua:161
    local r, g, b
    local power_type, power_token, alt_r, alt_g, alt_b = UnitPowerType(unit)
    local info = power_bar_colors[power_token] or power_bar_colors[power_type]
    if info then
        r, g, b = info.r, info.g, info.b
    elseif alt_r then
        r, g, b = alt_r, alt_g, alt_b
    else
        info = power_bar_colors['MANA']
        r, g, b = info.r, info.g, info.b
    end
    mana_bar:SetStatusBarColor(r, g, b)
    -- 系统界面的法力值会连续平滑变化，貌似是CVar predictedPower，见UnitFrame.lua:347，待研究
end

function BananaUpdateGlow(frame, show, r, g, b)
    local indicator = _G[frame:GetName() .. 'Glow']
    if show then
        indicator:SetBackdropBorderColor(r, g, b, 0.8)
        indicator:Show()
    else
        indicator:Hide()
    end
end

local aura_size, aura_spacing = 24, 26
local aura_small_size, aura_small_spacing = 20, 22
local is_deathknight

function BananaPlayerFrame_OnLoad(self)
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
    self:RegisterEvent('UNIT_THREAT_SITUATION_UPDATE')
    local self_name = self:GetName()
    _G[self_name .. 'HealthBarText']:Hide()
    _G[self_name .. 'ManaBarText']:Hide()
    is_deathknight = select(2, UnitClass('player')) == 'DEATHKNIGHT'
    local rune_frame = _G[self:GetName() .. 'RuneFrame']
    if is_deathknight then
        rune_frame:Show()
    else
        rune_frame:Hide()
    end
    -- self:SetScale(1.6)
end

function BananaPlayerFrame_OnEvent(self, event, unit)
    local update_health_mana = false
    local update_auras = false
    local update_threat = false
    if event == 'PLAYER_ENTERING_WORLD' then
        update_health_mana = true
        update_auras = true
        update_threat = true
    elseif event == 'UNIT_THREAT_SITUATION_UPDATE' and unit == 'player' then
        update_threat = true
    elseif unit == 'player' then
        if event == 'UNIT_AURA' then
            update_auras = true
        else
            update_health_mana = true
        end
    end
    if update_health_mana then
        BananaUpdateHealth(self, 'player')
        BananaUpdateMana(self, 'player')
    end
    if update_auras then
        BananaUpdateAuras(self, 'player', false, false, aura_size, nil, aura_spacing, 5, nil, true, 'TOPLEFT', self, 'BOTTOMLEFT', 3, is_deathknight and -28 or -6)
        BananaUpdateAuras(self, 'player', true, true, aura_size, nil, aura_spacing, 5, nil, nil, 'BOTTOMLEFT', self, 'TOPLEFT', 3, 6)
    end
    if update_threat then
        local status = UnitThreatSituation('player')
        if status and status > 0 then
            BananaUpdateGlow(self, true, GetThreatStatusColor(status))
        else
            BananaUpdateGlow(self, false)
        end
    end
end

function BananaPetFrame_OnLoad(self)
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
    self:RegisterEvent('UNIT_PET')
    self:RegisterEvent('UNIT_THREAT_SITUATION_UPDATE')
    local self_name = self:GetName()
    _G[self_name .. 'HealthBarText']:Hide()
    _G[self_name .. 'ManaBarText']:Hide()
end

function BananaPetFrame_OnEvent(self, event, unit)
    local update_visible = false
    local update_health_mana = false
    local update_auras = false
    local update_threat = false
    if event == 'PLAYER_ENTERING_WORLD' or (event == 'UNIT_PET' and unit == 'player') then
        -- print(event, unit)
        update_visible = true
        update_health_mana = true
        update_auras = true
        update_threat = true
    elseif event == 'UNIT_THREAT_SITUATION_UPDATE' and unit == 'pet' then
        update_threat = true
    elseif unit == 'pet' then
        if event == 'UNIT_AURA' then
            update_auras = true
        else
            update_health_mana = true
        end
    end
    if update_visible then
        if UnitExists('pet') then
            self:Show()
        else
            self:Hide()
        end
    end
    if update_health_mana then
        BananaUpdateHealth(self, 'pet')
        BananaUpdateMana(self, 'pet')
    end
    if update_auras then
        BananaUpdateAuras(self, 'pet', false, false, aura_small_size, nil, aura_small_spacing, 3, nil, true, 'TOPLEFT', self, 'BOTTOMLEFT', 3, -6)
        BananaUpdateAuras(self, 'pet', true, true, aura_small_size, nil, aura_small_spacing, 3, nil, nil, 'BOTTOMLEFT', self, 'TOPLEFT', 3, 6)
    end
    if update_threat then
        local status = UnitThreatSituation('pet')
        if status and status > 0 then
            BananaUpdateGlow(self, true, GetThreatStatusColor(status))
        else
            BananaUpdateGlow(self, false)
        end
    end
end

function BananaTargetFrame_OnLoad(self)
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
    self:RegisterEvent('UNIT_THREAT_SITUATION_UPDATE')
    -- self:SetScale(1.8)
end

function BananaTargetFrame_OnEvent(self, event, unit)
    local update_name = false
    local update_health_mana = false
    local update_auras = false
    local update_threat = false
    if event == 'PLAYER_ENTERING_WORLD' or event == 'PLAYER_TARGET_CHANGED' then
        update_name = true
        update_health_mana = true
        update_auras = true
        update_threat = true
    elseif event == 'UNIT_THREAT_SITUATION_UPDATE' and unit == 'player' then
        update_threat = true
    elseif unit == 'target' then
        if event == 'UNIT_AURA' then
            update_auras = true
        else
            update_health_mana = true
        end
    end
    if update_name then
        getglobal(self:GetName() .. 'Name'):SetText(UnitName('target'))
    end
    if update_health_mana then
        BananaUpdateHealth(self, 'target')
        BananaUpdateMana(self, 'target')
    end
    if update_auras then
        BananaUpdateAuras(self, 'target', false, true, aura_size, nil, aura_spacing, 11, nil, nil, 'BOTTOMLEFT', self, 'TOPLEFT', 0, 20)
        BananaUpdateAuras(self, 'target', true, false, aura_size, nil, aura_spacing, 11, nil, true, 'TOPLEFT', self, 'BOTTOMLEFT', 0, -36)
    end
    if update_threat then
        local status = UnitThreatSituation('player', 'target')
        if status and status > 0 then
            BananaUpdateGlow(self, true, GetThreatStatusColor(status))
        else
            BananaUpdateGlow(self, false)
        end
    end
end
