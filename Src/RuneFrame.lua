local rune_textures = {
    'Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Blood',
    'Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Unholy',
    'Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Frost',
    'Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Death'
}

local function update_type(frame, id)
    local icon = _G[frame:GetName() .. 'Button' .. id .. 'Icon']
    if not icon then
        return
    end
    icon:SetTexture(rune_textures[GetRuneType(id)])
end

local function update_power(frame, id)
    local cooldown = _G[frame:GetName() .. 'Button' .. id .. 'Cooldown']
    if not cooldown then -- 会有超过6的id，不知是不是私服问题
        return
    end
    local start, duration, ready = GetRuneCooldown(id)
    cooldown:SetCooldown(start, duration)
end

function BananaRuneFrame_OnLoad(self)
    self:RegisterEvent('PLAYER_ENTERING_WORLD')
    self:RegisterEvent('RUNE_TYPE_UPDATE')
    self:RegisterEvent('RUNE_POWER_UPDATE')
end

function BananaRuneFrame_OnEvent(self, event, id, ...)
    -- print(event, id, ...)
    if event == 'PLAYER_ENTERING_WORLD' then
        for i = 1, 6 do
            update_type(self, i)
            update_power(self, i)
        end
    elseif event == 'RUNE_TYPE_UPDATE' then
        update_type(self, id)
    elseif event == 'RUNE_POWER_UPDATE' then
        update_power(self, id)
    end
end
