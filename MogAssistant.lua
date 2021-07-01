local _G = _G
local select = select

local C_Transmog_IsAtTransmogNPC = C_Transmog.IsAtTransmogNPC
local C_TransmogCollection_GetAppearanceSourceInfo = C_TransmogCollection.GetAppearanceSourceInfo
local C_TransmogCollection_GetIllusionInfo = C_TransmogCollection.GetIllusionInfo
local CreateFrame = CreateFrame
local DressUpCollectionAppearance = DressUpCollectionAppearance
local DressUpVisual = DressUpVisual
local IsModifiedClick = IsModifiedClick
local PlaySound = PlaySound

local SOUNDKIT_UI_TRANSMOG_ITEM_CLICK = SOUNDKIT.UI_TRANSMOG_ITEM_CLICK
local WARDROBE_DOWN_VISUAL_KEY = WARDROBE_DOWN_VISUAL_KEY
local WARDROBE_NEXT_VISUAL_KEY = WARDROBE_NEXT_VISUAL_KEY
local WARDROBE_PREV_VISUAL_KEY = WARDROBE_PREV_VISUAL_KEY
local WARDROBE_UP_VISUAL_KEY = WARDROBE_UP_VISUAL_KEY

local function UpdateItems(self)
  local pendingTransmogModelFrame
  local indexOffset = (self.PagingFrame:GetCurrentPage() - 1) * self.PAGE_SIZE
  for i = 1, self.PAGE_SIZE do
    local model = self.Models[i]
    local index = i + indexOffset
    local visualInfo = self.filteredVisualsList[index]
    if visualInfo then
      local transmogStateAtlas
      if visualInfo.visualID == self.selectedVisualID then
        transmogStateAtlas = "transmog-wardrobe-border-selected"
        pendingTransmogModelFrame = model
      end
      if transmogStateAtlas then
        model.TransmogStateTexture:SetAtlas(transmogStateAtlas, true)
        model.TransmogStateTexture:Show()
      else
        model.TransmogStateTexture:Hide()
      end
    end
  end
  if pendingTransmogModelFrame then
    self.PendingTransmogFrame:SetParent(pendingTransmogModelFrame)
    self.PendingTransmogFrame:SetPoint("CENTER")
    self.PendingTransmogFrame:Show()
    if self.PendingTransmogFrame.visualID ~= self.selectedVisualID then
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
    self.PendingTransmogFrame.visualID = self.selectedVisualID
  end
end

local function DressUp(self, visualInfo)
  if self.transmogLocation:IsAppearance() then
    local sourceID = self:GetAnAppearanceSourceFromVisual(visualInfo.visualID, nil)
    DressUpCollectionAppearance(sourceID, self.transmogLocation, self:GetActiveCategory())
    self.selectedVisualID = select(2, C_TransmogCollection_GetAppearanceSourceInfo(sourceID))
  elseif self.transmogLocation:IsIllusion() then
    local slot = self:GetActiveSlot()
    local illusionInfo = C_TransmogCollection_GetIllusionInfo(visualInfo.sourceID)
    DressUpVisual(self.illusionWeaponAppearanceID, slot, visualInfo.sourceID)
    self.selectedVisualID = illusionInfo and illusionInfo.visualID
  end
end

local function GetAdjustedDisplayIndexFromKeyPress(contentFrame, index, numEntries, key)
  if key == WARDROBE_PREV_VISUAL_KEY then
    index = index - 1
    if index < 1 then
      index = numEntries
    end
  elseif key == WARDROBE_NEXT_VISUAL_KEY then
    index = index + 1
    if index > numEntries then
      index = 1
    end
  elseif key == WARDROBE_DOWN_VISUAL_KEY then
    local newIndex = index + contentFrame.NUM_COLS
    if newIndex > numEntries then
      -- If you're at the last entry, wrap back around; otherwise go to the last entry.
      index = index == numEntries and 1 or numEntries
    else
      index = newIndex
    end
  elseif key == WARDROBE_UP_VISUAL_KEY then
    local newIndex = index - contentFrame.NUM_COLS
    if newIndex < 1 then
      -- If you're at the first entry, wrap back around; otherwise go to the first entry.
      index = index == 1 and numEntries or 1
    else
      index = newIndex
    end
  end
  return index
end

local function OnKeyDown(self, key)
  if C_Transmog_IsAtTransmogNPC() or self.selectedCollectionTab ~= 1 then return end
  if not (key == WARDROBE_PREV_VISUAL_KEY or key == WARDROBE_NEXT_VISUAL_KEY or key == WARDROBE_UP_VISUAL_KEY or key == WARDROBE_DOWN_VISUAL_KEY) then return end
  self:SetPropagateKeyboardInput(false)
  local visualIndex = 0
  local visualsList = self.ItemsCollectionFrame:GetFilteredVisualsList()
  for i = 1, #visualsList do
    if visualsList[i].visualID == self.ItemsCollectionFrame.selectedVisualID then
      visualIndex = i
      break
    end
  end
  visualIndex = GetAdjustedDisplayIndexFromKeyPress(self.ItemsCollectionFrame, visualIndex, #visualsList, key)
  self.ItemsCollectionFrame.jumpToVisualID = visualsList[visualIndex].visualID
  self.ItemsCollectionFrame:ResetPage()
  PlaySound(SOUNDKIT_UI_TRANSMOG_ITEM_CLICK)
  DressUp(self.ItemsCollectionFrame, visualsList[visualIndex])
  UpdateItems(self.ItemsCollectionFrame)
end

local function OnMouseDown(self, button)
  if C_Transmog_IsAtTransmogNPC() then return end
  if button == "LeftButton" and not IsModifiedClick("CHATLINK") then
    PlaySound(SOUNDKIT_UI_TRANSMOG_ITEM_CLICK)
    DressUp(self:GetParent(), self.visualInfo)
    UpdateItems(self:GetParent())
  end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == "Blizzard_Collections" then
    _G.WardrobeCollectionFrame:HookScript("OnKeyDown", OnKeyDown)
    for i = 1, #_G.WardrobeCollectionFrame.ItemsCollectionFrame.Models do
      local model = _G.WardrobeCollectionFrame.ItemsCollectionFrame.Models[i]
      model:HookScript("OnMouseDown", OnMouseDown)
    end
  end
end)
