-- Lang: Lua | Executor: Delta/Synapse/Fluxus | UI: Rayfield
-- Dep: Rayfield via sirius.menu/rayfield
-- Jogo: Flee The Facility | PlaceId: 893973440
-- Uso: loadstring(game:HttpGet("SEU_RAW_LINK"))()

-- ── Proteção de injeção dupla ──────────────────────────────────
if getgenv().OllieFTF_Loaded then
    print("[olliE] já carregado, pulando")
    return
end
getgenv().OllieFTF_Loaded = true

-- ── Carrega Rayfield ───────────────────────────────────────────
local ok, Rayfield = pcall(function()
    return loadstring(game:HttpGet(
        "https://sirius.menu/rayfield", true))()
end)

if not ok or not Rayfield then
    -- fallback: tenta raw github do Rayfield
    ok, Rayfield = pcall(function()
        return loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/SiriusHubOfficial/Rayfield/main/source.lua", true))()
    end)
end

if not ok or not Rayfield then
    warn("[olliE] Rayfield falhou — verifica conexão ou executor")
    return
end

-- ── Serviços ───────────────────────────────────────────────────
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInput      = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local Debris         = game:GetService("Debris")
local VirtualUser    = game:GetService("VirtualUser")
local TeleportSvc    = game:GetService("TeleportService")
local ReplicatedSto  = game:GetService("ReplicatedStorage")
local Camera         = workspace.CurrentCamera
local LocalPlayer    = Players.LocalPlayer

-- ── Config global ──────────────────────────────────────────────
local cfg = getgenv().OllieFTF_CFG or {
    -- ESP Jogadores
    SurvivorESP      = false,
    BeastESP         = false,
    ESPBox           = true,
    ESPName          = true,
    ESPDist          = true,
    ESPStatus        = true,
    ESPHealth        = true,
    ESPWeapon        = false,
    SkeletonESP      = false,
    Chams            = false,
    Tracers          = false,

    -- ESP Objetos
    ComputerESP      = false,
    ComputerStatus   = false,
    PodESP           = false,
    ExitESP          = false,

    -- Alerts
    BeastAlert       = false,
    BeastAlertDist   = 50,

    -- Survivor
    Speed            = false,
    SpeedVal         = 32,
    WalkLock         = false,
    InfJump          = false,
    BunnyHop         = false,
    Fly              = false,
    FlySpeed         = 32,
    NoClip           = false,
    NoCrawl          = false,
    InfStamina       = false,
    AntiFreeze       = false,
    NoFailHack       = false,
    InstantHack      = false,
    AutoHack         = false,
    AutoFree         = false,
    AutoEscape       = false,
    AutoDodge        = false,
    AutoDodgeDist    = 40,
    FakeLag          = false,
    FakeLagVal       = 200,
    GhostMode        = false,

    -- Beast
    BeastSpeed       = false,
    BeastSpeedVal    = 40,
    BeastTeleport    = false,
    BeastAutoFreeze  = false,
    BeastFreezeAll   = false,
    BeastNoCD        = false,
    BeastFling       = false,
    BeastKillAura    = false,
    BeastAuraRange   = 20,

    -- Misc
    AntiAFK          = false,
    StatsHUD         = false,
    Flashlight       = false,
    ChatSpammer      = false,
    ChatMsg          = "olliE ftf ez frfr",
    ChatDelay        = 5,
    ServerHop        = false,
    AutoVote         = false,
    TrollMode        = false,
    Minimap          = false,
    CrosshairCustom  = false,
    CrosshairCol     = Color3.fromRGB(255, 50, 50),
}
getgenv().OllieFTF_CFG = cfg

-- ════════════════════════════════════════════════════════════════
-- UTIL
-- ════════════════════════════════════════════════════════════════
local function getChar()
    return LocalPlayer.Character
end

local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function isAlive(p)
    local c = p.Character
    if not c then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function isBeast(p)
    local c = p.Character
    if not c then return false end
    if p.Team and tostring(p.Team.Name):lower():find("beast") then
        return true
    end
    for _, name in ipairs({"IsBeast","Beast","BeastTag"}) do
        if c:FindFirstChild(name) then return true end
    end
    -- checa se tem tag de Beast no valor do personagem
    local val = c:FindFirstChild("PlayerType")
        or c:FindFirstChild("Role")
    if val and tostring(val.Value):lower():find("beast") then
        return true
    end
    return false
end

local function isFrozen(p)
    local c = p.Character
    if not c then return false end
    for _, n in ipairs({"Frozen","IsFrozen","Freeze","Crystalized"}) do
        if c:FindFirstChild(n) then return true end
    end
    return false
end

local function isHacking(p)
    local c = p.Character
    if not c then return false end
    for _, n in ipairs({"Hacking","IsHacking","UsingComputer"}) do
        if c:FindFirstChild(n) then return true end
    end
    return false
end

local function toScreen(pos)
    local sp, vis = Camera:WorldToViewportPoint(pos)
    return Vector2.new(sp.X, sp.Y), vis, sp.Z
end

local function distTo(pos)
    local r = getRoot()
    if not r then return 9999 end
    return math.floor((r.Position - pos).Magnitude)
end

local function getPlayers(excludeSelf, beastOnly, survivorOnly)
    local out = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if excludeSelf and p == LocalPlayer then goto skip end
        if beastOnly and not isBeast(p) then goto skip end
        if survivorOnly and isBeast(p) then goto skip end
        if not isAlive(p) then goto skip end
        table.insert(out, p)
        ::skip::
    end
    return out
