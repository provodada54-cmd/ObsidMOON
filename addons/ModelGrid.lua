local cloneref = (cloneref or clonereference or function(instance) return instance end)

local HttpService      = cloneref(game:GetService("HttpService"))
local RunService       = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))

local ModelGrid = {
    Library     = nil,
    SaveManager = nil,
    Elements    = {},

    Config = {
        CellSize        = UDim2.new(0, 140, 0, 170),
        CellPadding     = UDim2.new(0, 6, 0, 6),
        ViewportHeight  = 130,
        DefaultHeight   = 280,
        SearchHeight    = 26,
        LazyBuffer      = 150,
        PreviewDistance = 1.6,
    },

    PreviewCache = setmetatable({}, { __mode = "k" }),

    Templates = {
        Text          = nil,
        Values        = {},
        Height        = nil,
        CellSize      = nil,
        ModelProvider = nil,
        FormatDisplay = nil,
        Searchable    = true,
        AllowNull     = false,
        NullText      = "None",
        Default       = nil,
        Placeholder   = "> Search...",
        Callback      = function() end,
        Changed       = function() end,
        Disabled      = false,
        Visible       = true,
    },
}

function ModelGrid:SetLibrary(Library)
    ModelGrid.Library = Library
    if Library.Window then
        ModelGrid:HookWindow(Library.Window)
    end
    return ModelGrid
end

function ModelGrid:SetSaveManager(SaveManager)
    ModelGrid.SaveManager = SaveManager
    ModelGrid:RegisterSaveParser()
    return ModelGrid
end

function ModelGrid:RegisterSaveParser()
    local SM = ModelGrid.SaveManager
    if not SM or not SM.ElementParser then return end

    SM.ElementParser["ModelGrid"] = {
        Save = function(Index, Element)
            return { type = "ModelGrid", idx = Index, value = Element.Value }
        end,
        Load = function(Index, Data)
            local Element = ModelGrid.Library and ModelGrid.Library.Options[Index]
            if not Element then return end
            if Element.Value == Data.value then
                if Element.RunChanged then Element:RunChanged() end
                return
            end
            Element:SetValue(Data.value)
        end,
    }
end

function ModelGrid:HookWindow(Window)
    if not Window or Window.__ModelGridHooked then return end
    Window.__ModelGridHooked = true

    local OriginalAddTab = Window.AddTab
    Window.AddTab = function(self, ...)
        local Tab = OriginalAddTab(self, ...)
        ModelGrid:HookTab(Tab)
        return Tab
    end

    local Library = ModelGrid.Library
    if Library and Library.Tabs then
        for _, Tab in pairs(Library.Tabs) do
            ModelGrid:HookTab(Tab)
        end
    end
end

function ModelGrid:HookTab(Tab)
    if not Tab or Tab.__ModelGridHooked then return end
    Tab.__ModelGridHooked = true

    local OriginalAddGroupbox = Tab.AddGroupbox
    if typeof(OriginalAddGroupbox) ~= "function" then return end

    Tab.AddGroupbox = function(self, ...)
        local Groupbox = OriginalAddGroupbox(self, ...)
        ModelGrid:HookGroupbox(Groupbox)
        return Groupbox
    end
end

function ModelGrid:HookGroupbox(Groupbox)
    if not Groupbox or Groupbox.__ModelGridHooked then return end
    Groupbox.__ModelGridHooked = true

    local mt = getmetatable(Groupbox)
    if mt and mt.__index and not mt.__index.AddModelGrid then
        mt.__index.AddModelGrid = function(self, Idx, Info)
            return ModelGrid:Create(self, Idx, Info)
        end
    end
end

