local TweenService = game:GetService("TweenService")

local FluentSkin = {
    Library = nil,

    C = {
        Bg      = Color3.fromRGB(20, 20, 20),
        Card    = Color3.fromRGB(120, 120, 120),
        CardT   = 0.87,
        CardG   = 0.94,
        Border  = Color3.fromRGB(35, 35, 35),
        InBorder= Color3.fromRGB(90, 90, 90),
        Text    = Color3.fromRGB(240, 240, 240),
        SubText = Color3.fromRGB(170, 170, 170),
        Accent  = Color3.fromRGB(96, 205, 255),
        AccentOff = Color3.fromRGB(120, 120, 120),
        Font    = Font.new("rbxasset://fonts/families/GothamSSm.json"),
        Corner  = 6,
        CardH   = 42,
        PadX    = 12,
    },
}

local function tween(inst, time, props, style)
    TweenService:Create(inst, TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
end

function FluentSkin:SetLibrary(Library)
    self.Library = Library
    self:ApplyScheme()
    self:HookWindow(Library.Window)
    return self
end

function FluentSkin:ApplyScheme()
    local L, C = self.Library, self.C
    L.Scheme.BackgroundColor = C.Bg
    L.Scheme.MainColor       = C.Card
    L.Scheme.AccentColor     = C.Accent
    L.Scheme.OutlineColor    = C.InBorder
    L.Scheme.FontColor       = C.Text
    L.Scheme.Font            = C.Font
    L.CornerRadius           = C.Corner
    L:UpdateColorsUsingRegistry()
end

function FluentSkin:HookWindow(Window)
    if not Window or Window.__FluentHooked then return end
    Window.__FluentHooked = true

    local origAddTab = Window.AddTab
    Window.AddTab = function(self, ...)
        local Tab = origAddTab(self, ...)
        FluentSkin:HookTab(Tab)
        return Tab
    end

    local L = self.Library
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

    local origAddGroupbox = Tab.AddGroupbox
    if typeof(origAddGroupbox) ~= "function" then return end

    Tab.AddGroupbox = function(self, ...)
        local Groupbox = origAddGroupbox(self, ...)
        task.defer(function() FluentSkin:SkinGroupbox(Groupbox) end)
        return Groupbox
    end
end

function FluentSkin:SkinGroupbox(Groupbox)
    if not Groupbox or Groupbox.__FluentSkinned then return end
    Groupbox.__FluentSkinned = true

    self:SkinGroupboxVisual(Groupbox)

    local origAddToggle    = Groupbox.AddToggle
    local origAddSlider    = Groupbox.AddSlider
    local origAddDropdown  = Groupbox.AddDropdown
    local origAddInput     = Groupbox.AddInput
    local origAddButton    = Groupbox.AddButton

    if origAddToggle then
        Groupbox.AddToggle = function(self2, Idx, Info)
            local T = origAddToggle(self2, Idx, Info)
            task.defer(function() FluentSkin:SkinToggle(T) end)
            return T
        end
    end
    if origAddSlider then
        Groupbox.AddSlider = function(self2, Idx, Info)
            local S = origAddSlider(self2, Idx, Info)
            task.defer(function() FluentSkin:SkinSlider(S) end)
            return S
        end
    end
    if origAddDropdown then
        Groupbox.AddDropdown = function(self2, Idx, Info)
            local D = origAddDropdown(self2, Idx, Info)
            task.defer(function() FluentSkin:SkinDropdown(D) end)
            return D
        end
    end
    if origAddInput then
        Groupbox.AddInput = function(self2, Idx, Info)
            local I = origAddInput(self2, Idx, Info)
            task.defer(function() FluentSkin:SkinInput(I) end)
            return I
        end
    end
    if origAddButton then
        Groupbox.AddButton = function(self2, Idx, Info)
            local B = origAddButton(self2, Idx, Info)
            task.defer(function() FluentSkin:SkinButton(B) end)
            return B
        end
    end
end

-- Groupbox card: soft transparent card, no visible top border, bigger title
function FluentSkin:SkinGroupboxVisual(Groupbox)
    local C = self.C
    local holder = Groupbox.Holder
    if not holder then return end

    holder.BackgroundColor3 = C.Card
    holder.BackgroundTransparency = C.CardG

    local stroke = holder:FindFirstChildOfClass("UIStroke")
    if stroke then
        stroke.Color = C.Border
        stroke.Transparency = 0.75
        stroke.Thickness = 1
    end

    -- find GroupboxTop by AutomaticSize.Y
    local top
    for _, ch in ipairs(holder:GetChildren()) do
        if ch:IsA("Frame") and ch.AutomaticSize == Enum.AutomaticSize.Y then
            top = ch
            break
        end
    end

    if top then
        for _, ch in ipairs(top:GetDescendants()) do
            if ch:IsA("TextLabel") then
                ch.FontFace = C.Font
                ch.TextColor3 = C.Text
                ch.TextSize = 15
            end
        end
    end
end

function FluentSkin:SkinToggle(Toggle)
    if not Toggle or Toggle.__FluentVisual then return end
    Toggle.__FluentVisual = true
    local C = self.C
    local Holder, Label = Toggle.Holder, Toggle.TextLabel
    if not Holder or not Label then return end

    Holder.Size = UDim2.new(1, 0, 0, C.CardH)
    Holder.BackgroundColor3 = C.Card
    Holder.BackgroundTransparency = C.CardT

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, C.Corner)
    corner.Parent = Holder

    local stroke = Instance.new("UIStroke")
    stroke.Color = C.Border
    stroke.Transparency = 0.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = Holder

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, C.PadX)
    pad.PaddingRight = UDim.new(0, C.PadX)
    pad.Parent = Holder

    Label.FontFace = C.Font
    Label.TextSize = 13
    Label.TextColor3 = C.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Size = UDim2.new(1, -50, 1, 0)
    Label.Position = UDim2.new(0, 0, 0, 0)

    for _, child in ipairs(Holder:GetChildren()) do
        if child:IsA("Frame") and child ~= Label and child.Name ~= "FluentSwitch" then
            child:Destroy()
        end
    end

    local Switch = Instance.new("Frame")
    Switch.Name = "FluentSwitch"
    Switch.Size = UDim2.fromOffset(36, 18)
    Switch.AnchorPoint = Vector2.new(1, 0.5)
    Switch.Position = UDim2.new(1, 0, 0.5, 0)
    Switch.BackgroundColor3 = Toggle.Value and C.Accent or C.AccentOff
    Switch.BackgroundTransparency = Toggle.Value and 0 or 0.55
    Switch.Parent = Holder

    local sc = Instance.new("UICorner")
    sc.CornerRadius = UDim.new(1, 0)
    sc.Parent = Switch

    local ss = Instance.new("UIStroke")
    ss.Color = C.InBorder
    ss.Transparency = 0.5
    ss.Parent = Switch

    local spad = Instance.new("UIPadding")
    spad.PaddingTop = UDim.new(0, 2)
    spad.PaddingBottom = UDim.new(0, 2)
    spad.PaddingLeft = UDim.new(0, 2)
    spad.PaddingRight = UDim.new(0, 2)
    spad.Parent = Switch

    local Ball = Instance.new("Frame")
    Ball.Name = "FluentBall"
    Ball.Size = UDim2.fromScale(1, 1)
    Ball.SizeConstraint = Enum.SizeConstraint.RelativeYY
    Ball.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Ball.AnchorPoint = Vector2.new(Toggle.Value and 1 or 0, 0)
    Ball.Position = UDim2.new(Toggle.Value and 1 or 0, 0, 0, 0)
    Ball.Parent = Switch

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(1, 0)
    bc.Parent = Ball

    local origSetValue = Toggle.SetValue
    Toggle.SetValue = function(self2, value)
        origSetValue(self2, value)
        tween(Ball, 0.25, {
            Position = UDim2.new(value and 1 or 0, 0, 0, 0),
            AnchorPoint = Vector2.new(value and 1 or 0, 0),
        })
        tween(Switch, 0.25, {
            BackgroundColor3 = value and C.Accent or C.AccentOff,
            BackgroundTransparency = value and 0 or 0.55,
        })
    end

    Holder.MouseEnter:Connect(function()
        tween(Holder, 0.15, { BackgroundTransparency = C.CardT - 0.07 })
    end)
    Holder.MouseLeave:Connect(function()
        tween(Holder, 0.15, { BackgroundTransparency = C.CardT })
    end)