end

local function findNearest(list, getPos)
    local r = getRoot()
    if not r then return nil end
    local best, bestD = nil, math.huge
    for _, v in ipairs(list) do
        local pos = getPos(v)
        if pos then
            local d = (r.Position - pos).Magnitude
            if d < bestD then bestD = d; best = v end
        end
    end
    return best
end

local function getPartPos(obj)
    if not obj then return nil end
    if obj:IsA("Model") then
        local p = obj.PrimaryPart
            or obj:FindFirstChildOfClass("BasePart")
        return p and p.Position or nil
    elseif obj:IsA("BasePart") then
        return obj.Position
    end
    return nil
end

local function scanWorkspace(keywords)
    local out = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local n = obj.Name:lower()
            for _, kw in ipairs(keywords) do
                if n:find(kw) then
                    table.insert(out, obj)
                    break
                end
            end
        end
    end
    return out
end

-- ════════════════════════════════════════════════════════════════
-- DRAWING HELPERS
-- ════════════════════════════════════════════════════════════════
local allDrawings = {}

local function newText(size, color)
    local t = Drawing.new("Text")
    t.Size    = size or 13
    t.Color   = color or Color3.fromRGB(255,255,255)
    t.Outline = true
    t.Center  = true
    t.Visible = false
    table.insert(allDrawings, t)
    return t
end

local function newLine(color, thick)
    local l = Drawing.new("Line")
    l.Color     = color or Color3.fromRGB(255,255,255)
    l.Thickness = thick or 1
    l.Visible   = false
    table.insert(allDrawings, l)
    return l
end

local function newBox(color, thick)
    local b = Drawing.new("Square")
    b.Color     = color or Color3.fromRGB(255,255,255)
    b.Thickness = thick or 1.5
    b.Filled    = false
    b.Visible   = false
    table.insert(allDrawings, b)
    return b
end

local function newCircle(color, thick)
    local c = Drawing.new("Circle")
    c.Color     = color or Color3.fromRGB(255,255,255)
    c.Thickness = thick or 1
    c.NumSides  = 32
    c.Filled    = false
    c.Visible   = false
    table.insert(allDrawings, c)
    return c
end

-- ════════════════════════════════════════════════════════════════
-- ESP JOGADORES
-- ════════════════════════════════════════════════════════════════
local BONE_PAIRS = {
    {"Head","UpperTorso"},
    {"UpperTorso","LowerTorso"},
    {"LowerTorso","LeftUpperLeg"},
    {"LowerTorso","RightUpperLeg"},
    {"LeftUpperLeg","LeftLowerLeg"},
    {"RightUpperLeg","RightLowerLeg"},
    {"UpperTorso","LeftUpperArm"},
    {"UpperTorso","RightUpperArm"},
    {"LeftUpperArm","LeftLowerArm"},
    {"RightUpperArm","RightLowerArm"},
}

local playerESP  = {}
local highlights = {}

local function removeHighlight(p)
    if highlights[p] then
        pcall(function() highlights[p]:Destroy() end)
        highlights[p] = nil
    end
end

local function applyHighlight(p, fill, outline)
    removeHighlight(p)
    if not p.Character then return end
    local h = Instance.new("Highlight")
    h.FillColor           = fill
    h.OutlineColor        = outline
    h.FillTransparency    = 0.45
    h.OutlineTransparency = 0
    h.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent              = p.Character
    highlights[p]         = h
end

local function buildPlayerESP(p)
    if p == LocalPlayer then return end
    if playerESP[p] then return end

    local beast   = isBeast(p)
    local col     = beast
        and Color3.fromRGB(230, 40, 40)
        or  Color3.fromRGB(40, 230, 90)

    local d = {
        box    = newBox(col, 1.5),
        hpBG   = newBox(Color3.fromRGB(50,50,50), 1),
        hpBar  = newBox(Color3.fromRGB(50,255,50), 1),
        name   = newText(13, col),
        dist   = newText(11, Color3.fromRGB(200,200,200)),
        status = newText(11, Color3.fromRGB(255,220,50)),
        tracer = newLine(col, 1),
        bones  = {},
    }
    d.hpBG.Filled  = true
    d.hpBar.Filled = true

    for i = 1, #BONE_PAIRS do
        table.insert(d.bones, newLine(col, 1))
    end

    playerESP[p] = d
end

local function removePlayerESP(p)
    if playerESP[p] then
        local d = playerESP[p]
        for _, v in pairs(d) do
            if type(v) == "table" then
                for _, b in pairs(v) do
                    pcall(function() b:Remove() end)
                end
            else
                pcall(function() v:Remove() end)
            end
        end
        playerESP[p] = nil
    end
    removeHighlight(p)
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(1)
        buildPlayerESP(p)
    end)
    buildPlayerESP(p)
end)

Players.PlayerRemoving:Connect(removePlayerESP)

for _, p in ipairs(Players:GetPlayers()) do
    buildPlayerESP(p)
    p.CharacterAdded:Connect(function()
        task.wait(1)
        removePlayerESP(p)
        buildPlayerESP(p)
    end)
end

