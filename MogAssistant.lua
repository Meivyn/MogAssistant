local _G = _G

local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc
local DressUpVisual = DressUpVisual
local PlaySound = PlaySound

local LE_TRANSMOG_TYPE_APPEARANCE = LE_TRANSMOG_TYPE_APPEARANCE
local LE_TRANSMOG_TYPE_ILLUSION = LE_TRANSMOG_TYPE_ILLUSION
local SOUNDKIT_UI_TRANSMOG_ITEM_CLICK = SOUNDKIT.UI_TRANSMOG_ITEM_CLICK
local WARDROBE_DOWN_VISUAL_KEY = WARDROBE_DOWN_VISUAL_KEY
local WARDROBE_NEXT_VISUAL_KEY = WARDROBE_NEXT_VISUAL_KEY
local WARDROBE_PREV_VISUAL_KEY = WARDROBE_PREV_VISUAL_KEY
local WARDROBE_UP_VISUAL_KEY = WARDROBE_UP_VISUAL_KEY

local function HandleDressing(self)
  local GetWeaponInfoForEnchant = WardrobeCollectionFrame_GetWeaponInfoForEnchant
  local isCategoryLegionArtifact = WardrobeUtils_IsCategoryLegionArtifact(self:GetActiveCategory())
  local isCategoryRanged = WardrobeUtils_IsCategoryRanged(self:GetActiveCategory())

  local transmogType = self.transmogType
  local slot = self:GetActiveSlot()
  if transmogType == LE_TRANSMOG_TYPE_APPEARANCE then
    local sourceID = self:GetAnAppearanceSourceFromVisual(self.filteredVisualsList[self.visualIndex].visualID, nil)
    -- don't specify a slot for ranged weapons
    if isCategoryRanged or isCategoryLegionArtifact then
      slot = nil
    end
    DressUpVisual(sourceID, slot)
  elseif transmogType == LE_TRANSMOG_TYPE_ILLUSION then
    local weaponSourceID = GetWeaponInfoForEnchant(slot)
    DressUpVisual(weaponSourceID, slot, self.filteredVisualsList[self.visualIndex].sourceID)
  end
end

local function HandleBorder(self)
  local pendingTransmogModelFrame
  local index
  local indexOffset = (self.PagingFrame:GetCurrentPage() - 1) * self.PAGE_SIZE
  for i = 1, self.PAGE_SIZE do
    local model = self.Models[i]
    index = i + indexOffset
    local visualInfo = self.filteredVisualsList[index]
    if visualInfo then
      local transmogStateAtlas
      if visualInfo.visualID == self.filteredVisualsList[self.visualIndex].visualID then
        transmogStateAtlas = "transmog-wardrobe-border-selected"
        pendingTransmogModelFrame = model
      end
      if transmogStateAtlas then
        model.TransmogStateTexture:SetAtlas(transmogStateAtlas, true)
        model.TransmogStateTexture:Show()
      end
    end
  end
  self.pageIndex = index
  if pendingTransmogModelFrame then
    self.PendingTransmogFrame:SetParent(pendingTransmogModelFrame)
    self.PendingTransmogFrame:SetPoint("CENTER")
    self.PendingTransmogFrame:Show()
    self.PendingTransmogFrame.TransmogSelectedAnim:Stop()
    self.PendingTransmogFrame.TransmogSelectedAnim:Play()
    self.PendingTransmogFrame.TransmogSelectedAnim2:Stop()
    self.PendingTransmogFrame.TransmogSelectedAnim2:Play()
    self.PendingTransmogFrame.TransmogSelectedAnim3:Stop()
    self.PendingTransmogFrame.TransmogSelectedAnim3:Play()
    self.PendingTransmogFrame.TransmogSelectedAnim4:Stop()
    self.PendingTransmogFrame.TransmogSelectedAnim4:Play()
    self.PendingTransmogFrame.TransmogSelectedAnim5:Stop()
    self.PendingTransmogFrame.TransmogSelectedAnim5:Play()
  end
end

local function CanHandleKey(key)
  local isAtTransmogrifier = WardrobeFrame_IsAtTransmogrifier()

  return not isAtTransmogrifier and (key == WARDROBE_PREV_VISUAL_KEY or key == WARDROBE_NEXT_VISUAL_KEY or key == WARDROBE_UP_VISUAL_KEY or key == WARDROBE_DOWN_VISUAL_KEY)
end

local function HandleKey(self, key)
  local isAtTransmogrifier = WardrobeFrame_IsAtTransmogrifier()
  local GetAdjustedDisplayIndexFromKeyPress = WardrobeUtils_GetAdjustedDisplayIndexFromKeyPress

  if CanHandleKey(key) then
    self:SetPropagateKeyboardInput(false)
    local visualIndex = self.ItemsCollectionFrame.visualIndex
    local visualsList = self.ItemsCollectionFrame:GetFilteredVisualsList()
    visualIndex = GetAdjustedDisplayIndexFromKeyPress(self.ItemsCollectionFrame, visualIndex, #visualsList, key)
    self.ItemsCollectionFrame.visualIndex = visualIndex
    PlaySound(SOUNDKIT_UI_TRANSMOG_ITEM_CLICK)
    self.ItemsCollectionFrame.jumpToVisualID = visualsList[visualIndex].visualID
    self.ItemsCollectionFrame:ResetPage()
    HandleDressing(self.ItemsCollectionFrame)
    HandleBorder(self.ItemsCollectionFrame)
  elseif not isAtTransmogrifier then
    self:SetPropagateKeyboardInput(true)
  end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == "Blizzard_Collections" then
    _G.WardrobeCollectionFrame:HookScript("OnKeyDown", HandleKey)
    hooksecurefunc(_G.WardrobeCollectionFrame.ItemsCollectionFrame, "SetActiveCategory", function(self)
      self.visualIndex = 0
    end)
    hooksecurefunc(_G.WardrobeCollectionFrame.ItemsCollectionFrame, "OnPageChanged", function(self, userAction)
      if userAction then
        --TODO: This doesn't work as desired when the user changes pages more than once
        self.visualIndex = self.pageIndex
      end
    end)
  end
end)
