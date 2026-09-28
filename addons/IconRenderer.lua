local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local Assets       = ReplicatedStorage:WaitForChild("Assets")
local SwordsFolder = Assets:WaitForChild("Swords")
local ItemsFolder  = Assets:WaitForChild("Items")

local DataBins    = ReplicatedStorage:WaitForChild("DataBins")
local ItemData    = require(DataBins:WaitForChild("ItemData"))
local EnchantData = require(DataBins:WaitForChild("EnchantData"))

local IconRenderer = {}

local CAMERA = {
    Sword = { FOV = 70, Angle = 0,                  Distance = 8 },
    Item  = { FOV = 30, Angle = 0.4487989505128276, Distance = 8 },
    Pose  = { FOV = 30, Angle = 0.4487989505128276, Distance = 8 },
}

local function prepareEffects(model)
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then
            d.Anchored = true
            d.CanCollide = false
        elseif d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail")
            or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles")
            or d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then
            d.Enabled = true
        end
    end
end

local function clearViewport(viewport)
    for _, c in ipairs(viewport:GetChildren()) do
        if c:IsA("Model") or c:IsA("BasePart") or c:IsA("Camera") then
            c:Destroy()
        end
    end
end

local function getOrCreateCamera(viewport)
    local cam = viewport:FindFirstChildOfClass("Camera")
    if not cam then
        cam = Instance.new("Camera")
        cam.Parent = viewport
    end
    viewport.CurrentCamera = cam
    return cam
end

local function applyCamera(cam, model, preset)
    local cfg = CAMERA[preset] or CAMERA.Item
    cam.FieldOfView = cfg.FOV
    local pivot = model:GetPivot()
    cam.CFrame = pivot * CFrame.Angles(0, cfg.Angle, 0) * CFrame.new(0, 0, cfg.Distance)
end

function IconRenderer.Render3D(viewport, source, preset)
    if not viewport or not source then return nil end
    clearViewport(viewport)

    local model = source:Clone()
    model.Parent = viewport
    prepareEffects(model)

    local cam = getOrCreateCamera(viewport)
    applyCamera(cam, model, preset)
    return model, cam
end

function IconRenderer.RenderSword(viewport, swordName, opts)
    opts = opts or {}
    if type(swordName) ~= "string" or swordName == "" then return nil end

    local template = SwordsFolder:FindFirstChild(swordName)
    if not template then return nil end

    local model, cam = IconRenderer.Render3D(viewport, template, "Sword")
    if not model then return nil end

    if opts.shiny then
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("BasePart") then
                d.Material = Enum.Material.Neon
                d.Reflectance = math.max(d.Reflectance, 0.3)
            end
        end
    end

    if opts.ascended or opts.vfxColor then
        local Packages = ReplicatedStorage:FindFirstChild("Packages")
        local sv = Packages and Packages:FindFirstChild("SwordVisuals")
        if sv then
            local ok, mod = pcall(require, sv)
            if ok and mod and mod.Apply then
                pcall(function()
                    mod.Apply(model, { Ascension = true, VFXColor = opts.vfxColor })
                end)
            end
        end
    end

    return model, cam
end

function IconRenderer.RenderAura(viewport, auraName)
    if type(auraName) ~= "string" or auraName == "" then return nil end
    local template = ItemsFolder:FindFirstChild(auraName)
    if not template then return nil end
    if not (template:IsA("Model") or template:IsA("BasePart")) then return nil end
    return IconRenderer.Render3D(viewport, template, "Item")
end

local function rigTemplate()
    local rig = Assets:FindFirstChild("CharacterRigR15")
    if rig and rig:IsA("Model") then return rig end
    return nil
end

local function getAnimation(animId)
    local ok, objs = pcall(game.GetObjects, game, "rbxassetid://" .. tostring(animId))
    if not ok or not objs or not objs[1] then return nil end
    local obj = objs[1]
    if obj:IsA("Animation") then return obj end
    if obj:IsA("KeyframeSequence") then
        local a = Instance.new("Animation")
        a.AnimationId = "rbxassetid://" .. tostring(animId)
        return a
    end
    return nil
end

function IconRenderer.RenderPose(viewport, poseName)
    if type(poseName) ~= "string" or poseName == "" then return nil end
    if not viewport then return nil end

    local data = ItemData[poseName]
    if type(data) ~= "table" then return nil end
    local usage = data.UsageData
    local animId = type(usage) == "table" and usage[1]
    if not animId then return nil end

    local rig = rigTemplate()
    if not rig then return nil end

    clearViewport(viewport)

    local clone = rig:Clone()
    clone.Parent = viewport

    for _, d in ipairs(clone:GetDescendants()) do
        if d:IsA("Script") or d:IsA("LocalScript") then
            d:Destroy()
        elseif d:IsA("BasePart") then
            d.Anchored = true
            d.CanCollide = false
        end
    end

    local hum = clone:FindFirstChildOfClass("Humanoid") or clone:FindFirstChildWhichIsA("Humanoid", true)
    if not hum then return nil end

    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end

    local animObj = getAnimation(animId)
    if animObj then
        local okTrack, track = pcall(function() return animator:LoadAnimation(animObj) end)
        if okTrack and track then
            track.Priority = Enum.AnimationPriority.Action4
            track.Looped = true
            pcall(function()
                track:Play(0)
                track.Playing = false
                animator:StepAnimations(0.15)
            end)
        end
    end

    local cam = getOrCreateCamera(viewport)
    applyCamera(cam, clone, "Pose")
    return clone, cam
end

function IconRenderer.GetEnchantImage(enchName)
    local data = EnchantData[enchName]
    if type(data) == "table" then
        return data.ImageId or data.Icon or data.IconImage
    end
    return nil
end

function IconRenderer.GetItemImage(itemName)
    local data = ItemData[itemName]
    if type(data) == "table" then
        return data.ImageId or data.Icon or data.IconImage
    end
    return nil
end

function IconRenderer.GetPoseImage(poseName)
    local data = ItemData[poseName]
    if type(data) == "table" then
        if data.ImageId then return data.ImageId end
        local m = data.Meta
        if type(m) == "table" then
            return m.ImageId or m.Icon or m.IconImage
        end
    end
    return nil
end

return IconRenderer