-- ── ESP tick ──────────────────────────────────────────────────
RunService.RenderStepped:Connect(function()
    local cv = Camera.ViewportSize
    local cx, cy = cv.X/2, cv.Y

    for p, d in pairs(playerESP) do
        local beast   = isBeast(p)
        local enabled = beast and cfg.BeastESP or cfg.SurvivorESP

        local function hide()
            d.box.Visible    = false
            d.hpBG.Visible   = false
            d.hpBar.Visible  = false
            d.name.Visible   = false
            d.dist.Visible   = false
            d.status.Visible = false
            d.tracer.Visible = false
            for _, b in ipairs(d.bones) do b.Visible = false end
            removeHighlight(p)
        end

        if not enabled then hide() ; continue end

        local char = p.Character
        if not char or not isAlive(p) then hide() ; continue end

        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        if not root or not head then hide() ; continue end

        local rs, onS, depth = toScreen(root.Position)
        local hs             = toScreen(head.Position)
        if not onS or depth < 0 then hide() ; continue end

        local col = beast
            and Color3.fromRGB(230,40,40)
            or  Color3.fromRGB(40,230,90)

        local h = (hs - rs).Magnitude * 2
        local w = h * 0.55

        -- Box
        if cfg.ESPBox then
            d.box.Visible  = true
            d.box.Color    = col
            d.box.Size     = Vector2.new(w, h)
            d.box.Position = Vector2.new(rs.X - w/2, rs.Y - h)
        else
            d.box.Visible = false
        end

        -- HP Bar
        if cfg.ESPHealth then
            local hum = char:FindFirstChildOfClass("Humanoid")
            local pct = hum and (hum.Health/hum.MaxHealth) or 0
            local barH = h * pct
            local barX = rs.X - w/2 - 6

            d.hpBG.Visible   = true
            d.hpBG.Size      = Vector2.new(4, h)
            d.hpBG.Position  = Vector2.new(barX, rs.Y - h)

            d.hpBar.Visible  = true
            d.hpBar.Size     = Vector2.new(4, barH)
            d.hpBar.Position = Vector2.new(barX, rs.Y - barH)
            d.hpBar.Color    = Color3.fromRGB(
                math.floor(255*(1-pct)),
                math.floor(255*pct), 0)
        else
            d.hpBG.Visible  = false
            d.hpBar.Visible = false
        end

        -- Nome
        if cfg.ESPName then
            local prefix = beast and "[BEAST] " or ""
            d.name.Visible  = true
            d.name.Color    = col
            d.name.Text     = prefix .. p.DisplayName
            d.name.Position = Vector2.new(rs.X, rs.Y - h - 14)
        else
            d.name.Visible = false
        end

        -- Distância
        if cfg.ESPDist then
            d.dist.Visible  = true
            d.dist.Text     = distTo(root.Position) .. "m"
            d.dist.Position = Vector2.new(rs.X, rs.Y + 3)
        else
            d.dist.Visible = false
        end

        -- Status
        if cfg.ESPStatus then
            local s = isFrozen(p) and "FROZEN"
                or isHacking(p) and "HACKING"
                or "FREE"
            local sc = isFrozen(p)
                and Color3.fromRGB(100,200,255)
                or isHacking(p)
                and Color3.fromRGB(255,220,50)
                or  Color3.fromRGB(200,200,200)
            d.status.Visible  = true
            d.status.Color    = sc
            d.status.Text     = s
            d.status.Position = Vector2.new(rs.X, rs.Y + 15)
        else
            d.status.Visible = false
        end

        -- Tracer
        if cfg.Tracers then
            d.tracer.Visible = true
            d.tracer.Color   = col
            d.tracer.From    = Vector2.new(cx, cy)
            d.tracer.To      = rs
        else
            d.tracer.Visible = false
        end

        -- Skeleton
        if cfg.SkeletonESP then
            for i, pair in ipairs(BONE_PAIRS) do
                local p1 = char:FindFirstChild(pair[1])
                local p2 = char:FindFirstChild(pair[2])
                local bone = d.bones[i]
                if p1 and p2 then
                    local s1, v1 = toScreen(p1.Position)
                    local s2, v2 = toScreen(p2.Position)
                    bone.Visible = v1 and v2
                    bone.From    = s1
                    bone.To      = s2
                    bone.Color   = col
                else
                    bone.Visible = false
                end
            end
        else
            for _, b in ipairs(d.bones) do b.Visible = false end
        end

        -- Chams
        if cfg.Chams then
            if not highlights[p] then
                pcall(function()
                    applyHighlight(p, col,
                        Color3.fromRGB(255,255,255))
                end)
            end
        else
            removeHighlight(p)
        end
    end
end)

-- ════════════════════════════════════════════════════════════════
-- ESP OBJETOS
-- ════════════════════════════════════════════════════════════════
local function runObjectESP(enabled, keywords, label, col)
    if not enabled then return end
    local objs = scanWorkspace(keywords)
    local cv   = Camera.ViewportSize
    for _, obj in ipairs(objs) do
        local pos = getPartPos(obj)
        if pos then
            local sc, vis, dep = toScreen(pos)
            if vis and dep > 0 then
                local t = newText(13, col)
                local l = newLine(col, 1)
                t.Text     = label .. " " .. distTo(pos) .. "m"
                t.Position = sc
                t.Visible  = true
                l.From     = Vector2.new(cv.X/2, cv.Y)
                l.To       = sc
                l.Visible  = true
                -- auto remove no próximo frame pra evitar acúmulo
                task.delay(0, function()
                    pcall(function() t:Remove() end)
                    pcall(function() l:Remove() end)
                end)
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    if cfg.ComputerESP then
        runObjectESP(true,
            {"computer","terminal","hack"},
            "COMP", Color3.fromRGB(50,200,255))
    end
    if cfg.PodESP then
        runObjectESP(true,
            {"pod","freeze","crystal"},
            "POD", Color3.fromRGB(150,220,255))
    end
    if cfg.ExitESP then
        runObjectESP(true,
            {"exit","door","escape"},
            "EXIT", Color3.fromRGB(255,220,50))
    end