end

function FluentSkin:SkinSlider(Slider)
    if not Slider or Slider.__FluentVisual then return end
    Slider.__FluentVisual = true
    local C = self.C
    local Holder = Slider.Holder
    if not Holder then return end

    Holder.Size = UDim2.new(1, 0, 0, C.CardH)
    Holder.BackgroundColor3 = C.Card
    Holder.BackgroundTransparency = C.CardT

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, C.Corner)
    corner.Parent = Holder

    local stroke = Instance.new("UIStroke")
    stroke.Color = C.Border
    stroke.Transparency = 0.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = Holder

    for _, ch in ipairs(Holder:GetDescendants()) do
        if ch:IsA("TextLabel") then
            ch.FontFace = C.Font
            ch.TextSize = 12
            ch.TextColor3 = C.SubText
        end
    end

    Holder.MouseEnter:Connect(function()
        tween(Holder, 0.15, { BackgroundTransparency = C.CardT - 0.07 })
    end)
    Holder.MouseLeave:Connect(function()
        tween(Holder, 0.15, { BackgroundTransparency = C.CardT })
    end)
end

function FluentSkin:SkinDropdown(Dropdown)
    if not Dropdown or Dropdown.__FluentVisual then return end
    Dropdown.__FluentVisual = true
    local C = self.C
    local Holder = Dropdown.Holder
    if not Holder then return end

    Holder.Size = UDim2.new(1, 0, 0, C.CardH + (Dropdown.Text and 16 or 0))
    Holder.BackgroundColor3 = C.Card
    Holder.BackgroundTransparency = C.CardT

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, C.Corner)
    corner.Parent = Holder

    local stroke = Instance.new("UIStroke")
    stroke.Color = C.Border
    stroke.Transparency = 0.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = Holder

    for _, ch in ipairs(Holder:GetDescendants()) do
        if ch:IsA("TextLabel") then
            ch.FontFace = C.Font
            ch.TextSize = 13
        end
    end

    Holder.MouseEnter:Connect(function()
        tween(Holder, 0.15, { BackgroundTransparency = C.CardT - 0.07 })
    end)
    Holder.MouseLeave:Connect(function()
        tween(Holder, 0.15, { BackgroundTransparency = C.CardT })
    end)
