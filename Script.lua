-- Linguagem: Lua | Executor: Delta | UI: Rayfield
-- Dep: Rayfield — carregado via HttpGet sirius.menu
-- Dep: getgenv() — estado global entre reinjeções
-- PlaceId FtF: 893973440

local Rayfield = loadstring(game:HttpGet(
    'https://sirius.menu/rayfield'))()

-- ── Serviços ───────────────────────────────────────────────────
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local UserInput     = game:GetService("UserInputService")
local TweenService  = game:GetService("TweenService")
local Camera        = workspace.CurrentCamera
local LocalPlayer   = Players.LocalPlayer

-- ── Estado global ──────────────────────────────────────────────
local cfg = getgenv().OllieFTF or {
    -- ESP
    SurvivorESP     = false,
    BeastESP        = false,
    ComputerESP     = false,
    ExitESP         = false,
    PodESP          = false,
    Chams           = false,
    Tracers         = false,
    SkeletonESP     = false,
    NametagESP      = false,
    DistanceESP     = false,
    StatusESP       = false,
    ComputerStatus  = false,
    BeastAlert      = false,
    BeastAlertDist  = 50,

    -- Survivor
    Speed           = false,
    SpeedVal        = 28,
    WalkspeedLock   = false,
    InfJump         = false,
    BunnyHop        = false,
    Fly             = false,
    NoClip          = false,
    NoCrawl         = false,
    InfStamina      = false,
    AntiFreeze      = false,
    InstantHack     = false,
    NoFailHack      = false,
    AutoHack        = false,
    AutoFree        = false,
    AutoEscape      = false,
    AutoDodge       = false,
    AutoDodgeDist   = 40,
    SafeZone        = false,
    SafeZoneDist    = 60,
    CompFinder      = false,
    PodFinder       = false,
    ExitFinder      = false,
    FakeLag         = false,
    FakeLagVal      = 0.1,

    -- Beast
    BeastAutoFreeze = false,
    BeastTeleport   = false,
    BeastNoCD       = false,
    BeastSpeed      = false,
    BeastSpeedVal   = 28,
    BeastOneHit     = false,
    BeastFreezeAll  = false,
    BeastFling      = false,

    -- Misc
    AntiAFK         = false,
    ChatSpammer     = false,
    ChatMsg         = "olliE ftf ez",
    ChatDelay       = 5,
    Rejoin          = false,
    StatsHUD        = false,
    AutoVote        = false,
    TrollMode       = false,
    Flashlight      = false,
    ServerHop       = false,
}
getgenv().OllieFTF = cfg

-- ── Util ───────────────────────────────────────────────────────
local function getChar()
    return LocalPlayer.Character
end

local function getRootPart()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function isAlive(player)
    local c = player.Character
    if not c then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function isBeast(player)
    -- Beast tem tag/valor no character ou nome de equipe
    local c = player.Character
    if not c then return false end
    -- checa team name
    if player.Team and player.Team.Name:lower():find("beast") then
        return true
    end
    -- checa valor no character
    local tag = c:FindFirstChild("IsBeast")
        or c:FindFirstChild("Beast")
    return tag ~= nil
end

local function isFrozen(player)
    local c = player.Character
    if not c then return false end
    return c:FindFirstChild("Frozen") ~= nil
        or c:FindFirstChild("IsFrozen") ~= nil
end

local function isHacking(player)
    local c = player.Character
    if not c then return false end
    return c:FindFirstChild("Hacking") ~= nil
        or c:FindFirstChild("IsHacking") ~= nil
end

local function worldToScreen(pos)
    local sp, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(sp.X, sp.Y), onScreen, sp.Z
end

local function distTo(part)
    local root = getRootPart()
    if not root or not part then return 999 end
    return math.floor((root.Position - part.Position).Magnitude)
end

-- ════════════════════════════════════════════════════════════════
--  ESP SISTEMA
-- ════════════════════════════════════════════════════════════════

-- ── Highlight ESP (Chams) ──────────────────────────────────────
local highlights = {}

local function clearHighlight(player)
    if highlights[player] then
        highlights[player]:Destroy()
        highlights[player] = nil
    end
end

local function buildHighlight(player, fillColor, outlineColor)
    clearHighlight(player)
    local hl = Instance.new("SelectionBox")
    -- usa Highlight se disponível
    local h = Instance.new("Highlight")
    h.FillColor         = fillColor
    h.OutlineColor      = outlineColor
    h.FillTransparency  = 0.5
    h.OutlineTransparency = 0
    h.DepthMode         = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent            = player.Character
    highlights[player]  = h
    return h
end

-- ── Drawing ESP ────────────────────────────────────────────────
local espDrawings = {}

local function clearDrawing(key)
    if espDrawings[key] then
        for _, d in pairs(espDrawings[key]) do
            pcall(function() d:Remove() end)
        end
        espDrawings[key] = nil
    end
end

local function makeText(size, color, outline)
    local t = Drawing.new("Text")
    t.Size    = size or 13
    t.Color   = color or Color3.fromRGB(255,255,255)
    t.Outline = outline ~= false
    t.Center  = true
    t.Visible = false
    return t
end