end)

-- ── Beast Alert ────────────────────────────────────────────────
local alertLbl = newText(22, Color3.fromRGB(255,50,50))

RunService.RenderStepped:Connect(function()
    if not cfg.BeastAlert then
        alertLbl.Visible = false
        return
    end
    local close = false
    for _, p in ipairs(getPlayers(true, true, false)) do
        local r = p.Character
            and p.Character:FindFirstChild("HumanoidRootPart")
        local myR = getRoot()
        if r and myR then
            if (r.Position - myR.Position).Magnitude
            <= cfg.BeastAlertDist then
                close = true
            end
        end
    end
    alertLbl.Visible  = close
    alertLbl.Text     = "!! BEAST PROXIMO !!"
    alertLbl.Position = Vector2.new(
        Camera.ViewportSize.X/2, 55)
end)

-- ════════════════════════════════════════════════════════════════
-- SURVIVOR
-- ════════════════════════════════════════════════════════════════

-- Speed + Lock
RunService.Heartbeat:Connect(function()
    local hum = getHum()
    if not hum then return end
    if cfg.Speed or cfg.WalkLock then
        hum.WalkSpeed = cfg.SpeedVal
    end
end)

-- Inf Jump
UserInput.JumpRequest:Connect(function()
    if not cfg.InfJump then return end
    local hum = getHum()
    if hum then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- BunnyHop
RunService.Heartbeat:Connect(function()
    if not cfg.BunnyHop then return end
    local hum = getHum()
    if hum and hum.FloorMaterial ~= Enum.Material.Air then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Fly
local flyActive = false
local flyBV, flyBG

local function stopFly()
    flyActive = false
    pcall(function() flyBV:Destroy() end)
    pcall(function() flyBG:Destroy() end)
    flyBV = nil; flyBG = nil
end

local function startFly()
    stopFly()
    local root = getRoot()
    if not root then return end
    flyActive = true
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce  = Vector3.new(1e6,1e6,1e6)
    flyBV.Velocity  = Vector3.zero
    flyBV.Parent    = root
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e6,1e6,1e6)
    flyBG.CFrame    = root.CFrame
    flyBG.Parent    = root

    RunService.Heartbeat:Connect(function()
        if not cfg.Fly or not flyActive then
            stopFly(); return
        end
        if not flyBV or not flyBV.Parent then return end
        local dir = Vector3.zero
        local cf  = Camera.CFrame
        local spd = cfg.FlySpeed
        if UserInput:IsKeyDown(Enum.KeyCode.W) then
            dir += cf.LookVector end
        if UserInput:IsKeyDown(Enum.KeyCode.S) then
            dir -= cf.LookVector end
        if UserInput:IsKeyDown(Enum.KeyCode.A) then
            dir -= cf.RightVector end
        if UserInput:IsKeyDown(Enum.KeyCode.D) then
            dir += cf.RightVector end
        if UserInput:IsKeyDown(Enum.KeyCode.Space) then
            dir += Vector3.yAxis end
        if UserInput:IsKeyDown(Enum.KeyCode.LeftControl) then
            dir -= Vector3.yAxis end
        flyBV.Velocity = dir.Magnitude > 0
            and dir.Unit * spd
            or  Vector3.zero
        flyBG.CFrame = cf
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
    local hum = getHum()
    if hum and hum:GetState() == Enum.HumanoidStateType.Physics then
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end
end)

-- Inf Stamina
RunService.Heartbeat:Connect(function()
    if not cfg.InfStamina then return end
    local char = getChar()
    if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v.Name:lower():find("stamina")
        and v:IsA("NumberValue") then
            if v.Value < 10 then v.Value = 100 end
        end
    end
end)

-- Anti Freeze
RunService.Heartbeat:Connect(function()
    if not cfg.AntiFreeze then return end
    local char = getChar()
    if not char then return end
    for _, n in ipairs({"Frozen","IsFrozen","Freeze","Crystalized"}) do
        local v = char:FindFirstChild(n)
        if v then
            pcall(function() v:Destroy() end)
        end
    end
end)

-- Ghost Mode
RunService.Heartbeat:Connect(function()
    if not cfg.GhostMode then return end
    local char = getChar()
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            p.LocalTransparencyModifier = 1
        end
    end
end)

-- No Fail / Instant Hack via hook
local ncOk, oldNC = pcall(function()
    return hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args   = {...}
        local selfName = tostring(self):lower()

        if cfg.NoFailHack and method == "FireServer" then
            if selfName:find("fail") or selfName:find("error")
            or selfName:find("mistake") then
                return
            end
        end

        if cfg.InstantHack and method == "FireServer" then
            if selfName:find("hack") or selfName:find("computer")
            or selfName:find("progress") then
                args[1] = true
            end
        end

        if cfg.BeastNoCD and method == "FireServer" then
            if selfName:find("cooldown") or selfName:find("attack") then
                return oldNC(self, table.unpack(args))
            end
        end

        return oldNC(self, table.unpack(args))
    end)
end)