local function prepareModel(model)
    if not model then return nil, Vector3.new(2, 2, 2) end

    local cached = ModelGrid.PreviewCache[model]
    if cached then return cached.Model, cached.Size end

    local ok, prepared, size = pcall(function()
        local clone = model:Clone()
        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA("BasePart") then
                d.Anchored = true
                d.CanCollide = false
            end
            if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam")
               or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") then
                d.Enabled = false
            end
        end

        local primary
        for _, ch in ipairs(clone:GetChildren()) do
            if ch:IsA("BasePart") then primary = ch; break end
        end
        if not primary then
            primary = clone:FindFirstChildWhichIsA("BasePart", true)
        end
        if primary then clone.PrimaryPart = primary end

        if clone.PrimaryPart then
            local cf = CFrame.new(0, 0, 0)
                * CFrame.Angles(0, math.rad(180), 0)
                * CFrame.Angles(math.rad(-25), 0, math.rad(45))
            clone:PivotTo(cf)
        end

        local _, s = clone:GetBoundingBox()
        return clone, s
    end)

    if not ok or not prepared then return nil, Vector3.new(2, 2, 2) end
    ModelGrid.PreviewCache[model] = { Model = prepared, Size = size }
    return prepared, size
end

local function fillViewport(viewport, sourceModel)
    for _, c in ipairs(viewport:GetChildren()) do
        if c:IsA("Model") or c:IsA("BasePart") or c:IsA("Camera") then
            c:Destroy()
        end
    end
    if not sourceModel then return end

    local prepared, size = prepareModel(sourceModel)
    if not prepared then return end

    local clone = prepared:Clone()
    clone.Parent = viewport

    local cam = Instance.new("Camera")
    cam.Parent = viewport
    viewport.CurrentCamera = cam

    local dist = math.max(size.X, size.Y, size.Z) * ModelGrid.Config.PreviewDistance
    cam.CFrame = CFrame.new(Vector3.new(0, 0, dist), Vector3.new(0, 0, 0))
end

