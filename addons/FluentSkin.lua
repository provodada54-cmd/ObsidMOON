local TweenService = game:GetService("TweenService")

local FluentSkin = {
    Library = nil,
    C = {
        Bg          = Color3.fromRGB(20, 20, 20),
        Card        = Color3.fromRGB(120, 120, 120),
        CardT       = 0.87,
        CardHover   = 0.82,
        Border      = Color3.fromRGB(90, 90, 90),
        BorderT     = 0.6,
        Text        = Color3.fromRGB(240, 240, 240),
        Accent      = Color3.fromRGB(96, 205, 255),
        Font        = Font.new("rbxasset://fonts/families/GothamSSm.json"),
        Corner      = 8,
        ElementH    = 42,
        PadX        = 12,
    },
}

local function ensure(obj, class)
    local existing = obj:FindFirstChildOfClass(class)
    if not existing then
        existing = Instance.new(class)
        existing.Parent = obj
    end
    return existing
end

local function tween(inst, time, props)
    if not inst or not inst.Parent then return end
    TweenService:Create(inst, TweenInfo.new(time or 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
end

function FluentSkin:SetLibrary(Library)
    self.Library = Library
    local C = self.C
    Library.Scheme.BackgroundColor = C.Bg
    Library.Scheme.MainColor       = C.Card
    Library.Scheme.AccentColor     = C.Accent
    Library.Scheme.OutlineColor    = C.Border
    Library.Scheme.FontColor       = C.Text
    Library.Scheme.Font            = C.Font
    Library.CornerRadius           = C.Corner
    Library:UpdateColorsUsingRegistry()

    self:HookWindow(Library.Window)
    return self
end

function FluentSkin:HookWindow(Window)
    if not Window or Window.__FluentHooked then return end
    Window.__FluentHooked = true

    local origAddTab = Window.AddTab
    Window.AddTab = function(self2, ...)
        local Tab = origAddTab(self2, ...)
        FluentSkin:HookTab(Tab)
        return Tab
    end

    local L = FluentSkin.Library
    if L and L.Tabs then
        for _, Tab in pairs(L.Tabs) do
            if typeof(Tab) == "table" and not Tab.IsKeyTab then
                FluentSkin:HookTab(Tab)
            end
        end
    end
end

function FluentSkin:HookTab(Tab)
    if not Tab or Tab.__FluentHooked then return end
    Tab.__FluentHooked = true
    self:SkinTabButton(Tab)

    local origAddGroupbox = Tab.AddGroupbox
    if typeof(origAddGroupbox) ~= "function" then return end

    Tab.AddGroupbox = function(self2, ...)
        local Groupbox = origAddGroupbox(self2, ...)
        FluentSkin:SkinGroupbox(Groupbox)
        return Groupbox
    end
end

function FluentSkin:SkinTabButton(Tab)
    local Btn = Tab.Button
    if not Btn then return end
    local C = self.C
    Btn.Size = UDim2.new(1, 0, 0, 38)

    local corner = ensure(Btn, "UICorner")
    corner.CornerRadius = UDim.new(0, C.Corner)

    for _, d in ipairs(Btn:GetDescendants()) do
        if d:IsA("TextLabel") then
            d.FontFace = C.Font
            d.TextSize = 14
            d.TextColor3 = C.Text
        end
    end
end

function FluentSkin:SkinGroupbox(Groupbox)
    if not Groupbox or Groupbox.__FluentSkinned then return end
    Groupbox.__FluentSkinned = true
    local C = self.C

    local Holder = Groupbox.Holder
    if not Holder then return end

    Holder.BackgroundTransparency = 1
    local stroke = Holder:FindFirstChildOfClass("UIStroke")
    if stroke then stroke.Transparency = 1 end

    local header
    for _, ch in ipairs(Holder:GetChildren()) do
        if ch:IsA("Frame") and ch.AutomaticSize == Enum.AutomaticSize.Y then
            header = ch
            break
        end
    end

    if header then
        local pad = ensure(header, "UIPadding")
        pad.PaddingTop = UDim.new(0, 10)
        pad.PaddingBottom = UDim.new(0, 8)
        pad.PaddingLeft = UDim.new(0, 4)
        pad.PaddingRight = UDim.new(0, 4)

        for _, d in ipairs(header:GetDescendants()) do
            if d:IsA("TextLabel") then
                d.FontFace = C.Font
                d.TextSize = 18
                d.TextColor3 = C.Text
            end
        end
    end

    local Container = Groupbox.Container
    if Container then
        local list = Container:FindFirstChildOfClass("UIListLayout")
        if list then list.Padding = UDim.new(0, 5) end
    end

    local wrappers = {
        AddToggle   = "SkinToggle",
        AddSlider   = "SkinSlider",
        AddDropdown = "SkinDropdown",
        AddInput    = "SkinInput",
        AddButton   = "SkinButton",
        AddLabel    = "SkinLabel",
        AddDivider  = "SkinDivider",
    }

    for method, skinFn in pairs(wrappers) do
        local orig = Groupbox[method]
        if typeof(orig) == "function" then
            Groupbox[method] = function(self2, ...)
                local elem = orig(self2, ...)
                if elem and FluentSkin[skinFn] then
                    FluentSkin[skinFn](FluentSkin, elem)
                end
                return elem
            end
        end
    end
end

function FluentSkin:MakeCard(Holder, height)
    local C = self.C
    if not Holder or not Holder.Parent then return end
    Holder.Size = UDim2.new(1, 0, 0, height or C.ElementH)
    Holder.BackgroundColor3 = C.Card
    Holder.BackgroundTransparency = C.CardT

    local corner = ensure(Holder, "UICorner")
    corner.CornerRadius = UDim.new(0, C.Corner)

    local stroke = ensure(Holder, "UIStroke")
    stroke.Color = C.Border
    stroke.Transparency = C.BorderT
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Thickness = 1

    Holder.MouseEnter:Connect(function()
        tween(Holder, 0.15, { BackgroundTransparency = C.CardHover })
    end)
    Holder.MouseLeave:Connect(function()
        tween(Holder, 0.15, { BackgroundTransparency = C.CardT })
    end)
end

function FluentSkin:SkinToggle(Toggle)
    if not Toggle or Toggle.__FluentVisual then return end
    Toggle.__FluentVisual = true
    local C = self.C
    local Holder = Toggle.Holder
    if not Holder then return end

    self:MakeCard(Holder, C.ElementH)

    local Label = Toggle.TextLabel
    if Label then
        Label.FontFace = C.Font
        Label.TextSize = 14
        Label.TextColor3 = C.Text
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Size = UDim2.new(1, -60, 1, 0)
        Label.Position = UDim2.new(0, 12, 0, 0)
    end

    for _, ch in ipairs(Holder:GetChildren()) do
        if ch:IsA("Frame") and ch.AnchorPoint == Vector2.new(1, 0) then
            ch.Size = UDim2.fromOffset(38, 20)
            ch.AnchorPoint = Vector2.new(1, 0.5)
            ch.Position = UDim2.new(1, -12, 0.5, 0)
            local sc = ch:FindFirstChildOfClass("UICorner")
            if sc then sc.CornerRadius = UDim.new(1, 0) end
            local ss = ch:FindFirstChildOfClass("UIStroke")
            if ss then ss.Transparency = 0.6 end
            break
        end
    end
end

function FluentSkin:SkinSlider(Slider)
    if not Slider or Slider.__FluentVisual then return end
    Slider.__FluentVisual = true
    local C = self.C
    local Holder = Slider.Holder
    if not Holder then return end

    self:MakeCard(Holder, 54)

    for _, d in ipairs(Holder:GetDescendants()) do
        if d:IsA("TextLabel") then
            d.FontFace = C.Font
            d.TextColor3 = C.Text
        end
    end
end

function FluentSkin:SkinDropdown(Dropdown)
    if not Dropdown or Dropdown.__FluentVisual then return end
    Dropdown.__FluentVisual = true
    local C = self.C
    local Holder = Dropdown.Holder
    if not Holder then return end

    local h = Dropdown.Text and 60 or C.ElementH
    self:MakeCard(Holder, h)

    for _, d in ipairs(Holder:GetDescendants()) do
        if d:IsA("TextLabel") then
            d.FontFace = C.Font
            d.TextSize = 14
            d.TextColor3 = C.Text
        end
    end
end

function FluentSkin:SkinInput(Input)
    if not Input or Input.__FluentVisual then return end
    Input.__FluentVisual = true
    local C = self.C
    local Holder = Input.Holder
    if not Holder then return end

    self:MakeCard(Holder, 62)

    for _, d in ipairs(Holder:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextBox") then
            d.FontFace = C.Font
            d.TextColor3 = C.Text
        end
    end
end

function FluentSkin:SkinButton(Button)
    if not Button or Button.__FluentVisual then return end
    Button.__FluentVisual = true
    local C = self.C
    local Holder = Button.Holder
    local Base = Button.Base
    if not Holder or not Base then return end

    Holder.Size = UDim2.new(1, 0, 0, 32)
    Base.BackgroundColor3 = C.Card
    Base.BackgroundTransparency = C.CardT
    Base.TextColor3 = C.Text
    Base.TextSize = 14
    Base.FontFace = C.Font

    local corner = ensure(Base, "UICorner")
    corner.CornerRadius = UDim.new(0, C.Corner)

    local stroke = ensure(Base, "UIStroke")
    stroke.Color = C.Border
    stroke.Transparency = C.BorderT

    Base.MouseEnter:Connect(function()
        tween(Base, 0.15, { BackgroundTransparency = C.CardHover })
    end)
    Base.MouseLeave:Connect(function()
        tween(Base, 0.15, { BackgroundTransparency = C.CardT })
    end)
end

function FluentSkin:SkinLabel(Label)
    if not Label or Label.__FluentVisual then return end
    Label.__FluentVisual = true
    local C = self.C
    if Label.TextLabel then
        Label.TextLabel.FontFace = C.Font
        Label.TextLabel.TextColor3 = C.Text
    end
end

function FluentSkin:SkinDivider(Divider)
    if not Divider or Divider.__FluentVisual then return end
    Divider.__FluentVisual = true
end

getgenv().ObsidianFluentSkin = FluentSkin
return FluentSkin