local function makeLine(color, thickness)
    local l = Drawing.new("Line")
    l.Color     = color or Color3.fromRGB(255,255,255)
    l.Thickness = thickness or 1
    l.Visible   = false
    return l
end

local function makeBox(color, thickness)
    local b = Drawing.new("Square")
    b.Color     = color or Color3.fromRGB(255,255,255)
    b.Thickness = thickness or 1.5
    b.Filled    = false
    b.Visible   = false
    return b
end

-- ── ESP de jogador ─────────────────────────────────────────────
local playerESP = {}

local function clearPlayerESP(player)
    clearDrawing("player_" .. player.UserId)
    clearHighlight(player)
    playerESP[player] = nil
end

local function buildPlayerESP(player)
    if player == LocalPlayer then return end
    clearPlayerESP(player)

    local beast    = isBeast(player)
    local fillCol  = beast
        and Color3.fromRGB(220, 30, 30)
        or  Color3.fromRGB(30, 220, 80)
    local lblCol   = beast
        and Color3.fromRGB(255, 80, 80)
        or  Color3.fromRGB(80, 255, 120)

    local drawings = {
        box      = makeBox(fillCol, 1.5),
        name     = makeText(13, lblCol),
        dist     = makeText(11, Color3.fromRGB(200,200,200)),
        status   = makeText(11, Color3.fromRGB(255,220,50)),
        tracer   = makeLine(fillCol, 1),
    }

    -- skeleton lines (8 conexões básicas)
    drawings.bones = {}
    for i = 1, 8 do
        table.insert(drawings.bones, makeLine(fillCol, 1))
    end

    espDrawings["player_" .. player.UserId] = drawings

    -- Highlight/Chams
    if cfg.Chams then
        pcall(function()
            buildHighlight(player, fillCol,
                Color3.fromRGB(255,255,255))
        end)
    end

    playerESP[player] = drawings
end

-- conexões de esqueleto — pares de partes do corpo
local BONE_PAIRS = {
    {"Head",        "UpperTorso"},
    {"UpperTorso",  "LowerTorso"},
    {"LowerTorso",  "LeftUpperLeg"},
    {"LowerTorso",  "RightUpperLeg"},
    {"LeftUpperLeg","LeftLowerLeg"},
    {"RightUpperLeg","RightLowerLeg"},
    {"UpperTorso",  "LeftUpperArm"},
    {"UpperTorso",  "RightUpperArm"},
}

RunService.RenderStepped:Connect(function()
    for player, drawings in pairs(playerESP) do
        local beast   = isBeast(player)
        local enabled = beast and cfg.BeastESP or cfg.SurvivorESP

        local function hideAll()
            for _, d in pairs(drawings) do
                if type(d) == "table" then
                    for _, b in pairs(d) do b.Visible = false end
                else
                    d.Visible = false
                end
            end
            clearHighlight(player)
        end

        if not enabled then hideAll() ; goto continue end

        local char = player.Character
        if not char or not isAlive(player) then
            hideAll() ; goto continue
        end

        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        if not root or not head then hideAll() ; goto continue end

        local rootSc, onScreen, depth = worldToScreen(root.Position)
        local headSc = worldToScreen(head.Position)

        if not onScreen or depth < 0 then
            hideAll() ; goto continue
        end

        local h = (headSc - rootSc).Magnitude * 2
        local w = h * 0.55

        -- Box
        drawings.box.Visible  = true
        drawings.box.Size     = Vector2.new(w, h)
        drawings.box.Position = Vector2.new(
            rootSc.X - w/2, rootSc.Y - h)
        drawings.box.Color    = beast
            and Color3.fromRGB(220,30,30)
            or  Color3.fromRGB(30,220,80)

        -- Nome
        if cfg.NametagESP then
            drawings.name.Visible  = true
            drawings.name.Text     = (beast and "👹 " or "🟢 ")
                .. player.DisplayName
            drawings.name.Position = Vector2.new(
                rootSc.X, rootSc.Y - h - 14)
        else
            drawings.name.Visible = false
        end

        -- Distância
        if cfg.DistanceESP then
            drawings.dist.Visible  = true
            drawings.dist.Text     = distTo(root) .. "m"
            drawings.dist.Position = Vector2.new(
                rootSc.X, rootSc.Y + 3)
        else
            drawings.dist.Visible = false
        end

        -- Status
        if cfg.StatusESP then
            local status = isFrozen(player) and "❄ FROZEN"
                or isHacking(player) and "💻 HACKING"
                or "● FREE"
            drawings.status.Visible  = true
            drawings.status.Text     = status
            drawings.status.Position = Vector2.new(
                rootSc.X, rootSc.Y + 15)
        else
            drawings.status.Visible = false
        end

        -- Tracer
        if cfg.Tracers then
            drawings.tracer.Visible = true
            drawings.tracer.From    = Vector2.new(
                Camera.ViewportSize.X / 2,
                Camera.ViewportSize.Y)
            drawings.tracer.To      = rootSc
            drawings.tracer.Color   = beast
                and Color3.fromRGB(220,30,30)
                or  Color3.fromRGB(30,220,80)
        else
            drawings.tracer.Visible = false
        end

        -- Skeleton
        if cfg.SkeletonESP then
            for i, pair in ipairs(BONE_PAIRS) do
                local p1 = char:FindFirstChild(pair[1])
                local p2 = char:FindFirstChild(pair[2])
                local bone = drawings.bones[i]
                if p1 and p2 and bone then
                    local s1, on1 = worldToScreen(p1.Position)
                    local s2, on2 = worldToScreen(p2.Position)
                    bone.Visible = on1 and on2
                    bone.From    = s1
                    bone.To      = s2
                    bone.Color   = beast
                        and Color3.fromRGB(220,30,30)
                        or  Color3.fromRGB(30,220,80)
                else
                    if bone then bone.Visible = false end
                end
            end
        else
            for _, bone in pairs(drawings.bones) do
                bone.Visible = false
            end
        end

        -- Chams/Highlight
        if cfg.Chams then
            if not highlights[player] and char then
                pcall(function()
                    buildHighlight(player,
                        beast and Color3.fromRGB(220,30,30)
                               or Color3.fromRGB(30,220,80),
                        Color3.fromRGB(255,255,255))
                end)
            end
        else
            clearHighlight(player)
        end

        ::continue::
    end
end)

