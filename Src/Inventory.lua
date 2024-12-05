-- 商人界面鼠标滚轮翻页
MerchantFrame:SetScript(
    'OnMouseWheel',
    function(frame, delta)
        if delta == 1 then
            if MerchantPrevPageButton:IsShown() then
                MerchantPrevPageButton:Click()
            end
        elseif delta == -1 then
            if MerchantNextPageButton:IsShown() then
                MerchantNextPageButton:Click()
            end
        end
    end
)
MerchantFrame:EnableMouseWheel(true)

-- 自动修理、自动售卖垃圾
MerchantFrame:HookScript(
    'OnShow',
    function(frame)
        if CanMerchantRepair() then
            if IsInGuild() and CanGuildBankRepair() then
                RepairAllItems(true)
            end
            RepairAllItems(false)
        end
        for bag_id = 0, 4 do
            local num_slots = GetContainerNumSlots(bag_id)
            if num_slots and num_slots > 0 then
                for slot_index = 1, num_slots do
                    local item_link = GetContainerItemLink(bag_id, slot_index)
                    if item_link then
                        -- 物品信息，WLK只有GetItemInfo函数可用，返回值一直到sellPrice为止
                        if select(3, GetItemInfo(item_link)) == 0 then
                            UseContainerItem(bag_id, slot_index)
                        end
                    end
                end
            end
        end
    end
)

-- 增强物品显示
local overlayed_item_buttons = {}
local function item_button_prepare(button, more)
    if not overlayed_item_buttons[button] then
        local overlay = CreateFrame('FRAME', nil, button)
        overlay:SetAllPoints()
        overlay:Show()
        local ilvlbg = overlay:CreateTexture(nil, 'BACKGROUND')
        ilvlbg:SetTexture(0, 0, 0)
        ilvlbg:SetPoint('TOPRIGHT', -2, -2)
        ilvlbg:Hide()
        local ilvl = overlay:CreateFontString(nil, 'OVERLAY', 'NumberFont_Outline_Large')
        ilvl:SetPoint('TOPRIGHT', -2, -2)
        ilvl:SetJustifyH('RIGHT')
        ilvl:Hide()
        overlayed_item_buttons[button] = {
            overlay = overlay,
            ilvlbg = ilvlbg,
            ilvl = ilvl
        }
        if more then
            more(overlayed_item_buttons[button])
        end
    end
    return overlayed_item_buttons[button]
end
local function item_button_hide_all(button)
    if overlayed_item_buttons[button] then
        overlayed_item_buttons[button].ilvlbg:Hide()
        overlayed_item_buttons[button].ilvl:Hide()
    end
end
local function item_button_show_ilvl(button, item_link)
    local item_name, item_link, item_quality, item_level, item_min_level, item_type, item_sub_type, item_stack_count, item_equip_loc, item_texture, sell_price = GetItemInfo(item_link)
    if item_equip_loc == '' or item_equip_loc == 'INVTYPE_BAG' or not item_level or not item_quality then
        return
    end
    local r, g, b
    if item_quality == 2 then -- 绿色，变暗
        r, g, b = 0, 0.9, 0
    elseif item_quality == 3 then -- 蓝色，加亮
        r, g, b = 0.1, 0.5, 1
    elseif item_quality == 4 then -- 紫色，加亮
        r, g, b = 0.9, 0.3, 1
    else
        r, g, b = GetItemQualityColor(item_quality) -- 传家宝的ITEM_QUALITY_COLORS为空，这个函数正常
    end
    local entry = item_button_prepare(button)
    entry.ilvl:SetText(item_level)
    if r then
        entry.ilvl:SetTextColor(r, g, b)
    end
    entry.ilvl:Show()
    entry.ilvlbg:SetSize(entry.ilvl:GetSize())
    entry.ilvlbg:Show()
