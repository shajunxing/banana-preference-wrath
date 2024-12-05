BANANA_ACTION_BUTTON_SIZE = 32

-- 3.3.5的代码加上了安全代码，还不如看看1.12.1的，但是有actionpage等概念依旧有些麻烦，还是用sync吧

local function sync_method(src, dst, set, get)
    if src[set] and dst[set] then
        hooksecurefunc(
            src,
            set,
            function(self, ...)
                dst[set](dst, ...)
            end
        )
        if get and src[get] and dst[get] then
            dst[set](dst, src[get](src))
        end
    end
end

local function sync_object(src, dst)
    sync_method(src, dst, 'Show') -- ScriptRegion
    sync_method(src, dst, 'Hide')
    if src.IsShown and dst.Show and dst.Hide then
        if src:IsShown() then
            dst:Show()
        else
            dst:Hide()
        end
    end
    sync_method(src, dst, 'SetAlpha', 'GetAlpha') -- Region
    sync_method(src, dst, 'SetVertexColor', 'GetVertexColor')
    sync_method(src, dst, 'SetTexture', 'GetTexture') -- TextureBase
    sync_method(src, dst, 'SetDesaturated', 'IsDesaturated')
    sync_method(src, dst, 'SetText', 'GetText') -- FontString
    sync_method(src, dst, 'SetButtonState', 'GetButtonState') -- Button按下的状态，只对键盘有效，鼠标无效
    sync_method(src, dst, 'SetNormalTexture')
    if src.GetNormalTexture and dst.SetNormalTexture then
        dst:SetNormalTexture(src:GetNormalTexture():GetTexture())
    end
    sync_method(src, dst, 'SetPushedTexture')
    if src.GetPushedTexture and dst.SetPushedTexture then
        dst:SetPushedTexture(src:GetPushedTexture():GetTexture())
    end
    sync_method(src, dst, 'SetHighlightTexture')
    if src.GetHighlightTexture and dst.SetHighlightTexture then
        dst:SetHighlightTexture(src:GetHighlightTexture():GetTexture())
    end
    sync_method(src, dst, 'SetChecked', 'GetChecked') -- CheckButton
    sync_method(src, dst, 'SetCheckedTexture')
    if src.GetCheckedTexture and dst.SetCheckedTexture then
        dst:SetCheckedTexture(src:GetCheckedTexture():GetTexture())
    end
    sync_method(src, dst, 'SetCooldown') -- Cooldown
    sync_method(src, dst, 'SetMinMaxValues', 'GetMinMaxValues') -- StatusBar
    sync_method(src, dst, 'SetValue', 'GetValue')
    sync_method(src, dst, 'SetStatusBarColor', 'GetStatusBarColor')
end

function BananaActionButton_OnLoad(self)
    self:EnableKeyboard(false)
    self:EnableMouse(false)
    self:EnableMouseWheel(false)
    local self_name = self:GetName()
    local sync = _G[string.match(self_name, 'Banana(.+)')]
    sync_object(sync, self)
    -- 用/tinspect获取
    local icon, flash, hotkey, count, name, border, normal, pushed, highlight, checked = sync:GetRegions()
    local cooldown = sync:GetChildren()
    sync_object(icon, _G[self_name .. 'Icon'])
    sync_object(flash, _G[self_name .. 'Flash'])
    sync_object(hotkey, _G[self_name .. 'HotKey'])
    sync_object(count, _G[self_name .. 'Count'])
    sync_object(name, _G[self_name .. 'Name'])
    sync_object(border, _G[self_name .. 'Border'])
    -- sync_object(normal, _G[self_name .. 'NormalTexture'])
    -- sync_object(pushed, _G[self_name .. 'PushedTexture'])
    -- sync_object(highlight, _G[self_name .. 'HighlightTexture'])
    -- sync_object(checked, _G[self_name .. 'CheckedTexture'])
    sync_object(cooldown, _G[self_name .. 'Cooldown'])
    _G[self_name .. 'NormalTexture']:SetAlpha(0)
end

local function show_bonus_bar()
    BananaActionBar:Hide()
    BananaBonusActionBar:Show()
end

local function hide_bonus_bar()
    BananaActionBar:Show()
    BananaBonusActionBar:Hide()
end

local function toggle_bonus_bar(show)
    if show then
        show_bonus_bar()
    else
        hide_bonus_bar()
    end
end

function BananaBonusActionBar_OnLoad(self)
    BonusActionBarFrame:HookScript('OnShow', show_bonus_bar)
    BonusActionBarFrame:HookScript('OnHide', hide_bonus_bar)
    toggle_bonus_bar(BonusActionBarFrame:IsShown())
end