-- Auto Hack
RunService.Heartbeat:Connect(function()
    if not cfg.AutoHack then return end
    local root = getRoot()
    if not root then return end
    local comps = scanWorkspace({"computer","terminal","hack"})
    for _, obj in ipairs(comps) do
        local pos = getPartPos(obj)
        if pos and (pos - root.Position).Magnitude < 12 then
            local pp = obj:FindFirstChildOfClass("ProximityPrompt")
            if pp then
                pcall(function() fireproximityprompt(pp) end)
            end
        end
    end
end)

-- Auto Free
RunService.Heartbeat:Connect(function()
    if not cfg.AutoFree then return end
    local root = getRoot()
    if not root then return end
    for _, p in ipairs(getPlayers(true, false, true)) do
        if isFrozen(p) and p.Character then
            local fr = p.Character:FindFirstChild("HumanoidRootPart")
            if fr then
                local dist = (fr.Position - root.Position).Magnitude
                if dist > 12 then
                    root.CFrame = CFrame.new(
                        fr.Position + Vector3.new(2, 0, 2))
                else
                    local pp = p.Character:FindFirstChildOfClass(
                        "ProximityPrompt")
                    if pp then
                        pcall(function() fireproximityprompt(pp) end)
                    end
                end
            end
        end
    end
end)

-- Auto Dodge
RunService.Heartbeat:Connect(function()
    if not cfg.AutoDodge then return end
    local root = getRoot()
    if not root then return end
    for _, p in ipairs(getPlayers(true, true, false)) do
        local br = p.Character
            and p.Character:FindFirstChild("HumanoidRootPart")
        if br then
            local dist = (br.Position - root.Position).Magnitude
            if dist < cfg.AutoDodgeDist then
                local away = (root.Position - br.Position).Unit
                root.CFrame = CFrame.new(
                    root.Position + away * 20)
            end
        end
    end
end)

-- Fake Lag
local fakeLagActive = false
RunService.Heartbeat:Connect(function()
    if not cfg.FakeLag then
        fakeLagActive = false
        return
    end
    if not fakeLagActive then
        fakeLagActive = true
        task.spawn(function()
            while cfg.FakeLag do
                task.wait(cfg.FakeLagVal / 1000)
            end
            fakeLagActive = false
        end)
    end
end)

-- Teleports (botões)
local function tpToComp()
    local root = getRoot()
    if not root then return end
    local objs = scanWorkspace({"computer","terminal"})
    local best = findNearest(objs, getPartPos)
    if best then
        local pos = getPartPos(best)
        if pos then
            root.CFrame = CFrame.new(pos + Vector3.new(0,3,3))
        end
    end
end

local function tpToPod()
    local root = getRoot()
    if not root then return end
    local objs = scanWorkspace({"pod","freeze","crystal"})
    local best = findNearest(objs, getPartPos)
    if best then
        local pos = getPartPos(best)
        if pos then
            root.CFrame = CFrame.new(pos + Vector3.new(0,3,3))
        end
    end
end

local function tpToExit()
    local root = getRoot()
    if not root then return end
    local objs = scanWorkspace({"exit","door","escape"})
    local best = findNearest(objs, getPartPos)
    if best then
        local pos = getPartPos(best)
        if pos then
            root.CFrame = CFrame.new(pos + Vector3.new(0,3,3))
        end
    end
end

-- ════════════════════════════════════════════════════════════════
-- BEAST
-- ════════════════════════════════════════════════════════════════

RunService.Heartbeat:Connect(function()
    if not isBeast(LocalPlayer) then return end
    local root = getRoot()
    if not root then return end
    local hum = getHum()

    if cfg.BeastSpeed and hum then
        hum.WalkSpeed = cfg.BeastSpeedVal
    end

    local survivors = getPlayers(true, false, true)
    local nearest = findNearest(survivors, function(p)
        local r = p.Character
            and p.Character:FindFirstChild("HumanoidRootPart")
        return r and r.Position or nil
    end)

    if not nearest then return end
    local nr = nearest.Character
        and nearest.Character:FindFirstChild("HumanoidRootPart")
    if not nr then return end

    local dist = (nr.Position - root.Position).Magnitude

    if cfg.BeastTeleport then
        root.CFrame = CFrame.new(
            nr.Position + Vector3.new(0, 3, 3))
    end

    if cfg.BeastKillAura and dist <= cfg.BeastAuraRange then
        local tool = getChar()
            and getChar():FindFirstChildOfClass("Tool")
        if tool then
            local pp = nearest.Character
                :FindFirstChildOfClass("ProximityPrompt")
            if pp then
                pcall(function() fireproximityprompt(pp) end)
            end
        end
    end

    if cfg.BeastAutoFreeze and dist < 8 then
        local pp = nearest.Character
            :FindFirstChildOfClass("ProximityPrompt")
        if pp then
            pcall(function() fireproximityprompt(pp) end)
        end
    end

    if cfg.BeastFreezeAll then
        for _, p in ipairs(survivors) do
            local pr = p.Character
                and p.Character:FindFirstChild("HumanoidRootPart")
            if pr then
                root.CFrame = CFrame.new(
                    pr.Position + Vector3.new(0,3,2))
                local pp = p.Character
                    :FindFirstChildOfClass("ProximityPrompt")
                if pp then
                    pcall(function() fireproximityprompt(pp) end)
                end
                task.wait(0.1)
            end
        end
    end
end)