end
-- 角色面板
do
    local function update(button)
        item_button_hide_all(button)
        local slot_id = button:GetID()
        local item_link = GetInventoryItemLink('player', slot_id)
        if item_link then
            item_button_show_ilvl(button, item_link)
        end
    end
    hooksecurefunc('PaperDollItemSlotButton_Update', update)
    -- FrameXML\PaperDollFrame.xml
    if PaperDollFrame:IsShown() then
        update(CharacterHeadSlot)
        update(CharacterNeckSlot)
        update(CharacterShoulderSlot)
        update(CharacterBackSlot)
        update(CharacterChestSlot)
        update(CharacterShirtSlot)
        update(CharacterTabardSlot)
        update(CharacterWristSlot)
        update(CharacterHandsSlot)
        update(CharacterWaistSlot)
        update(CharacterLegsSlot)
        update(CharacterFeetSlot)
        update(CharacterFinger0Slot)
        update(CharacterFinger1Slot)
        update(CharacterTrinket0Slot)
        update(CharacterTrinket1Slot)
        update(CharacterMainHandSlot)
        update(CharacterSecondaryHandSlot)
        update(CharacterRangedSlot)
        update(CharacterAmmoSlot)
    end
end
-- 目标角色面板
-- 一些支持“幻化”的服务器，打开某目标显示的是真实装备，而从某目标切换到新目标显示的是幻化装备，测试代码如下：
-- /run NotifyInspect('target');print(GetInventoryItemLink('target', 1))
-- 1换成幻化的slot_id，如果不NotifyInspect那么得不到结果，参考Blizzard_InspectUI.lua
do
    LoadAddOn('Blizzard_InspectUI')
    local function update(button)
        item_button_hide_all(button)
        local slot_id = button:GetID()
        if InspectFrame.unit then
            local item_link = GetInventoryItemLink(InspectFrame.unit, slot_id)
            if item_link then
                -- print(slot_id, item_link)
                item_button_show_ilvl(button, item_link)
            end
        end
    end
    hooksecurefunc('InspectPaperDollItemSlotButton_Update', update)
    -- AddOns\Blizzard_InspectUI\InspectPaperDollFrame.xml
    if InspectPaperDollFrame:IsShown() then
        update(InspectHeadSlot)
        update(InspectNeckSlot)
        update(InspectShoulderSlot)
        update(InspectBackSlot)
        update(InspectChestSlot)
        update(InspectShirtSlot)
        update(InspectTabardSlot)
        update(InspectWristSlot)
        update(InspectHandsSlot)
        update(InspectWaistSlot)
        update(InspectLegsSlot)
        update(InspectFeetSlot)
        update(InspectFinger0Slot)
        update(InspectFinger1Slot)
        update(InspectTrinket0Slot)
        update(InspectTrinket1Slot)
        update(InspectMainHandSlot)
        update(InspectSecondaryHandSlot)
        update(InspectRangedSlot)
    -- 没有AmmoSlot
    end
end
-- 背包
do
    local function update(bag)
        local bag_id = bag:GetID()
        local bag_name = bag:GetName()
        for i = 1, bag.size do
            local button = _G[bag_name .. 'Item' .. i]
            item_button_hide_all(button)
            local slot_id = button:GetID()
            local item_link = GetContainerItemLink(bag_id, slot_id)
            if item_link then
                item_button_show_ilvl(button, item_link)
            end
        end
    end
    hooksecurefunc('ContainerFrame_Update', update)
    -- FrameXML\ContainerFrame.xml
    for i = 1, 13 do
        local bag = _G['ContainerFrame' .. i]
        if bag:IsShown() then
            update(bag)
        end
    end
end
-- 银行界面，非银行背包
do
    local function update(button)
        item_button_hide_all(button)
        if button.isBag then
            return
        end
        local item_link = GetContainerItemLink(BANK_CONTAINER, button:GetID())
        if item_link then
            item_button_show_ilvl(button, item_link)
        end
    end
    hooksecurefunc('BankFrameItemButton_Update', update)
    -- FrameXML\BankFrame.xml
    if BankFrame:IsShown() then
        for i = 1, 28 do
            local button = _G['BankFrameItem' .. i]
            update(button)
        end
    end
