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
    return self
end

getgenv().ObsidianFluentSkin = FluentSkin
return FluentSkin
