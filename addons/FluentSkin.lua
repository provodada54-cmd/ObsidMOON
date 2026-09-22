local TweenService = game:GetService("TweenService")

local FluentSkin = {
    Library = nil,

    C = {
        Bg      = Color3.fromRGB(20, 20, 20),
        Card    = Color3.fromRGB(120, 120, 120),
        CardT   = 0.87,
        Border  = Color3.fromRGB(35, 35, 35),
        InBorder= Color3.fromRGB(90, 90, 90),
        Text    = Color3.fromRGB(240, 240, 240),
        SubText = Color3.fromRGB(170, 170, 170),
        Accent  = Color3.fromRGB(96, 205, 255),
        Font    = Font.new("rbxasset://fonts/families/GothamSSm.json"),
        Corner  = 6,
        CardH   = 42,
        PadX    = 12,
    },
}

local function tween(inst, time, props, style)
    if not inst or not inst.Parent then return end
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

function FluentSkin:SkinGroupboxVisual(Groupbox)
    local C = self.C
    local holder = Groupbox.Holder
    if not holder then return end

    holder.BackgroundColor3 = C.Card
    holder.BackgroundTransparency = 0.94

    local stroke = holder:FindFirstChildOfClass("UIStroke")
    if stroke then
        stroke.Color = C.Border
        stroke.Transparency = 0.75
        stroke.Thickness = 1
    end

    for _, ch in ipairs(holder:GetDescendants()) do
        if ch:IsA("TextLabel") then
            ch.FontFace = C.Font
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

    local corner = Holder:FindFirstChildOfClass("UICorner")
    if not corner then
        corner = Instance.new("UICorner")
        corner.Parent = Holder
    end
    corner.CornerRadius = UDim.new(0, C.Corner)

    local stroke = Holder:FindFirstChildOfClass("UIStroke")
    if not stroke then
        stroke = Instance.new("UIStroke")
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = Holder
    end
    stroke.Color = C.Border
    stroke.Transparency = 0.5

    local pad = Holder:FindFirstChildOfClass("UIPadding")
    if not pad then
        pad = Instance.new("UIPadding")
        pad.Parent = Holder
    end
    pad.PaddingLeft = UDim.new(0, C.PadX)
    pad.PaddingRight = UDim.new(0, C.PadX)

    Label.FontFace = C.Font
    Label.TextSize = 13
    Label.TextColor3 = C.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left

    for _, ch in ipairs(Holder:GetChildren()) do
        if ch:IsA("Frame") then
            for _, sub in ipairs(ch:GetDescendants()) do
                if sub:IsA("TextLabel") then
                    sub.FontFace = C.Font
                    sub.TextColor3 = C.Text
                end
            end
            for _, sub in ipairs(ch:GetChildren()) do
                if sub:IsA("UIStroke") then
                    sub.Transparency = 0.5
                end
            end
        end
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

    local corner = Holder:FindFirstChildOfClass("UICorner")
    if not corner then
        corner = Instance.new("UICorner")
        corner.Parent = Holder
    end
    corner.CornerRadius = UDim.new(0, C.Corner)

    local stroke = Holder:FindFirstChildOfClass("UIStroke")
    if not stroke then
        stroke = Instance.new("UIStroke")
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = Holder
    end
    stroke.Color = C.Border
    stroke.Transparency = 0.5

    local pad = Holder:FindFirstChildOfClass("UIPadding")
    if not pad then
        pad = Instance.new("UIPadding")
        pad.Parent = Holder
    end
    pad.PaddingLeft = UDim.new(0, C.PadX)
    pad.PaddingRight = UDim.new(0, C.PadX)

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

    local corner = Holder:FindFirstChildOfClass("UICorner")
    if not corner then
        corner = Instance.new("UICorner")
        corner.Parent = Holder
    end
    corner.CornerRadius = UDim.new(0, C.Corner)

    local stroke = Holder:FindFirstChildOfClass("UIStroke")
    if not stroke then
        stroke = Instance.new("UIStroke")
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = Holder
    end
    stroke.Color = C.Border
    stroke.Transparency = 0.5

    local pad = Holder:FindFirstChildOfClass("UIPadding")
    if not pad then
        pad = Instance.new("UIPadding")
        pad.Parent = Holder
    end
    pad.PaddingLeft = UDim.new(0, C.PadX)
    pad.PaddingRight = UDim.new(0, C.PadX)

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

    local corner = Holder:FindFirstChildOfClass("UICorner")
    if not corner then
        corner = Instance.new("UICorner")
        corner.Parent = Holder
    end
    corner.CornerRadius = UDim.new(0, C.Corner)

    local stroke = Holder:FindFirstChildOfClass("UIStroke")
    if not stroke then
        stroke = Instance.new("UIStroke")
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = Holder
    end
    stroke.Color = C.Border
    stroke.Transparency = 0.5

    local pad = Holder:FindFirstChildOfClass("UIPadding")
    if not pad then
        pad = Instance.new("UIPadding")
        pad.Parent = Holder
    end
    pad.PaddingLeft = UDim.new(0, C.PadX)
    pad.PaddingRight = UDim.new(0, C.PadX)

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

    local corner = Base:FindFirstChildOfClass("UICorner")
    if not corner then
        corner = Instance.new("UICorner")
        corner.Parent = Base
    end
    corner.CornerRadius = UDim.new(0, C.Corner)

    local stroke = Base:FindFirstChildOfClass("UIStroke")
    if not stroke then
        stroke = Instance.new("UIStroke")
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = Base
    end
    stroke.Color = C.Border
    stroke.Transparency = 0.5
end

getgenv().ObsidianFluentSkin = FluentSkin
return FluentSkin