local function flingPlayer(p)
    local r = p.Character
        and p.Character:FindFirstChild("HumanoidRootPart")
    if not r then return end
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(
        math.random(-300,300), 500,
        math.random(-300,300))
    bv.MaxForce = Vector3.new(1e7,1e7,1e7)
    bv.Parent   = r
    Debris:AddItem(bv, 0.15)
end

-- ════════════════════════════════════════════════════════════════
-- MISC
-- ════════════════════════════════════════════════════════════════

-- Anti-AFK
task.spawn(function()
    while true do
        task.wait(55)
        if cfg.AntiAFK then
            pcall(function()
                VirtualUser:Button2Down(
                    Vector2.zero, Camera.CFrame)
                task.wait(0.1)
                VirtualUser:Button2Up(
                    Vector2.zero, Camera.CFrame)
            end)
        end
    end
end)

-- Stats HUD
local stats = {hacks=0,frees=0,frozen=0,escaped=0,rounds=0}
local statsLbl = newText(13, Color3.fromRGB(255,255,255))
statsLbl.Center = false

RunService.RenderStepped:Connect(function()
    statsLbl.Visible  = cfg.StatsHUD
    statsLbl.Text     = string.format(
        "Hacks: %d | Freed: %d | Frozen: %d | Escaped: %d",
        stats.hacks, stats.frees, stats.frozen, stats.escaped)
    statsLbl.Position = Vector2.new(10, 10)
end)

-- Flashlight
local flashPart
local function setFlashlight(on)
    if on then
        if flashPart then return end
        local root = getRoot()
        if not root then return end
        flashPart = Instance.new("Part")
        flashPart.Size        = Vector3.new(0.1,0.1,0.1)
        flashPart.CanCollide  = false
        flashPart.Anchored    = false
        flashPart.Transparency = 1
        local sl = Instance.new("SpotLight")
        sl.Range      = 80
        sl.Brightness = 6
        sl.Angle      = 80
        sl.Parent     = flashPart
        local wc = Instance.new("WeldConstraint")
        wc.Part0   = root
        wc.Part1   = flashPart
        wc.Parent  = flashPart
        flashPart.Parent = getChar()
    else
        if flashPart then
            pcall(function() flashPart:Destroy() end)
            flashPart = nil
        end
    end
end

-- Chat Spammer
task.spawn(function()
    while true do
        task.wait(math.max(cfg.ChatDelay, 1))
        if cfg.ChatSpammer then
            pcall(function()
                ReplicatedSto
                    :WaitForChild("DefaultChatSystemChatEvents")
                    :WaitForChild("SayMessageRequest")
                    :FireServer(cfg.ChatMsg, "All")
            end)
        end
    end
end)

-- Crosshair
local crossParts = {
    newLine(Color3.fromRGB(255,50,50), 2),
    newLine(Color3.fromRGB(255,50,50), 2),
    newLine(Color3.fromRGB(255,50,50), 2),
    newLine(Color3.fromRGB(255,50,50), 2),
}

RunService.RenderStepped:Connect(function()
    local cv = Camera.ViewportSize
    local cx, cy = cv.X/2, cv.Y/2
    local defs = {
        {Vector2.new(cx-12,cy), Vector2.new(cx-4,cy)},
        {Vector2.new(cx+4,cy),  Vector2.new(cx+12,cy)},
        {Vector2.new(cx,cy-12), Vector2.new(cx,cy-4)},
        {Vector2.new(cx,cy+4),  Vector2.new(cx,cy+12)},
    }
    for i, ln in ipairs(crossParts) do
        ln.Visible = cfg.CrosshairCustom
        ln.Color   = cfg.CrosshairCol
        ln.From    = defs[i][1]
        ln.To      = defs[i][2]
    end
end)

-- Rejoin
local function rejoin()
    pcall(function()
        TeleportSvc:Teleport(game.PlaceId, LocalPlayer)
    end)
end

-- ════════════════════════════════════════════════════════════════
-- RAYFIELD UI
-- ════════════════════════════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name             = "olliE | Flee The Facility",
    LoadingTitle     = "olliE v2 carregando...",
    LoadingSubtitle  = "absolute olliE — gng",
    Icon             = "skull",
    ConfigurationSaving = {
        Enabled  = true,
        FileName = "OllieFTF_v2"
    },
    KeySystem = false,
})

-- ── ABA: ESP ──────────────────────────────────────────────────
local ESP = Window:CreateTab("ESP", "eye")

ESP:CreateSection("Jogadores")
ESP:CreateToggle({Name="Survivor ESP",CurrentValue=cfg.SurvivorESP,Flag="SurvivorESP",Callback=function(v)cfg.SurvivorESP=v end})
ESP:CreateToggle({Name="Beast ESP",CurrentValue=cfg.BeastESP,Flag="BeastESP",Callback=function(v)cfg.BeastESP=v end})
ESP:CreateToggle({Name="Box",CurrentValue=cfg.ESPBox,Flag="ESPBox",Callback=function(v)cfg.ESPBox=v end})
ESP:CreateToggle({Name="Nome",CurrentValue=cfg.ESPName,Flag="ESPName",Callback=function(v)cfg.ESPName=v end})
ESP:CreateToggle({Name="Distância",CurrentValue=cfg.ESPDist,Flag="ESPDist",Callback=function(v)cfg.ESPDist=v end})
ESP:CreateToggle({Name="Status",CurrentValue=cfg.ESPStatus,Flag="ESPStatus",Callback=function(v)cfg.ESPStatus=v end})
ESP:CreateToggle({Name="HP Bar",CurrentValue=cfg.ESPHealth,Flag="ESPHealth",Callback=function(v)cfg.ESPHealth=v end})
ESP:CreateToggle({Name="Skeleton",CurrentValue=cfg.SkeletonESP,Flag="SkeletonESP",Callback=function(v)cfg.SkeletonESP=v end})
ESP:CreateToggle({Name="Chams (Parede)",CurrentValue=cfg.Chams,Flag="Chams",Callback=function(v)cfg.Chams=v end})
ESP:CreateToggle({Name="Tracers",CurrentValue=cfg.Tracers,Flag="Tracers",Callback=function(v)cfg.Tracers=v end})