Players.PlayerAdded:Connect(buildPlayerESP)
Players.PlayerRemoving:Connect(clearPlayerESP)
for _, p in ipairs(Players:GetPlayers()) do buildPlayerESP(p) end

-- ── ESP de Computadores ────────────────────────────────────────
local compDrawings = {}

local function findComputers()
    local comps = {}
    -- nome comum dos computadores em FtF
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name:lower():find("computer")
        or obj.Name:lower():find("terminal")
        or obj.Name:lower():find("hack") then
            if obj:IsA("BasePart") or obj:IsA("Model") then
                table.insert(comps, obj)
            end
        end
    end
    return comps
end

RunService.RenderStepped:Connect(function()
    -- limpa drawings antigas
    for key, d in pairs(compDrawings) do
        pcall(function() d.label:Remove() end)
        pcall(function() d.tracer:Remove() end)
        compDrawings[key] = nil
    end

    if not cfg.ComputerESP then return end

    for _, comp in ipairs(findComputers()) do
        local pos = comp:IsA("Model")
            and comp:GetModelCFrame().Position
            or  comp.Position

        local screen, onScreen, depth = worldToScreen(pos)
        if not onScreen or depth < 0 then goto compNext end

        local lbl    = Drawing.new("Text")
        local tracer = Drawing.new("Line")

        lbl.Text     = cfg.ComputerStatus
            and "💻 COMP ~" .. math.floor(depth) .. "m"
            or  "💻 " .. math.floor(depth) .. "m"
        lbl.Position = screen
        lbl.Size     = 13
        lbl.Color    = Color3.fromRGB(50, 200, 255)
        lbl.Outline  = true
        lbl.Center   = true
        lbl.Visible  = true

        tracer.From      = Vector2.new(
            Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
        tracer.To        = screen
        tracer.Color     = Color3.fromRGB(50,200,255)
        tracer.Thickness = 1
        tracer.Visible   = true

        compDrawings[tostring(comp)] = {label=lbl, tracer=tracer}
        ::compNext::
    end
end)

-- ── ESP de Freeze Pods ─────────────────────────────────────────
local podDrawings = {}

local function findPods()
    local pods = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name:lower():find("pod")
        or obj.Name:lower():find("freeze")
        or obj.Name:lower():find("crystal") then
            if obj:IsA("BasePart") or obj:IsA("Model") then
                table.insert(pods, obj)
            end
        end
    end
    return pods
end

RunService.RenderStepped:Connect(function()
    for key, d in pairs(podDrawings) do
        pcall(function() d.label:Remove() end)
        pcall(function() d.tracer:Remove() end)
        podDrawings[key] = nil
    end

    if not cfg.PodESP then return end

    for _, pod in ipairs(findPods()) do
        local pos = pod:IsA("Model")
            and pod:GetModelCFrame().Position
            or  pod.Position

        local screen, onScreen, depth = worldToScreen(pos)
        if not onScreen or depth < 0 then goto podNext end

        local lbl    = Drawing.new("Text")
        local tracer = Drawing.new("Line")

        lbl.Text     = "❄ POD " .. math.floor(depth) .. "m"
        lbl.Position = screen
        lbl.Size     = 13
        lbl.Color    = Color3.fromRGB(150, 220, 255)
        lbl.Outline  = true
        lbl.Center   = true
        lbl.Visible  = true

        tracer.From      = Vector2.new(
            Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
        tracer.To        = screen
        tracer.Color     = Color3.fromRGB(150,220,255)
        tracer.Thickness = 1
        tracer.Visible   = true

        podDrawings[tostring(pod)] = {label=lbl, tracer=tracer}
        ::podNext::
    end
end)

-- ── ESP de Saídas ──────────────────────────────────────────────
local exitDrawings = {}

local function findExits()
    local exits = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name:lower():find("exit")
        or obj.Name:lower():find("door")
        or obj.Name:lower():find("escape") then
            if obj:IsA("BasePart") or obj:IsA("Model") then
                table.insert(exits, obj)
            end
        end
    end
    return exits
end

RunService.RenderStepped:Connect(function()
    for key, d in pairs(exitDrawings) do
        pcall(function() d.label:Remove() end)
        pcall(function() d.tracer:Remove() end)
        exitDrawings[key] = nil
    end

    if not cfg.ExitESP then return end

    for _, exit in ipairs(findExits()) do
        local pos = exit:IsA("Model")
            and exit:GetModelCFrame().Position
            or  exit.Position

        local screen, onScreen, depth = worldToScreen(pos)
        if not onScreen or depth < 0 then goto exitNext end

        local lbl    = Drawing.new("Text")
        local tracer = Drawing.new("Line")

        lbl.Text     = "🚪 EXIT " .. math.floor(depth) .. "m"
        lbl.Position = screen
        lbl.Size     = 13
        lbl.Color    = Color3.fromRGB(255, 220, 50)
        lbl.Outline  = true
        lbl.Center   = true
        lbl.Visible  = true

        tracer.From      = Vector2.new(
            Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
        tracer.To        = screen
        tracer.Color     = Color3.fromRGB(255,220,50)
        tracer.Thickness = 1
        tracer.Visible   = true

        exitDrawings[tostring(exit)] = {label=lbl, tracer=tracer}
        ::exitNext::
    end
end)

-- ── Beast Alert ────────────────────────────────────────────────
local alertLabel = Drawing.new("Text")
alertLabel.Size    = 20
alertLabel.Color   = Color3.fromRGB(255, 50, 50)
alertLabel.Outline = true
alertLabel.Center  = true
alertLabel.Visible = false

RunService.RenderStepped:Connect(function()
    if not cfg.BeastAlert then
        alertLabel.Visible = false
        return
    end
    local beastClose = false
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and isBeast(p) and isAlive(p) then
            local r = p.Character
                and p.Character:FindFirstChild("HumanoidRootPart")
            local myR = getRootPart()
            if r and myR then
                local d = (r.Position - myR.Position).Magnitude
                if d <= cfg.BeastAlertDist then
                    beastClose = true
                end
            end
        end
    end
    alertLabel.Visible  = beastClose
    alertLabel.Text     = "⚠ BEAST PRÓXIMO ⚠"
    alertLabel.Position = Vector2.new(
        Camera.ViewportSize.X / 2, 50)
end)

-- ════════════════════════════════════════════════════════════════
--  SURVIVOR
-- ════════════════════════════════════════════════════════════════

-- Speed + Lock
RunService.Heartbeat:Connect(function()
    local hum = getHumanoid()
    if not hum then return end
    if cfg.Speed or cfg.WalkspeedLock then
        hum.WalkSpeed = cfg.SpeedVal
    end
end)

-- Infinite Jump
UserInput.JumpRequest:Connect(function()
    if not cfg.InfJump then return end
    local hum = getHumanoid()
    if hum then hum:ChangeState(
        Enum.HumanoidStateType.Jumping) end
end)

-- BunnyHop
RunService.Heartbeat:Connect(function()
    if not cfg.BunnyHop then return end
    local hum = getHumanoid()
    if hum and hum.FloorMaterial ~= Enum.Material.Air then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Fly
local flyConn
local function startFly()
    local char = getChar()
    if not char then return end
    local root = getRootPart()
    if not root then return end
    local bp = Instance.new("BodyVelocity")
    bp.Velocity        = Vector3.zero
    bp.MaxForce        = Vector3.new(1e5,1e5,1e5)
    bp.Parent          = root
    local bg = Instance.new("BodyGyro")
    bg.MaxTorque       = Vector3.new(1e5,1e5,1e5)
    bg.CFrame          = root.CFrame
    bg.Parent          = root
    flyConn = RunService.Heartbeat:Connect(function()
        if not cfg.Fly then
            bp:Destroy(); bg:Destroy()
            if flyConn then flyConn:Disconnect() end
            return
        end
        local dir = Vector3.zero
        local cf  = Camera.CFrame
        if UserInput:IsKeyDown(Enum.KeyCode.W) then
            dir = dir + cf.LookVector end
        if UserInput:IsKeyDown(Enum.KeyCode.S) then
            dir = dir - cf.LookVector end
        if UserInput:IsKeyDown(Enum.KeyCode.A) then
            dir = dir - cf.RightVector end
        if UserInput:IsKeyDown(Enum.KeyCode.D) then
            dir = dir + cf.RightVector end
        if UserInput:IsKeyDown(Enum.KeyCode.Space) then
            dir = dir + Vector3.new(0,1,0) end
        if UserInput:IsKeyDown(Enum.KeyCode.LeftControl) then
            dir = dir - Vector3.new(0,1,0) end
        bp.Velocity = dir * cfg.SpeedVal
        bg.CFrame   = cf
    end)
end

-- NoClip
RunService.Stepped:Connect(function()
    if not cfg.NoClip then return end
    local char = getChar()
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanCollide = false
        end
    end
end)

-- No Crawl
RunService.Heartbeat:Connect(function()
    if not cfg.NoCrawl then return end
    local hum = getHumanoid()
    if hum and hum:GetState() ==
    Enum.HumanoidStateType.Physics then
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end
end)

-- Inf Stamina
RunService.Heartbeat:Connect(function()
    if not cfg.InfStamina then return end
    local char = getChar()
    if not char then return end
    local stamina = char:FindFirstChild("Stamina")
        or char:FindFirstChild("StaminaValue")
    if stamina and stamina:IsA("NumberValue") then
        stamina.Value = stamina.Value > 0
            and stamina.Value or 100
    end
end)

-- Anti Freeze
RunService.Heartbeat:Connect(function()
    if not cfg.AntiFreeze then return end
    local char = getChar()
    if not char then return end
    local frozen = char:FindFirstChild("Frozen")
        or char:FindFirstChild("IsFrozen")
    if frozen then frozen:Destroy() end
end)

-- No Fail Hack / Instant Hack
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args   = {...}

    if cfg.NoFailHack and method == "FireServer" then
        -- intercepta evento de falha no minigame
        local name = tostring(self)
        if name:lower():find("fail") or name:lower():find("error") then
            return
        end
    end

    if cfg.InstantHack and method == "FireServer" then
        local name = tostring(self)
        if name:lower():find("hack") or name:lower():find("computer") then
            -- força sucesso imediato
            args[1] = true
        end
    end

    return oldNamecall(self, table.unpack(args))
end)

-- Auto Hack
RunService.Heartbeat:Connect(function()
    if not cfg.AutoHack then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name:lower():find("computer")
        or obj.Name:lower():find("terminal") then
            local root = getRootPart()
            local part = obj:IsA("Model")
                and obj:FindFirstChildOfClass("BasePart")
                or  (obj:IsA("BasePart") and obj or nil)
            if part and root then
                local dist = (part.Position - root.Position).Magnitude
                if dist < 10 then
                    -- tenta interagir via ProximityPrompt
                    local pp = obj:FindFirstChildOfClass("ProximityPrompt")
                        or part:FindFirstChildOfClass("ProximityPrompt")
                    if pp then
                        fireproximityprompt(pp)
                    end
                end
            end
        end
    end
end)

-- Auto Free survivors congelados
RunService.Heartbeat:Connect(function()
    if not cfg.AutoFree then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and isFrozen(p) then
            local c = p.Character
            local root = getRootPart()
            if c and root then
                local fr = c:FindFirstChild("HumanoidRootPart")
                if fr then
                    local dist = (fr.Position - root.Position).Magnitude
                    if dist < 10 then
                        local pp = c:FindFirstChildOfClass("ProximityPrompt")
                        if pp then fireproximityprompt(pp) end
                    else
                        -- teleporta perto
                        root.CFrame = CFrame.new(
                            fr.Position + Vector3.new(2,0,2))
                    end
                end
            end
        end
    end
end)

-- Auto Dodge
RunService.Heartbeat:Connect(function()
    if not cfg.AutoDodge then return end
    local root = getRootPart()
    if not root then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and isBeast(p) and isAlive(p) then
            local br = p.Character
                and p.Character:FindFirstChild("HumanoidRootPart")
            if br then
                local dist = (br.Position - root.Position).Magnitude
                if dist < cfg.AutoDodgeDist then
                    -- foge na direção oposta
                    local away = (root.Position - br.Position).Unit
                    root.CFrame = root.CFrame
                        + away * 15
                end
            end
        end
    end
end)

-- Computer Finder
local function teleportToNearestComp()
    local root = getRootPart()
    if not root then return end
    local nearest, dist = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name:lower():find("computer")
        or obj.Name:lower():find("terminal") then
            local part = obj:IsA("Model")
                and obj:FindFirstChildOfClass("BasePart")
                or  (obj:IsA("BasePart") and obj or nil)
            if part then
                local d = (part.Position - root.Position).Magnitude
                if d < dist then dist = d; nearest = part end
            end
        end
    end
    if nearest then
        root.CFrame = CFrame.new(
            nearest.Position + Vector3.new(0,3,3))
    end
end

-- Pod Finder
local function teleportToNearestPod()
    local root = getRootPart()
    if not root then return end
    local nearest, dist = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name:lower():find("pod")
        or obj.Name:lower():find("freeze") then
            local part = obj:IsA("Model")
                and obj:FindFirstChildOfClass("BasePart")
                or  (obj:IsA("BasePart") and obj or nil)
            if part then
                local d = (part.Position - root.Position).Magnitude
                if d < dist then dist = d; nearest = part end
            end
        end
    end
    if nearest then
        root.CFrame = CFrame.new(
            nearest.Position + Vector3.new(0,3,3))
    end
end

-- Exit Finder
local function teleportToExit()
    local root = getRootPart()
    if not root then return end
    local nearest, dist = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name:lower():find("exit")
        or obj.Name:lower():find("door") then
            local part = obj:IsA("Model")
                and obj:FindFirstChildOfClass("BasePart")
                or  (obj:IsA("BasePart") and obj or nil)
            if part then
                local d = (part.Position - root.Position).Magnitude
                if d < dist then dist = d; nearest = part end
            end
        end
    end
    if nearest then
        root.CFrame = CFrame.new(
            nearest.Position + Vector3.new(0,3,3))
    end
end

-- ════════════════════════════════════════════════════════════════
--  BEAST
-- ════════════════════════════════════════════════════════════════

-- Beast Speed
RunService.Heartbeat:Connect(function()
    if not cfg.BeastSpeed then return end
    if not isBeast(LocalPlayer) then return end
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = cfg.BeastSpeedVal end
end)

-- Beast Auto Freeze / Teleport to Survivor
RunService.Heartbeat:Connect(function()
    if not isBeast(LocalPlayer) then return end
    local root = getRootPart()
    if not root then return end

    local nearest, dist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and isAlive(p) and not isBeast(p) then
            local r = p.Character
                and p.Character:FindFirstChild("HumanoidRootPart")
            if r then
                local d = (r.Position - root.Position).Magnitude
                if d < dist then dist = d; nearest = {p=p, r=r} end
            end
        end
    end

    if nearest then
        if cfg.BeastTeleport then
            root.CFrame = CFrame.new(
                nearest.r.Position + Vector3.new(0,3,2))
        end
        if cfg.BeastAutoFreeze and dist < 8 then
            -- tenta acertar via click/touch
            local tool = getChar()
                and getChar():FindFirstChildOfClass("Tool")
            if tool then
                local pp = tool:FindFirstChildOfClass("ProximityPrompt")
                    or nearest.p.Character
                        :FindFirstChildOfClass("ProximityPrompt")
                if pp then fireproximityprompt(pp) end
            end
        end
        if cfg.BeastFreezeAll then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and isAlive(p) and not isBeast(p) then
                    local r2 = p.Character
                        and p.Character:FindFirstChild("HumanoidRootPart")
                    if r2 then
                        root.CFrame = CFrame.new(
                            r2.Position + Vector3.new(0,3,2))
                    end
                end
            end
        end
    end
end)

-- Beast Fling
local function flingTarget(target)
    local r = target.Character
        and target.Character:FindFirstChild("HumanoidRootPart")
    if not r then return end
    local bv = Instance.new("BodyVelocity")
    bv.Velocity  = Vector3.new(
        math.random(-200,200), 300, math.random(-200,200))
    bv.MaxForce  = Vector3.new(1e6,1e6,1e6)
    bv.Parent    = r
    game:GetService("Debris"):AddItem(bv, 0.2)
end

-- ════════════════════════════════════════════════════════════════
--  MISC
-- ════════════════════════════════════════════════════════════════

-- Anti-AFK
task.spawn(function()
    while true do
        task.wait(55)
        if cfg.AntiAFK then
            local vu = game:GetService("VirtualUser")
            vu:Button2Down(Vector2.zero, Camera.CFrame)
            task.wait(0.1)
            vu:Button2Up(Vector2.zero, Camera.CFrame)
        end
    end
end)

-- Chat Spammer
task.spawn(function()
    while true do
        task.wait(cfg.ChatDelay)
        if cfg.ChatSpammer then
            pcall(function()
                game:GetService("ReplicatedStorage")
                    :WaitForChild("DefaultChatSystemChatEvents")
                    :WaitForChild("SayMessageRequest")
                    :FireServer(cfg.ChatMsg, "All")
            end)
        end
    end
end)

-- Stats HUD
local stats = {hacks=0, frees=0, frozen=0, escaped=0}
local statsLbl = Drawing.new("Text")
statsLbl.Size    = 13
statsLbl.Color   = Color3.fromRGB(255,255,255)
statsLbl.Outline = true
statsLbl.Center  = false
statsLbl.Visible = false

RunService.RenderStepped:Connect(function()
    statsLbl.Visible  = cfg.StatsHUD
    statsLbl.Text     = string.format(
        "Hacks: %d | Freed: %d | Frozen: %d | Escaped: %d",
        stats.hacks, stats.frees, stats.frozen, stats.escaped)
    statsLbl.Position = Vector2.new(10, 10)
end)

-- Flashlight
local flashPart
local function toggleFlashlight(on)
    local char = getChar()
    if not char then return end
    if on then
        if flashPart then return end
        local root = getRootPart()
        if not root then return end
        flashPart = Instance.new("Part")
        flashPart.Size        = Vector3.new(0.1,0.1,0.1)
        flashPart.CanCollide  = false
        flashPart.Anchored    = false
        flashPart.Transparency = 1
        local light = Instance.new("SpotLight")
        light.Range      = 60
        light.Brightness = 5
        light.Angle      = 70
        light.Parent     = flashPart
        local weld = Instance.new("WeldConstraint")
        weld.Part0   = root
        weld.Part1   = flashPart
        weld.Parent  = flashPart
        flashPart.Parent = char
    else
        if flashPart then
            flashPart:Destroy()
            flashPart = nil
        end
    end
end

-- Rejoin
local function rejoin()
    game:GetService("TeleportService")
        :Teleport(game.PlaceId, LocalPlayer)
end

-- Server Hop
local function serverHop()
    local servers = game:GetService("HttpService")
    -- lista servidores via API Roblox
    -- FILL: requer HttpService habilitado no executor
    rejoin() -- fallback simples
end

-- ════════════════════════════════════════════════════════════════
--  RAYFIELD UI
-- ════════════════════════════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name            = "olliE | Flee The Facility",
    LoadingTitle    = "olliE carregando...",
    LoadingSubtitle = "absolute olliE",
    ConfigurationSaving = {
        Enabled  = true,
        FileName = "OllieFTF"
    },
    KeySystem = false,
})

-- ── ABA: ESP ──────────────────────────────────────────────────
local TabESP = Window:CreateTab("ESP", "eye")

TabESP:CreateToggle({ Name = "Survivor ESP",
    CurrentValue = cfg.SurvivorESP, Flag = "SurvivorESP",
    Callback = function(v) cfg.SurvivorESP = v end })

TabESP:CreateToggle({ Name = "Beast ESP",
    CurrentValue = cfg.BeastESP, Flag = "BeastESP",
    Callback = function(v) cfg.BeastESP = v end })

TabESP:CreateToggle({ Name = "Computer ESP",
    CurrentValue = cfg.ComputerESP, Flag = "ComputerESP",
    Callback = function(v) cfg.ComputerESP = v end })

TabESP:CreateToggle({ Name = "Computer Status %",
    CurrentValue = cfg.ComputerStatus, Flag = "ComputerStatus",
    Callback = function(v) cfg.ComputerStatus = v end })

TabESP:CreateToggle({ Name = "Freeze Pod ESP",
    CurrentValue = cfg.PodESP, Flag = "PodESP",
    Callback = function(v) cfg.PodESP = v end })

TabESP:CreateToggle({ Name = "Exit Door ESP",
    CurrentValue = cfg.ExitESP, Flag = "ExitESP",
    Callback = function(v) cfg.ExitESP = v end })

TabESP:CreateToggle({ Name = "Chams (Parede)",
    CurrentValue = cfg.Chams, Flag = "Chams",
    Callback = function(v) cfg.Chams = v end })

TabESP:CreateToggle({ Name = "Tracers",
    CurrentValue = cfg.Tracers, Flag = "Tracers",
    Callback = function(v) cfg.Tracers = v end })

TabESP:CreateToggle({ Name = "Skeleton ESP",
    CurrentValue = cfg.SkeletonESP, Flag = "SkeletonESP",
    Callback = function(v) cfg.SkeletonESP = v end })

TabESP:CreateToggle({ Name = "Nametags",
    CurrentValue = cfg.NametagESP, Flag = "NametagESP",
    Callback = function(v) cfg.NametagESP = v end })

TabESP:CreateToggle({ Name = "Distância",
    CurrentValue = cfg.DistanceESP, Flag = "DistanceESP",
    Callback = function(v) cfg.DistanceESP = v end })

TabESP:CreateToggle({ Name = "Status (Frozen/Hacking)",
    CurrentValue = cfg.StatusESP, Flag = "StatusESP",
    Callback = function(v) cfg.StatusESP = v end })

TabESP:CreateToggle({ Name = "Beast Alert",
    CurrentValue = cfg.BeastAlert, Flag = "BeastAlert",
    Callback = function(v) cfg.BeastAlert = v end })

TabESP:CreateSlider({ Name = "Distância do Alert",
    Range = {10,150}, Increment = 5,
    CurrentValue = cfg.BeastAlertDist, Flag = "BeastAlertDist",
    Callback = function(v) cfg.BeastAlertDist = v end })

-- ── ABA: SURVIVOR ─────────────────────────────────────────────
local TabSurv = Window:CreateTab("Survivor", "user")

TabSurv:CreateToggle({ Name = "Speed",
    CurrentValue = cfg.Speed, Flag = "Speed",
    Callback = function(v) cfg.Speed = v end })

TabSurv:CreateSlider({ Name = "Velocidade",
    Range = {16,120}, Increment = 2,
    CurrentValue = cfg.SpeedVal, Flag = "SpeedVal",
    Callback = function(v) cfg.SpeedVal = v end })

TabSurv:CreateToggle({ Name = "Walkspeed Lock",
    CurrentValue = cfg.WalkspeedLock, Flag = "WalkspeedLock",
    Callback = function(v) cfg.WalkspeedLock = v end })

TabSurv:CreateToggle({ Name = "Infinite Jump",
    CurrentValue = cfg.InfJump, Flag = "InfJump",
    Callback = function(v) cfg.InfJump = v end })

TabSurv:CreateToggle({ Name = "Bunny Hop",
    CurrentValue = cfg.BunnyHop, Flag = "BunnyHop",
    Callback = function(v) cfg.BunnyHop = v end })

TabSurv:CreateToggle({ Name = "Fly",
    CurrentValue = cfg.Fly, Flag = "Fly",
    Callback = function(v)
        cfg.Fly = v
        if v then startFly() end
    end })

TabSurv:CreateToggle({ Name = "NoClip",
    CurrentValue = cfg.NoClip, Flag = "NoClip",
    Callback = function(v) cfg.NoClip = v end })

TabSurv:CreateToggle({ Name = "No Crawl",
    CurrentValue = cfg.NoCrawl, Flag = "NoCrawl",
    Callback = function(v) cfg.NoCrawl = v end })

TabSurv:CreateToggle({ Name = "Inf Stamina",
    CurrentValue = cfg.InfStamina, Flag = "InfStamina",
    Callback = function(v) cfg.InfStamina = v end })

TabSurv:CreateToggle({ Name = "Anti Freeze",
    CurrentValue = cfg.AntiFreeze, Flag = "AntiFreeze",
    Callback = function(v) cfg.AntiFreeze = v end })

TabSurv:CreateToggle({ Name = "No Fail Hack",
    CurrentValue = cfg.NoFailHack, Flag = "NoFailHack",
    Callback = function(v) cfg.NoFailHack = v end })

TabSurv:CreateToggle({ Name = "Instant Hack",
    CurrentValue = cfg.InstantHack, Flag = "InstantHack",
    Callback = function(v) cfg.InstantHack = v end })

TabSurv:CreateToggle({ Name = "Auto Hack",
    CurrentValue = cfg.AutoHack, Flag = "AutoHack",
    Callback = function(v) cfg.AutoHack = v end })

TabSurv:CreateToggle({ Name = "Auto Free Survivors",
    CurrentValue = cfg.AutoFree, Flag = "AutoFree",
    Callback = function(v) cfg.AutoFree = v end })

TabSurv:CreateToggle({ Name = "Auto Dodge Beast",
    CurrentValue = cfg.AutoDodge, Flag = "AutoDodge",
    Callback = function(v) cfg.AutoDodge = v end })

TabSurv:CreateSlider({ Name = "Dodge Distance",
    Range = {10,100}, Increment = 5,
    CurrentValue = cfg.AutoDodgeDist, Flag = "AutoDodgeDist",
    Callback = function(v) cfg.AutoDodgeDist = v end })

TabSurv:CreateButton({ Name = "Teleport → Computer",
    Callback = teleportToNearestComp })

TabSurv:CreateButton({ Name = "Teleport → Pod",
    Callback = teleportToNearestPod })

TabSurv:CreateButton({ Name = "Teleport → Exit",
    Callback = teleportToExit })

-- ── ABA: BEAST ────────────────────────────────────────────────
local TabBeast = Window:CreateTab("Beast", "skull")

TabBeast:CreateToggle({ Name = "Beast Speed",
    CurrentValue = cfg.BeastSpeed, Flag = "BeastSpeed",
    Callback = function(v) cfg.BeastSpeed = v end })

TabBeast:CreateSlider({ Name = "Velocidade Beast",
    Range = {16,120}, Increment = 2,
    CurrentValue = cfg.BeastSpeedVal, Flag = "BeastSpeedVal",
    Callback = function(v) cfg.BeastSpeedVal = v end })

TabBeast:CreateToggle({ Name = "Teleport to Survivor",
    CurrentValue = cfg.BeastTeleport, Flag = "BeastTeleport",
    Callback = function(v) cfg.BeastTeleport = v end })

TabBeast:CreateToggle({ Name = "Auto Freeze",
    CurrentValue = cfg.BeastAutoFreeze, Flag = "BeastAutoFreeze",
    Callback = function(v) cfg.BeastAutoFreeze = v end })

TabBeast:CreateToggle({ Name = "Freeze All",
    CurrentValue = cfg.BeastFreezeAll, Flag = "BeastFreezeAll",
    Callback = function(v) cfg.BeastFreezeAll = v end })

TabBeast:CreateButton({ Name = "Fling Survivor Mais Perto",
    Callback = function()
        local root = getRootPart()
        if not root then return end
        local nearest, dist = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and isAlive(p) and not isBeast(p) then
                local r = p.Character
                    and p.Character:FindFirstChild("HumanoidRootPart")
                if r then
                    local d = (r.Position - root.Position).Magnitude
                    if d < dist then dist = d; nearest = p end
                end
            end
        end
        if nearest then flingTarget(nearest) end
    end })

-- ── ABA: MISC ─────────────────────────────────────────────────
local TabMisc = Window:CreateTab("Misc", "settings")

TabMisc:CreateToggle({ Name = "Anti-AFK",
    CurrentValue = cfg.AntiAFK, Flag = "AntiAFK",
    Callback = function(v) cfg.AntiAFK = v end })

TabMisc:CreateToggle({ Name = "Stats HUD",
    CurrentValue = cfg.StatsHUD, Flag = "StatsHUD",
    Callback = function(v) cfg.StatsHUD = v end })

TabMisc:CreateToggle({ Name = "Flashlight",
    CurrentValue = cfg.Flashlight, Flag = "Flashlight",
    Callback = function(v)
        cfg.Flashlight = v
        toggleFlashlight(v)
    end })

TabMisc:CreateToggle({ Name = "Chat Spammer",
    CurrentValue = cfg.ChatSpammer, Flag = "ChatSpammer",
    Callback = function(v) cfg.ChatSpammer = v end })

TabMisc:CreateInput({ Name = "Mensagem Spammer",
    CurrentValue = cfg.ChatMsg,
    PlaceholderText = "mensagem aqui",
    RemoveTextAfterFocusLost = false, Flag = "ChatMsg",
    Callback = function(v) cfg.ChatMsg = v end })

TabMisc:CreateSlider({ Name = "Delay Spammer (s)",
    Range = {1,30}, Increment = 1,
    CurrentValue = cfg.ChatDelay, Flag = "ChatDelay",
    Callback = function(v) cfg.ChatDelay = v end })

TabMisc:CreateButton({ Name = "Rejoin",
    Callback = rejoin })

TabMisc:CreateButton({ Name = "Server Hop",
    Callback = serverHop })

-- ── Notificação ────────────────────────────────────────────────
Rayfield:Notify({
    Title    = "olliE | Flee The Facility",
    Content  = "tudo carregado, absolute olliE to Sam",
    Duration = 4,
})
