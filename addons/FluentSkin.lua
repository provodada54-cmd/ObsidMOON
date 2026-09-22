local FluentSkin = {
    Library = nil,
    C = {
        Bg      = Color3.fromRGB(20, 20, 20),
        Card    = Color3.fromRGB(120, 120, 120),
        Border  = Color3.fromRGB(90, 90, 90),
        Text    = Color3.fromRGB(240, 240, 240),
        Accent  = Color3.fromRGB(96, 205, 255),
        Corner  = 6,
    },
}

function FluentSkin:SetLibrary(Library)
    self.Library = Library

    Library.Scheme.BackgroundColor = self.C.Bg
    Library.Scheme.MainColor       = self.C.Card
    Library.Scheme.AccentColor     = self.C.Accent
    Library.Scheme.OutlineColor    = self.C.Border
    Library.Scheme.FontColor       = self.C.Text
    Library.CornerRadius           = self.C.Corner
    Library:UpdateColorsUsingRegistry()

    self:HookWindow(Library.Window)
    return self
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

    local origAddGroupbox = Tab.AddGroupbox
    if typeof(origAddGroupbox) ~= "function" then return end

    Tab.AddGroupbox = function(self, ...)
        local Groupbox = origAddGroupbox(self, ...)
        FluentSkin:SkinGroupbox(Groupbox)
        return Groupbox
    end
end

function FluentSkin:SkinGroupbox(Groupbox)
    if not Groupbox or Groupbox.__FluentSkinned then return end
    Groupbox.__FluentSkinned = true

    local Holder = Groupbox.Holder
    if not Holder then return end

    -- Rounded corners on the groupbox card
    local corner = Holder:FindFirstChildOfClass("UICorner")
    if not corner then
        corner = Instance.new("UICorner")
        corner.Parent = Holder
    end
    corner.CornerRadius = UDim.new(0, 8)

    -- Find header frame (transparent + auto Y)
    local top
    for _, ch in ipairs(Holder:GetChildren()) do
        if ch:IsA("Frame") and ch.AutomaticSize == Enum.AutomaticSize.Y and ch.BackgroundTransparency == 1 then
            top = ch
            break
        end
    end

    if top then
        local pad = top:FindFirstChildOfClass("UIPadding")
        if not pad then
            pad = Instance.new("UIPadding")
            pad.Parent = top
        end
        pad.PaddingBottom = UDim.new(0, 10)
        pad.PaddingLeft = UDim.new(0, 12)
        pad.PaddingRight = UDim.new(0, 12)
        pad.PaddingTop = UDim.new(0, 12)

        for _, d in ipairs(top:GetDescendants()) do
            if d:IsA("TextLabel") then
                d.TextSize = 15
            end
        end
    end

    -- Container padding (space around inner elements)
    local Container = Groupbox.Container
    if Container then
        local pad = Container:FindFirstChildOfClass("UIPadding")
        if not pad then
            pad = Instance.new("UIPadding")
            pad.Parent = Container
        end
        pad.PaddingBottom = UDim.new(0, 10)
        pad.PaddingLeft = UDim.new(0, 10)
        pad.PaddingRight = UDim.new(0, 10)
        pad.PaddingTop = UDim.new(0, 6)

        local list = Container:FindFirstChildOfClass("UIListLayout")
        if list then
            list.Padding = UDim.new(0, 6)
        end
    end

    -- Spacing between header and content
    for _, ch in ipairs(Holder:GetChildren()) do
        if ch:IsA("UIListLayout") then
            ch.Padding = UDim.new(0, 4)
        end
    end
end

getgenv().ObsidianFluentSkin = FluentSkin
return FluentSkin