ESP:CreateSection("Objetos")
ESP:CreateToggle({Name="Computer ESP",CurrentValue=cfg.ComputerESP,Flag="ComputerESP",Callback=function(v)cfg.ComputerESP=v end})
ESP:CreateToggle({Name="Computer Status %",CurrentValue=cfg.ComputerStatus,Flag="ComputerStatus",Callback=function(v)cfg.ComputerStatus=v end})
ESP:CreateToggle({Name="Freeze Pod ESP",CurrentValue=cfg.PodESP,Flag="PodESP",Callback=function(v)cfg.PodESP=v end})
ESP:CreateToggle({Name="Exit Door ESP",CurrentValue=cfg.ExitESP,Flag="ExitESP",Callback=function(v)cfg.ExitESP=v end})

ESP:CreateSection("Alertas")
ESP:CreateToggle({Name="Beast Alert",CurrentValue=cfg.BeastAlert,Flag="BeastAlert",Callback=function(v)cfg.BeastAlert=v end})
ESP:CreateSlider({Name="Distância do Alert",Range={10,150},Increment=5,CurrentValue=cfg.BeastAlertDist,Flag="BeastAlertDist",Callback=function(v)cfg.BeastAlertDist=v end})

-- ── ABA: SURVIVOR ─────────────────────────────────────────────
local SRV = Window:CreateTab("Survivor", "user")

SRV:CreateSection("Movimento")
SRV:CreateToggle({Name="Speed",CurrentValue=cfg.Speed,Flag="Speed",Callback=function(v)cfg.Speed=v end})
SRV:CreateSlider({Name="Velocidade",Range={16,150},Increment=2,CurrentValue=cfg.SpeedVal,Flag="SpeedVal",Callback=function(v)cfg.SpeedVal=v end})
SRV:CreateToggle({Name="Walkspeed Lock",CurrentValue=cfg.WalkLock,Flag="WalkLock",Callback=function(v)cfg.WalkLock=v end})
SRV:CreateToggle({Name="Infinite Jump",CurrentValue=cfg.InfJump,Flag="InfJump",Callback=function(v)cfg.InfJump=v end})
SRV:CreateToggle({Name="Bunny Hop",CurrentValue=cfg.BunnyHop,Flag="BunnyHop",Callback=function(v)cfg.BunnyHop=v end})
SRV:CreateToggle({Name="Fly",CurrentValue=cfg.Fly,Flag="Fly",Callback=function(v)cfg.Fly=v;if v then startFly() else stopFly() end end})
SRV:CreateSlider({Name="Fly Speed",Range={10,150},Increment=2,CurrentValue=cfg.FlySpeed,Flag="FlySpeed",Callback=function(v)cfg.FlySpeed=v end})
SRV:CreateToggle({Name="NoClip",CurrentValue=cfg.NoClip,Flag="NoClip",Callback=function(v)cfg.NoClip=v end})
SRV:CreateToggle({Name="No Crawl",CurrentValue=cfg.NoCrawl,Flag="NoCrawl",Callback=function(v)cfg.NoCrawl=v end})
SRV:CreateToggle({Name="Ghost Mode",CurrentValue=cfg.GhostMode,Flag="GhostMode",Callback=function(v)cfg.GhostMode=v end})

SRV:CreateSection("Gameplay")
SRV:CreateToggle({Name="Inf Stamina",CurrentValue=cfg.InfStamina,Flag="InfStamina",Callback=function(v)cfg.InfStamina=v end})
SRV:CreateToggle({Name="Anti Freeze",CurrentValue=cfg.AntiFreeze,Flag="AntiFreeze",Callback=function(v)cfg.AntiFreeze=v end})
SRV:CreateToggle({Name="No Fail Hack",CurrentValue=cfg.NoFailHack,Flag="NoFailHack",Callback=function(v)cfg.NoFailHack=v end})
SRV:CreateToggle({Name="Instant Hack",CurrentValue=cfg.InstantHack,Flag="InstantHack",Callback=function(v)cfg.InstantHack=v end})
SRV:CreateToggle({Name="Auto Hack",CurrentValue=cfg.AutoHack,Flag="AutoHack",Callback=function(v)cfg.AutoHack=v end})
SRV:CreateToggle({Name="Auto Free Survivors",CurrentValue=cfg.AutoFree,Flag="AutoFree",Callback=function(v)cfg.AutoFree=v end})
SRV:CreateToggle({Name="Auto Dodge Beast",CurrentValue=cfg.AutoDodge,Flag="AutoDodge",Callback=function(v)cfg.AutoDodge=v end})
SRV:CreateSlider({Name="Dodge Distance",Range={10,100},Increment=5,CurrentValue=cfg.AutoDodgeDist,Flag="AutoDodgeDist",Callback=function(v)cfg.AutoDodgeDist=v end})
SRV:CreateToggle({Name="Fake Lag",CurrentValue=cfg.FakeLag,Flag="FakeLag",Callback=function(v)cfg.FakeLag=v end})
SRV:CreateSlider({Name="Lag (ms)",Range={50,500},Increment=50,CurrentValue=cfg.FakeLagVal,Flag="FakeLagVal",Callback=function(v)cfg.FakeLagVal=v end})