function ModelGrid:Create(Groupbox, Idx, Info)
    local Library = ModelGrid.Library
    assert(Library, "ModelGrid: Library not set")

    Info = Library:Validate(Info, ModelGrid.Templates)

    local Container  = Groupbox.Container
    local CellSize   = Info.CellSize or ModelGrid.Config.CellSize
    local GridHeight = Info.Height  or ModelGrid.Config.DefaultHeight
    local Searchable = Info.Searchable ~= false
    local LabelH     = Info.Text and 18 or 0
    local SearchH    = Searchable and ModelGrid.Config.SearchHeight or 0
    local Gap        = 4
    local TotalH     = LabelH
                     + (LabelH > 0 and Gap or 0)
                     + (Searchable and (SearchH + Gap) or 0)
                     + GridHeight

    local Holder = Instance.new("Frame")
    Holder.BackgroundTransparency = 1
    Holder.Size = UDim2.new(1, 0, 0, TotalH)
    Holder.Visible = Info.Visible
    Holder.Parent = Container

    local Element = {
        Type = "ModelGrid",
        Connections = {},
        Destroyed = false,

        Visible = Info.Visible,
        Disabled = Info.Disabled,

        Text          = Info.Text,
        Value         = nil,
        Values        = Info.Values,
        AllowNull     = Info.AllowNull,
        NullText      = Info.NullText,

        ModelProvider = Info.ModelProvider,
        FormatDisplay = Info.FormatDisplay,

        Callback = Info.Callback,
        Changed  = Info.Changed,

        Parent = Groupbox,
        Holder = Holder,
        Cells  = {},

        _loadedOrder = 0,
    }

    local curY = 0

    if Info.Text then
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(1, 0, 0, LabelH)
        lbl.Position = UDim2.new(0, 0, 0, curY)
        lbl.Text = Info.Text
        lbl.TextSize = 14
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Font = Library.Scheme.Font
        lbl.TextColor3 = Library.Scheme.FontColor
        lbl.Parent = Holder
        Library:AddToRegistry(lbl, { TextColor3 = "FontColor", FontFace = "Font" })
        curY = curY + LabelH + Gap
    end

    if Searchable then
        local sb = Instance.new("TextBox")
        sb.BackgroundColor3 = Library.Scheme.MainColor
        sb.BorderSizePixel = 0
        sb.Size = UDim2.new(1, 0, 0, SearchH)
        sb.Position = UDim2.new(0, 0, 0, curY)
        sb.Text = ""
        sb.PlaceholderText = Info.Placeholder
        sb.TextColor3 = Library.Scheme.FontColor
        sb.PlaceholderColor3 = Library.Scheme.FontColor:Lerp(Library.Scheme.BackgroundColor, 0.5)
        sb.Font = Library.Scheme.Font
        sb.TextSize = 12
        sb.ClearTextOnFocus = false
        sb.TextXAlignment = Enum.TextXAlignment.Left
        sb.Parent = Holder
        Library:AddToRegistry(sb, {
            BackgroundColor3 = "MainColor",
            TextColor3 = "FontColor",
            FontFace = "Font",
        })

        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 8)
        pad.Parent = sb

        local stroke = Instance.new("UIStroke")
        stroke.Color = Library.Scheme.OutlineColor
        stroke.Parent = sb
        Library:AddToRegistry(stroke, { Color = "OutlineColor" })

        Element.SearchBox = sb
        curY = curY + SearchH + Gap
    end

    local Scroll = Instance.new("ScrollingFrame")
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel = 0
    Scroll.Position = UDim2.new(0, 0, 0, curY)
    Scroll.Size = UDim2.new(1, 0, 0, GridHeight)
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Scroll.ScrollBarThickness = 4
    Scroll.ScrollBarImageColor3 = Library.Scheme.AccentColor
    Scroll.ScrollBarImageTransparency = 0.3
    Scroll.Parent = Holder
    Library:AddToRegistry(Scroll, { ScrollBarImageColor3 = "AccentColor" })
    Element.Scroll = Scroll

    local Grid = Instance.new("UIGridLayout")
    Grid.CellSize = CellSize
    Grid.CellPadding = ModelGrid.Config.CellPadding
    Grid.SortOrder = Enum.SortOrder.LayoutOrder
    Grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
    Grid.Parent = Scroll
    Element.Grid = Grid

    local function makeCell(itemName, display)
        local Cell = {
            ItemName = itemName,
            Loaded   = false,
            Selected = false,
        }

        local Frame = Instance.new("Frame")
        Frame.BackgroundColor3 = Library.Scheme.MainColor
        Frame.BorderSizePixel = 0
        Frame.Parent = Scroll
        Frame.LayoutOrder = Element._loadedOrder
        Element._loadedOrder = Element._loadedOrder + 1
        Library:AddToRegistry(Frame, { BackgroundColor3 = "MainColor" })

        local stroke = Instance.new("UIStroke")
        stroke.Color = Library.Scheme.OutlineColor
        stroke.Transparency = 0.6
        stroke.Thickness = 1
        stroke.Parent = Frame
        Library:AddToRegistry(stroke, { Color = "OutlineColor" })

        local cellCorner = Instance.new("UICorner")
        cellCorner.CornerRadius = UDim.new(0, 4)
        cellCorner.Parent = Frame

        local vp = Instance.new("ViewportFrame")
        vp.Name = "VP"
        vp.BackgroundColor3 = Library.Scheme.BackgroundColor
        vp.BackgroundTransparency = 0.3
        vp.BorderSizePixel = 0
        vp.Size = UDim2.new(1, -8, 0, ModelGrid.Config.ViewportHeight)
        vp.Position = UDim2.new(0, 4, 0, 4)
        vp.Ambient = Color3.fromRGB(180, 180, 180)
        vp.LightColor = Color3.fromRGB(255, 255, 255)
        vp.LightDirection = Vector3.new(-1, -1, -1)
        vp.Parent = Frame
        Library:AddToRegistry(vp, { BackgroundColor3 = "BackgroundColor" })

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Name = "NameLbl"
        nameLbl.BackgroundTransparency = 1
        nameLbl.Size = UDim2.new(1, -8, 0, 30)
        nameLbl.Position = UDim2.new(0, 4, 1, -34)
        nameLbl.Text = display
        nameLbl.Font = Library.Scheme.Font
        nameLbl.TextSize = 10
        nameLbl.TextWrapped = true
        nameLbl.TextColor3 = Library.Scheme.FontColor
        nameLbl.Parent = Frame
        Library:AddToRegistry(nameLbl, { TextColor3 = "FontColor", FontFace = "Font" })

        local btn = Instance.new("TextButton")
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.ZIndex = 5
        btn.Parent = Frame

        Cell.Frame    = Frame
        Cell.Viewport = vp
        Cell.NameLbl  = nameLbl
        Cell.Button   = btn
        Cell.Stroke   = stroke

        btn.MouseButton1Click:Connect(function()
            if Element.Disabled then return end
            Element:SetValue(itemName)
        end)

        return Cell
    end

    local function loadCellViewport(cell)
        if cell.Loaded or cell.Destroyed then return end
        if cell.ItemName == nil then return end
        if not Element.ModelProvider then return end

        cell.Loaded = true
        local ok, model = pcall(Element.ModelProvider, cell.ItemName)
        if ok and model then
            fillViewport(cell.Viewport, model)
        end
    end

    function Element:UpdateVisibleViewports()
        if self.Destroyed then return end
        local scrollAbs = Scroll.AbsolutePosition
        local scrollSize = Scroll.AbsoluteSize
        local buffer = ModelGrid.Config.LazyBuffer

        for _, cell in ipairs(self.Cells) do
            if cell.Loaded then continue end
            if not cell.Frame.Parent then continue end
            local p = cell.Frame.AbsolutePosition
            local s = cell.Frame.AbsoluteSize
            local relY = p.Y - scrollAbs.Y
            local bottom = relY + s.Y
            local visible = bottom >= -buffer and relY <= scrollSize.Y + buffer
            if visible then
                loadCellViewport(cell)
            end
        end
    end

    function Element:RefreshHighlights()
        for _, cell in ipairs(self.Cells) do
            local isSel = (cell.ItemName == self.Value)
            cell.Selected = isSel
            if isSel then
                cell.Frame.BackgroundColor3 = Library.Scheme.MainColor:Lerp(Library.Scheme.AccentColor, 0.15)
                cell.Stroke.Color = Library.Scheme.AccentColor
                cell.Stroke.Transparency = 0.1
                cell.Stroke.Thickness = 2
                cell.NameLbl.TextColor3 = Library.Scheme.AccentColor
            else
                cell.Frame.BackgroundColor3 = Library.Scheme.MainColor
                cell.Stroke.Color = Library.Scheme.OutlineColor
                cell.Stroke.Transparency = 0.6
                cell.Stroke.Thickness = 1
                cell.NameLbl.TextColor3 = Library.Scheme.FontColor
            end

            Library.Registry[cell.Frame].BackgroundColor3 = function()
                return cell.Selected
                    and Library.Scheme.MainColor:Lerp(Library.Scheme.AccentColor, 0.15)
                    or Library.Scheme.MainColor
            end
            Library.Registry[cell.Stroke].Color = function()
                return cell.Selected and Library.Scheme.AccentColor or Library.Scheme.OutlineColor
            end
            Library.Registry[cell.NameLbl].TextColor3 = function()
                return cell.Selected and Library.Scheme.AccentColor or Library.Scheme.FontColor
            end
        end
    end

    local function passesFilter(itemName, query)
        if query == "" then return true end
        local low = query:lower()
        local name = (itemName == nil) and "none" or tostring(itemName)
        local display = (itemName == nil)
            and (Element.NullText or "none")
            or (Element.FormatDisplay and tostring(Element.FormatDisplay(itemName)) or name)
        return name:lower():find(low, 1, true) ~= nil
            or display:lower():find(low, 1, true) ~= nil
    end

    function Element:Rebuild(query)
        query = query or ""
        for _, cell in ipairs(self.Cells) do
            if cell.Frame then cell.Frame:Destroy() end
        end
        table.clear(self.Cells)
        Element._loadedOrder = 0

        if self.AllowNull and passesFilter(nil, query) then
            local c = makeCell(nil, self.NullText or "None")
            table.insert(self.Cells, c)
        end

        for _, itemName in ipairs(self.Values or {}) do
            if passesFilter(itemName, query) then
                local display = self.FormatDisplay
                    and tostring(self.FormatDisplay(itemName))
                    or tostring(itemName)
                local c = makeCell(itemName, display)
                table.insert(self.Cells, c)
            end
        end

        self:RefreshHighlights()
        task.defer(function()
            if not self.Destroyed then
                self:UpdateVisibleViewports()
            end
        end)
    end

    function Element:SetValue(value)
        if self.Disabled then return end
        if value == "__none__" then value = nil end
        if value ~= nil then
            local found = false
            for _, v in ipairs(self.Values or {}) do
                if v == value then found = true; break end
            end
            if not found then return end
        else
            if not self.AllowNull then return end
        end

        if self.Value == value then
            self:RunChanged()
            return
        end

        self.Value = value
        self:RefreshHighlights()
        self:RunChanged()
    end

    function Element:GetValue()
        return self.Value
    end

    function Element:SetValues(values)
        self.Values = values or {}
        self:Rebuild(self.SearchBox and self.SearchBox.Text or "")
    end

    function Element:SetDisabled(disabled)
        self.Disabled = disabled
        if self.SearchBox then
            self.SearchBox.TextEditable = not disabled
            self.SearchBox.Active = not disabled
        end
    end

    function Element:SetVisible(visible)
        self.Visible = visible
        Holder.Visible = visible
        if Groupbox and Groupbox.Resize then Groupbox:Resize() end
    end

    function Element:SetText(text)
        self.Text = text
    end

    function Element:OnChanged(fn) self.Changed = fn end

    function Element:RunChanged()
        if self.Disabled then return end
        Library:SafeCallback(self.Callback, self.Value)
        Library:SafeCallback(self.Changed, self.Value)
    end

    function Element:Destroy()
        self.Destroyed = true
        for _, conn in ipairs(self.Connections) do
            if conn and conn.Disconnect then conn:Disconnect() end
        end
        for _, cell in ipairs(self.Cells) do
            if cell.Frame then cell.Frame:Destroy() end
        end
        if Holder then Holder:Destroy() end

        local elemIdx = table.find(Groupbox.Elements, self)
        if elemIdx then table.remove(Groupbox.Elements, elemIdx) end
        if Groupbox.Resize then Groupbox:Resize() end

        Library.Options[Idx] = nil
        ModelGrid.Elements[Idx] = nil
    end

    table.insert(Element.Connections, Scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        Element:UpdateVisibleViewports()
    end))
    table.insert(Element.Connections, Scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        Element:UpdateVisibleViewports()
    end))

    if Element.SearchBox then
        table.insert(Element.Connections, Element.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
            Element:Rebuild(Element.SearchBox.Text)
        end))
    end

    Library.Options[Idx] = Element
    table.insert(Groupbox.Elements, Element)
    Groupbox:Resize()

    ModelGrid.Elements[Idx] = Element

    Element:Rebuild("")

    if Info.Default ~= nil then
        Element:SetValue(Info.Default)
    elseif Info.AllowNull then
        Element.Value = nil
        Element:RefreshHighlights()
    end

    return Element
end

getgenv().ObsidianModelGrid = ModelGrid
return ModelGrid