end
-- 商人
do
    local function update()
        for i = 1, 12 do
            local item = _G['MerchantItem' .. i]
            local button = _G['MerchantItem' .. i .. 'ItemButton']
            item_button_hide_all(button)
            if item:IsShown() and button:IsShown() then
                if MerchantFrame.selectedTab == 2 then
                    -- 补上回购物品ID
                    button.link = GetBuybackItemLink(i)
                end
                if button.link then
                    item_button_show_ilvl(button, button.link)
                end
            end
        end
        item_button_hide_all(MerchantBuyBackItemItemButton)
        local link = GetBuybackItemLink(GetNumBuybackItems())
        if link then
            item_button_show_ilvl(MerchantBuyBackItemItemButton, link)
        end
    end
    hooksecurefunc('MerchantFrame_Update', update)
    if MerchantFrame:IsShown() then
        update()
    end
end
-- 公会银行
do
    LoadAddOn('Blizzard_GuildBankUI')
    local function update()
        local tab = GetCurrentGuildBankTab()
        for column = 1, 7 do
            for index = 1, 14 do
                local slot = (column - 1) * 14 + index
                local item_link = GetGuildBankItemLink(tab, slot)
                local button = _G['GuildBankColumn' .. column .. 'Button' .. index]
                item_button_hide_all(button)
                if item_link then
                    item_button_show_ilvl(button, item_link)
                end
            end
        end
    end
    hooksecurefunc('GuildBankFrame_Update', update)
    if GuildBankFrame:IsShown() then
        update()
    end
end

-- PATCH: 处于购回标签页时候修理按钮会时不时显示的问题
function MerchantFrame_UpdateRepairButtons()
    if CanMerchantRepair() and MerchantFrame.selectedTab == 1 then -- PATCH HERE
        if CanGuildBankRepair() then
            MerchantRepairAllButton:SetWidth(32)
            MerchantRepairAllButton:SetHeight(32)
            MerchantRepairItemButton:SetWidth(32)
            MerchantRepairItemButton:SetHeight(32)
            MerchantRepairItemButton:SetPoint('RIGHT', MerchantRepairAllButton, 'LEFT', -4, 0)
            MerchantRepairAllButton:SetPoint('BOTTOMRIGHT', MerchantFrame, 'BOTTOMLEFT', 115, 89)
            MerchantRepairText:ClearAllPoints()
            MerchantRepairText:SetPoint('CENTER', MerchantFrame, 'BOTTOMLEFT', 97, 129)
            MerchantGuildBankRepairButton:Show()
        else
            MerchantRepairAllButton:SetWidth(36)
            MerchantRepairAllButton:SetHeight(36)
            MerchantRepairItemButton:SetWidth(36)
            MerchantRepairItemButton:SetHeight(36)
            MerchantRepairItemButton:SetPoint('RIGHT', MerchantRepairAllButton, 'LEFT', -2, 0)
            MerchantRepairAllButton:SetPoint('BOTTOMRIGHT', MerchantFrame, 'BOTTOMLEFT', 172, 91)
            MerchantRepairText:ClearAllPoints()
            MerchantRepairText:SetPoint('BOTTOMLEFT', MerchantFrame, 'BOTTOMLEFT', 26, 103)
            MerchantGuildBankRepairButton:Hide()
        end
        MerchantRepairText:Show()
        MerchantRepairAllButton:Show()
        MerchantRepairItemButton:Show()
    else
        MerchantRepairText:Hide()
        MerchantRepairAllButton:Hide()
        MerchantRepairItemButton:Hide()
        MerchantGuildBankRepairButton:Hide()
    end
end