SRV:CreateSection("Teleportes")
SRV:CreateButton({Name="TP → Computer",Callback=tpToComp})
SRV:CreateButton({Name="TP → Pod",Callback=tpToPod})
SRV:CreateButton({Name="TP → Exit",Callback=tpToExit})

-- ── ABA: BEAST ────────────────────────────────────────────────
local BST = Window:CreateTab("Beast", "skull")

BST:CreateSection("Movimento")
BST:CreateToggle({Name="Beast Speed",CurrentValue=cfg.BeastSpeed,Flag="BeastSpeed",Callback=function(v)cfg.BeastSpeed=v end})
BST:CreateSlider({Name="Velocidade Beast",Range={16,150},Increment=2,CurrentValue=cfg.BeastSpeedVal,Flag="BeastSpeedVal",Callback=function(v)cfg.BeastSpeedVal=v end})
BST:CreateToggle({Name="Teleport to Survivor",CurrentValue=cfg.BeastTeleport,Flag="BeastTeleport",Callback=function(v)cfg.BeastTeleport=v end})

BST:CreateSection("Ataque")
BST:CreateToggle({Name="Auto Freeze",CurrentValue=cfg.BeastAutoFreeze,Flag="BeastAutoFreeze",Callback=function(v)cfg.BeastAutoFreeze=v end})
BST:CreateToggle({Name="Kill Aura",CurrentValue=cfg.BeastKillAura,Flag="BeastKillAura",Callback=function(v)cfg.BeastKillAura=v end})
BST:CreateSlider({Name="Aura Range",Range={5,60},Increment=5,CurrentValue=cfg.BeastAuraRange,Flag="BeastAuraRange",Callback=function(v)cfg.BeastAuraRange=v end})
BST:CreateToggle({Name="Freeze All",CurrentValue=cfg.BeastFreezeAll,Flag="BeastFreezeAll",Callback=function(v)cfg.BeastFreezeAll=v end})
BST:CreateToggle({Name="No Cooldown",CurrentValue=cfg.BeastNoCD,Flag="BeastNoCD",Callback=function(v)cfg.BeastNoCD=v end})
BST:CreateButton({Name="Fling Survivor Mais Perto",Callback=function()
    local survivors = getPlayers(true, false, true)
    local nearest = findNearest(survivors, function(p)
        local r = p.Character
            and p.Character:FindFirstChild("HumanoidRootPart")
        return r and r.Position or nil
    end)
    if nearest then flingPlayer(nearest) end
end})

-- ── ABA: MISC ─────────────────────────────────────────────────
local MSC = Window:CreateTab("Misc", "settings")

MSC:CreateSection("Utilidades")
MSC:CreateToggle({Name="Anti-AFK",CurrentValue=cfg.AntiAFK,Flag="AntiAFK",Callback=function(v)cfg.AntiAFK=v end})
MSC:CreateToggle({Name="Stats HUD",CurrentValue=cfg.StatsHUD,Flag="StatsHUD",Callback=function(v)cfg.StatsHUD=v end})
MSC:CreateToggle({Name="Flashlight",CurrentValue=cfg.Flashlight,Flag="Flashlight",Callback=function(v)cfg.Flashlight=v;setFlashlight(v) end})
MSC:CreateToggle({Name="Crosshair Custom",CurrentValue=cfg.CrosshairCustom,Flag="CrosshairCustom",Callback=function(v)cfg.CrosshairCustom=v end})
MSC:CreateColorPicker({Name="Cor Crosshair",Color=cfg.CrosshairCol,Flag="CrosshairCol",Callback=function(v)cfg.CrosshairCol=v end})

MSC:CreateSection("Chat")
MSC:CreateToggle({Name="Chat Spammer",CurrentValue=cfg.ChatSpammer,Flag="ChatSpammer",Callback=function(v)cfg.ChatSpammer=v end})
MSC:CreateInput({Name="Mensagem",CurrentValue=cfg.ChatMsg,PlaceholderText="mensagem aqui",RemoveTextAfterFocusLost=false,Flag="ChatMsg",Callback=function(v)cfg.ChatMsg=v end})
MSC:CreateSlider({Name="Delay (s)",Range={1,30},Increment=1,CurrentValue=cfg.ChatDelay,Flag="ChatDelay",Callback=function(v)cfg.ChatDelay=v end})

MSC:CreateSection("Servidor")
MSC:CreateButton({Name="Rejoin",Callback=rejoin})
MSC:CreateButton({Name="Server Hop",Callback=rejoin})

-- ── Notificação de boot ────────────────────────────────────────
Rayfield:Notify({
    Title    = "olliE | FTF v2",
    Content  = "carregado, absolute olliE to Sam — gng",
    Duration = 5,
    Image    = "skull",
})

print("[olliE] FTF v2 carregado com sucesso")