end

function FluentSkin:SkinInput(Input)
    if not Input or Input.__FluentVisual then return end
    Input.__FluentVisual = true
    local C = self.C
    local Holder = Input.Holder
    if not Holder then return end

    Holder.Size = UDim2.new(1, 0, 0, C.CardH + 16)
    Holder.BackgroundColor3 = C.Card
    Holder.BackgroundTransparency = C.CardT

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, C.Corner)
    corner.Parent = Holder

    local stroke = Instance.new("UIStroke")
    stroke.Color = C.Border
    stroke.Transparency = 0.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = Holder

    for _, ch in ipairs(Holder:GetDescendants()) do
        if ch:IsA("TextLabel") or ch:IsA("TextBox") then
            ch.FontFace = C.Font
            ch.TextColor3 = C.Text
        end
    end

    Holder.MouseEnter:Connect(function()
        tween(Holder, 0.15, { BackgroundTransparency = C.CardT - 0.07 })
    end)
    Holder.MouseLeave:Connect(function()
        tween(Holder, 0.15, { BackgroundTransparency = C.CardT })
    end)
end

function FluentSkin:SkinButton(Button)
    if not Button or Button.__FluentVisual then return end
    Button.__FluentVisual = true
    local C = self.C
    local Holder, Base = Button.Holder, Button.Base
    if not Holder or not Base then return end

    Holder.Size = UDim2.new(1, 0, 0, 30)
    Base.BackgroundColor3 = C.Card
    Base.BackgroundTransparency = C.CardT
    Base.TextColor3 = C.Text
    Base.TextSize = 13
    Base.FontFace = C.Font

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, C.Corner)
    corner.Parent = Base

    local stroke = Instance.new("UIStroke")
    stroke.Color = C.Border
    stroke.Transparency = 0.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = Base

    Base.MouseEnter:Connect(function()
        tween(Base, 0.15, { BackgroundColor3 = C.Accent, BackgroundTransparency = 0.5 })
    end)
    Base.MouseLeave:Connect(function()
        tween(Base, 0.15, { BackgroundColor3 = C.Card, BackgroundTransparency = C.CardT })
    end)
end

getgenv().ObsidianFluentSkin = FluentSkin
return FluentSkin
