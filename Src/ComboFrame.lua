local function shine_fade_out(shine)
    UIFrameFadeOut(shine, COMBOFRAME_SHINE_FADE_OUT)
end

local function shine_fade_in(shine)
    UIFrameFade(
        shine,
        {
            mode = 'IN',
            timeToFade = COMBOFRAME_SHINE_FADE_IN,
            finishedFunc = shine_fade_out,
            finishedArg1 = shine
        }
    )
end

function BananaComboPoint_OnShow(self)
    local self_name = self:GetName()
    local highlight = _G[self_name .. 'Highlight']
    local shine = _G[self_name .. 'Shine']
    UIFrameFade(
        highlight,
        {
            mode = 'IN',
            timeToFade = COMBOFRAME_HIGHLIGHT_FADE_IN,
            finishedFunc = shine_fade_in,
            finishedArg1 = shine
        }
    )
end

function BananaComboFrame_OnLoad(self)
    self:RegisterEvent('PLAYER_ENTERING_WORLD')
    self:RegisterEvent('PLAYER_TARGET_CHANGED')
    self:RegisterEvent('UNIT_COMBO_POINTS')
end

function BananaComboFrame_OnEvent(self, event, unit)
    if event == 'PLAYER_ENTERING_WORLD' or event == 'PLAYER_TARGET_CHANGED' or (event == 'UNIT_COMBO_POINTS' and unit == 'player') then
        local numpoints = GetComboPoints('player', 'target')
        if numpoints > 0 then
            local self_name = self:GetName()
            for i = 1, MAX_COMBO_POINTS do
                local combopoint = _G[self_name .. 'ComboPoint' .. i]
                if i <= numpoints then
                    combopoint:Show()
                else
                    combopoint:Hide()
                end
            end
            self:Show()
        else
            self:Hide()
        end
    end
end
