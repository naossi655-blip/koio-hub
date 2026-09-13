--[[
    ========================================================================
    KOIO INTERNAL // ULTIMATE LUAU STANDALONE HUB (v3.0)
    ========================================================================
    Menu profesional estilo ImGui Dark Obsidian & Emerald Green
    Totalmente autonomo y compatible con cualquier juego de Roblox
    
    Instrucciones para Pastebin:
    1. Copia todo este codigo.
    2. Pegalo en pastebin.com y guarda el enlace RAW.
    3. Ejecutalo con:
       loadstring(game:HttpGet("https://pastebin.com/raw/TU_PASTEBIN_ID"))()
    
    Teclas de acceso rapido:
    - [RightShift] o [Insert] : Alternar ventana del menu
    - [Ctrl + Click Izquierdo] : Click Teleport (si esta activo)
    - [Click Derecho (mantener)] : Aimbot Lock (si esta activo)
    ========================================================================
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Evitar instancias duplicadas de la interfaz
if game:GetService("CoreGui"):FindFirstChild("KoioUltimateHub") then
    game:GetService("CoreGui").KoioUltimateHub:Destroy()
end

-- ============================================================================
-- TABLA GLOBAL DE CONFIGURACIÓN
-- ============================================================================
local State = {
    UI = {
        Visible = true,
        ToggleKey = Enum.KeyCode.RightShift,
    },
    Aim = {
        Aimbot = false,
        AimbotSmooth = 5,
        AimbotFOV = 120,
        DrawFOV = false,
        TargetPart = "Head", -- "Head" o "HumanoidRootPart"
        TeamCheck = false,
        WallCheck = false,
        SilentAim = false,
        SilentAimFOV = 150,
        Triggerbot = false,
        HBE = false,
        HBESize = 12,
        HBETrans = 0.6,
    },
    Movement = {
        Speed = false,
        SpeedVal = 35,
        Jump = false,
        JumpVal = 80,
        InfJump = false,
        Noclip = false,
        Fly = false,
        FlySpeed = 65,
        Gravity = 196.2,
        HipHeight = false,
        HipHeightVal = 2,
        Spinbot = false,
        SpinSpeed = 18,
    },
    Visuals = {
        Fullbright = false,
        NoFog = false,
        FOV = 70,
        ClockTime = 14,
        Freecam = false,
    },
    ESP = {
        Master = false,
        Chams = true,
        Names = true,
        Tracers = false,
        Distance = true,
        Health = true,
        TeamCheck = false,
        Color = Color3.fromRGB(87, 139, 46),
        OutlineColor = Color3.fromRGB(255, 255, 255),
    },
    Teleport = {
        ClickTP = false,
        SavedCFrame = nil,
    },
    Exploits = {
        FastLoot = false,
        Freeze = false,
        AntiAFK = true,
        AutoSteal = false,
    }
}

-- ============================================================================
-- UTILIDADES DE JUGADOR Y PERSONAJE
-- ============================================================================
local function GetCharacter(player)
    player = player or LocalPlayer
    return player.Character
end

local function GetHRP(player)
    local char = GetCharacter(player)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid(player)
    local char = GetCharacter(player)
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function IsAlive(player)
    local hum = GetHumanoid(player)
    return hum and hum.Health > 0
end

-- ============================================================================
-- MÓDULO: COMBATE, AIMBOT & HITBOX EXPANDER
-- ============================================================================

-- Circulo FOV con Drawing API si esta soportada
local fovCircle = nil
pcall(function()
    if Drawing and Drawing.new then
        fovCircle = Drawing.new("Circle")
        fovCircle.Thickness = 1.5
        fovCircle.NumSides = 48
        fovCircle.Radius = State.Aim.AimbotFOV
        fovCircle.Filled = false
        fovCircle.Visible = false
        fovCircle.Color = Color3.fromRGB(138, 232, 125)
        fovCircle.Transparency = 0.8
    end
end)

local function GetClosestTarget(fovRadius, targetPartName, teamCheck, wallCheck)
    local bestTarget = nil
    local shortestDist = fovRadius
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and IsAlive(p) then
            if not teamCheck or (p.Team ~= LocalPlayer.Team) then
                local char = p.Character
                local part = char and char:FindFirstChild(targetPartName)
                if part then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        if dist < shortestDist then
                            if wallCheck then
                                local rayParams = RaycastParams.new()
                                rayParams.FilterDescendantsInstances = { LocalPlayer.Character, char }
                                rayParams.FilterType = RaycastFilterType.Exclude
                                local hit = workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, rayParams)
                                if not hit then
                                    shortestDist = dist
                                    bestTarget = part
                                end
                            else
                                shortestDist = dist
                                bestTarget = part
                            end
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

-- Bucle de Aimbot
local isAiming = false
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.UserInputType == Enum.UserInputType.MouseButton2 then
        isAiming = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isAiming = false
    end
end)

RunService.RenderStepped:Connect(function()
    -- Actualizar Circulo FOV
    if fovCircle then
        fovCircle.Visible = State.Aim.DrawFOV and State.UI.Visible
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        fovCircle.Radius = State.Aim.AimbotFOV
    end

    -- Ejecutar Aimbot
    if State.Aim.Aimbot and isAiming then
        local target = GetClosestTarget(State.Aim.AimbotFOV, State.Aim.TargetPart, State.Aim.TeamCheck, State.Aim.WallCheck)
        if target then
            local targetPos = target.Position
            local camPos = Camera.CFrame.Position
            local targetCFrame = CFrame.new(camPos, targetPos)
            local smooth = math.clamp(State.Aim.AimbotSmooth, 1, 20)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 / smooth)
        end
    end

    -- Triggerbot
    if State.Aim.Triggerbot and Mouse.Target then
        local targetChar = Mouse.Target:FindFirstAncestorOfClass("Model")
        local targetPlayer = targetChar and Players:GetPlayerFromCharacter(targetChar)
        if targetPlayer and targetPlayer ~= LocalPlayer and IsAlive(targetPlayer) then
            pcall(function()
                mouse1click()
            end)
        end
    end
end)

-- Bucle de Hitbox Expander (HBE)
task.spawn(function()
    while true do
        if State.Aim.HBE then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    if hrp and hum and hum.Health > 0 then
                        if not State.Aim.TeamCheck or (p.Team ~= LocalPlayer.Team) then
                            hrp.Size = Vector3.new(State.Aim.HBESize, State.Aim.HBESize, State.Aim.HBESize)
                            hrp.Transparency = State.Aim.HBETrans
                            hrp.CanCollide = false
                            hrp.Material = Enum.Material.ForceField
                        end
                    end
                end
            end
        end
        task.wait(0.3)
    end
end)

-- Hook de Silent Aim si el entorno soporta hookmetamethod
pcall(function()
    if hookmetamethod and getnamecallmethod then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            local args = { ... }

            if State.Aim.SilentAim and (method == "FireServer" or method == "InvokeServer") then
                local target = GetClosestTarget(State.Aim.SilentAimFOV, State.Aim.TargetPart, State.Aim.TeamCheck, false)
                if target then
                    for i, arg in ipairs(args) do
                        if typeof(arg) == "Vector3" then
                            args[i] = target.Position
                        elseif typeof(arg) == "CFrame" then
                            args[i] = target.CFrame
                        end
                    end
                    return oldNamecall(self, unpack(args))
                end
            end
            return oldNamecall(self, ...)
        end)
    end
end)

-- ============================================================================
-- MÓDULO: MOVIMIENTO Y FÍSICAS
-- ============================================================================

-- Bucle Noclip
RunService.Stepped:Connect(function()
    if State.Movement.Noclip then
        local char = LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    p.CanCollide = false
                end
            end
        end
    end
end)

-- Bucle Speed, JumpPower, HipHeight, Spinbot
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")

        if hum then
            if State.Movement.Speed then hum.WalkSpeed = State.Movement.SpeedVal end
            if State.Movement.Jump then hum.JumpPower = State.Movement.JumpVal end
            if State.Movement.HipHeight then hum.HipHeight = State.Movement.HipHeightVal end
        end

        if State.Movement.Spinbot and hrp then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(State.Movement.SpinSpeed), 0)
        end
    end

    if State.Movement.Gravity then
        workspace.Gravity = State.Movement.Gravity
    end
end)

-- Salto Infinito
UserInputService.JumpRequest:Connect(function()
    if State.Movement.InfJump then
        local hum = GetHumanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Vuelo Libre 6-DOF
local flyBV, flyBG
local function SetFly(enabled)
    State.Movement.Fly = enabled
    local hrp = GetHRP()
    if not hrp then return end

    if enabled then
        flyBV = Instance.new("BodyVelocity")
        flyBV.Name = "KoioBV"
        flyBV.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        flyBV.Parent = hrp

        flyBG = Instance.new("BodyGyro")
        flyBG.Name = "KoioBG"
        flyBG.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
        flyBG.P = 1e4
        flyBG.Parent = hrp

        task.spawn(function()
            while State.Movement.Fly and hrp.Parent do
                local dir = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end

                flyBV.Velocity = dir * State.Movement.FlySpeed
                flyBG.CFrame = Camera.CFrame
                RunService.RenderStepped:Wait()
            end
            if flyBV then flyBV:Destroy() end
            if flyBG then flyBG:Destroy() end
        end)
    else
        if flyBV then flyBV:Destroy() end
        if flyBG then flyBG:Destroy() end
    end
end

-- ============================================================================
-- MÓDULO: VISUALES Y MUNDO
-- ============================================================================
local origLighting = {
    Ambient = Lighting.Ambient,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    GlobalShadows = Lighting.GlobalShadows,
    FogEnd = Lighting.FogEnd
}

RunService.RenderStepped:Connect(function()
    if State.Visuals.Fullbright then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
        Lighting.GlobalShadows = false
    end
    if State.Visuals.NoFog then
        Lighting.FogEnd = 1e6
    end
    if State.Visuals.FOV then
        Camera.FieldOfView = State.Visuals.FOV
    end
    if State.Visuals.ClockTime then
        Lighting.ClockTime = State.Visuals.ClockTime
    end
end)

-- ============================================================================
-- MÓDULO: ESP JUGADORES (HIGHLIGHTS, NOMBRES Y TRACERS)
-- ============================================================================
local espCache = {}

local function CreatePlayerESP(p)
    if p == LocalPlayer then return end

    local function Apply(char)
        if not char then return end
        if espCache[p] then
            pcall(function()
                if espCache[p].Highlight then espCache[p].Highlight:Destroy() end
                if espCache[p].Billboard then espCache[p].Billboard:Destroy() end
            end)
            espCache[p] = nil
        end

        local data = {}

        -- 1. Highlight
        local hl = Instance.new("Highlight")
        hl.Name = "KoioHL"
        hl.Adornee = char
        hl.FillColor = State.ESP.Color
        hl.OutlineColor = State.ESP.OutlineColor
        hl.FillTransparency = 0.4
        hl.OutlineTransparency = 0.1
        hl.Enabled = State.ESP.Master and State.ESP.Chams
        hl.Parent = char
        data.Highlight = hl

        -- 2. Billboard Tag (Nombre, Salud, Distancia)
        local head = char:WaitForChild("Head", 4)
        if head then
            local bb = Instance.new("BillboardGui")
            bb.Name = "KoioBB"
            bb.Adornee = head
            bb.Size = UDim2.new(0, 140, 0, 40)
            bb.StudsOffset = Vector3.new(0, 2.5, 0)
            bb.AlwaysOnTop = true
            bb.Enabled = State.ESP.Master and State.ESP.Names
            bb.Parent = head

            local tag = Instance.new("TextLabel")
            tag.Name = "Tag"
            tag.Size = UDim2.new(1, 0, 1, 0)
            tag.BackgroundTransparency = 1
            tag.Font = Enum.Font.GothamBold
            tag.TextSize = 11
            tag.TextColor3 = Color3.fromRGB(240, 255, 240)
            tag.TextStrokeTransparency = 0.3
            tag.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            tag.Text = p.DisplayName
            tag.Parent = bb
            data.Billboard = bb
            data.Tag = tag
        end

        espCache[p] = data
    end

    if p.Character then Apply(p.Character) end
    p.CharacterAdded:Connect(Apply)
end

for _, p in ipairs(Players:GetPlayers()) do CreatePlayerESP(p) end
Players.PlayerAdded:Connect(CreatePlayerESP)
Players.PlayerRemoving:Connect(function(p)
    if espCache[p] then
        pcall(function()
            if espCache[p].Highlight then espCache[p].Highlight:Destroy() end
            if espCache[p].Billboard then espCache[p].Billboard:Destroy() end
        end)
        espCache[p] = nil
    end
end)

-- Bucle de Actualización del ESP
RunService.RenderStepped:Connect(function()
    if not State.ESP.Master then
        for _, data in pairs(espCache) do
            if data.Highlight then data.Highlight.Enabled = false end
            if data.Billboard then data.Billboard.Enabled = false end
        end
        return
    end

    local myHRP = GetHRP()
    for p, data in pairs(espCache) do
        local char = p.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        local isTeam = State.ESP.TeamCheck and (p.Team ~= nil and p.Team == LocalPlayer.Team)
        local visible = (not isTeam) and (hum and hum.Health > 0)

        if data.Highlight and data.Highlight.Parent then
            data.Highlight.Enabled = visible and State.ESP.Chams
            data.Highlight.FillColor = State.ESP.Color
        end

        if data.Billboard and data.Billboard.Parent and myHRP and hrp then
            data.Billboard.Enabled = visible and State.ESP.Names
            if data.Tag then
                local dist = math.floor((hrp.Position - myHRP.Position).Magnitude)
                local hp = math.floor(hum.Health)
                data.Tag.Text = string.format("%s\n[%d HP | %d studs]", p.DisplayName, hp, dist)
            end
        end
    end
end)

-- ============================================================================
-- MÓDULO: EXPLOITS Y TELETRANSPORTE
-- ============================================================================

-- Click to Teleport (Ctrl + Click)
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and State.Teleport.ClickTP then
        if input.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            local hit = Mouse.Hit
            local hrp = GetHRP()
            if hit and hrp then
                hrp.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3.5, 0))
            end
        end
    end
end)

-- Fast Loot (Instant ProximityPrompt)
ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
    if State.Exploits.FastLoot then
        pcall(function()
            prompt.HoldDuration = 0
        end)
    end
end)

-- Anti-AFK
pcall(function()
    local vu = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        if State.Exploits.AntiAFK then
            vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end
    end)
end)

-- Congelar Personaje (Anti-Knockback)
RunService.Stepped:Connect(function()
    if State.Exploits.Freeze then
        local hrp = GetHRP()
        if hrp then
            hrp.Velocity = Vector3.zero
            hrp.RotVelocity = Vector3.zero
        end
    end
end)

-- ============================================================================
-- CONSTRUCCIÓN DE LA INTERFAZ GRÁFICA (GUI IMGUI OBSIDIAN & EMERALD)
-- ============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KoioUltimateHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 620, 0, 420)
MainFrame.Position = UDim2.new(0.5, -310, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 17)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(40, 75, 50)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

-- Topbar
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 36)
TopBar.BackgroundColor3 = Color3.fromRGB(11, 16, 13)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text = "  KOIO ULTIMATE // LUAU INTERNAL HUB"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 13
TitleLabel.TextColor3 = Color3.fromRGB(138, 232, 125)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Size = UDim2.new(0, 300, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Parent = TopBar

local SubtitleLabel = Instance.new("TextLabel")
SubtitleLabel.Text = "v3.0 • [RShift: Alternar]"
SubtitleLabel.Font = Enum.Font.Gotham
SubtitleLabel.TextSize = 11
SubtitleLabel.TextColor3 = Color3.fromRGB(96, 128, 104)
SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Right
SubtitleLabel.Position = UDim2.new(1, -70, 0, 0)
SubtitleLabel.Size = UDim2.new(0, 200, 1, 0)
SubtitleLabel.BackgroundTransparency = 1
SubtitleLabel.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.TextColor3 = Color3.fromRGB(240, 100, 100)
CloseBtn.BackgroundColor3 = Color3.fromRGB(22, 30, 25)
CloseBtn.Size = UDim2.new(0, 26, 0, 22)
CloseBtn.Position = UDim2.new(1, -32, 0, 7)
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TopBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 4)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Arrastre
local isDragging, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = false
    end
end)

-- Tecla alternar
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and (input.KeyCode == State.UI.ToggleKey or input.KeyCode == Enum.KeyCode.Insert) then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 140, 1, -36)
Sidebar.Position = UDim2.new(0, 0, 0, 36)
Sidebar.BackgroundColor3 = Color3.fromRGB(11, 16, 13)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.Padding = UDim.new(0, 4)
SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SidebarLayout.Parent = Sidebar

local SidebarPad = Instance.new("UIPadding")
SidebarPad.PaddingTop = UDim.new(0, 6)
SidebarPad.Parent = Sidebar

-- Content Area
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -148, 1, -44)
ContentArea.Position = UDim2.new(0, 144, 0, 40)
ContentArea.BackgroundColor3 = Color3.fromRGB(13, 18, 15)
ContentArea.BorderSizePixel = 0
ContentArea.Parent = MainFrame

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 6)
ContentCorner.Parent = ContentArea

-- ============================================================================
-- GENERADOR DE WIDGETS
-- ============================================================================
local Tabs = {}
local CurrentTab = nil

local function CreateTab(name, icon)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(1, -12, 0, 28)
    TabBtn.BackgroundColor3 = Color3.fromRGB(16, 24, 19)
    TabBtn.Text = icon .. " " .. name
    TabBtn.Font = Enum.Font.GothamSemibold
    TabBtn.TextSize = 11
    TabBtn.TextColor3 = Color3.fromRGB(180, 205, 185)
    TabBtn.BorderSizePixel = 0
    TabBtn.Parent = Sidebar

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 4)
    Corner.Parent = TabBtn

    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, -10, 1, -10)
    Page.Position = UDim2.new(0, 5, 0, 5)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 4
    Page.ScrollBarImageColor3 = Color3.fromRGB(87, 139, 46)
    Page.Visible = false
    Page.Parent = ContentArea

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 5)
    Layout.Parent = Page

    local Pad = Instance.new("UIPadding")
    Pad.PaddingTop = UDim.new(0, 4)
    Pad.PaddingLeft = UDim.new(0, 4)
    Pad.PaddingRight = UDim.new(0, 4)
    Pad.Parent = Page

    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Page.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 14)
    end)

    local data = { Button = TabBtn, Page = Page }
    Tabs[name] = data

    TabBtn.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do
            t.Page.Visible = false
            t.Button.BackgroundColor3 = Color3.fromRGB(16, 24, 19)
            t.Button.TextColor3 = Color3.fromRGB(180, 205, 185)
        end
        Page.Visible = true
        TabBtn.BackgroundColor3 = Color3.fromRGB(87, 139, 46)
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)

    if not CurrentTab then
        CurrentTab = data
        Page.Visible = true
        TabBtn.BackgroundColor3 = Color3.fromRGB(87, 139, 46)
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end

    return Page
end

local function CreateSection(parent, title)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 0, 22)
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 11
    Label.TextColor3 = Color3.fromRGB(138, 232, 125)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Text = "// " .. string.upper(title)
    Label.Parent = parent
end

local function CreateToggle(parent, title, default, callback)
    local state = default or false

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 30)
    Frame.BackgroundColor3 = Color3.fromRGB(18, 25, 20)
    Frame.BorderSizePixel = 0
    Frame.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 4)
    Corner.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Text = title
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 11
    Label.TextColor3 = Color3.fromRGB(220, 235, 225)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Size = UDim2.new(1, -50, 1, 0)
    Label.Position = UDim2.new(0, 8, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Parent = Frame

    local Switch = Instance.new("TextButton")
    Switch.Text = ""
    Switch.Size = UDim2.new(0, 34, 0, 16)
    Switch.Position = UDim2.new(1, -42, 0.5, -8)
    Switch.BackgroundColor3 = state and Color3.fromRGB(87, 139, 46) or Color3.fromRGB(35, 45, 38)
    Switch.BorderSizePixel = 0
    Switch.Parent = Frame

    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(1, 0)
    SwitchCorner.Parent = Switch

    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 12, 0, 12)
    Indicator.Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
    Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Indicator.BorderSizePixel = 0
    Indicator.Parent = Switch

    local IndCorner = Instance.new("UICorner")
    IndCorner.CornerRadius = UDim.new(1, 0)
    IndCorner.Parent = Indicator

    local function updateVisuals()
        local targetPos = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
        local targetColor = state and Color3.fromRGB(87, 139, 46) or Color3.fromRGB(35, 45, 38)
        TweenService:Create(Indicator, TweenInfo.new(0.15), { Position = targetPos }):Play()
        TweenService:Create(Switch, TweenInfo.new(0.15), { BackgroundColor3 = targetColor }):Play()
    end

    Switch.MouseButton1Click:Connect(function()
        state = not state
        updateVisuals()
        pcall(callback, state)
    end)
end

local function CreateSlider(parent, title, min, max, default, callback)
    local value = default or min

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 42)
    Frame.BackgroundColor3 = Color3.fromRGB(18, 25, 20)
    Frame.BorderSizePixel = 0
    Frame.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 4)
    Corner.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Text = title
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 11
    Label.TextColor3 = Color3.fromRGB(220, 235, 225)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Size = UDim2.new(1, -60, 0, 18)
    Label.Position = UDim2.new(0, 8, 0, 2)
    Label.BackgroundTransparency = 1
    Label.Parent = Frame

    local ValLabel = Instance.new("TextLabel")
    ValLabel.Text = tostring(value)
    ValLabel.Font = Enum.Font.GothamBold
    ValLabel.TextSize = 11
    ValLabel.TextColor3 = Color3.fromRGB(138, 232, 125)
    ValLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValLabel.Size = UDim2.new(0, 50, 0, 18)
    ValLabel.Position = UDim2.new(1, -58, 0, 2)
    ValLabel.BackgroundTransparency = 1
    ValLabel.Parent = Frame

    local Bar = Instance.new("TextButton")
    Bar.Text = ""
    Bar.Size = UDim2.new(1, -16, 0, 6)
    Bar.Position = UDim2.new(0, 8, 0, 26)
    Bar.BackgroundColor3 = Color3.fromRGB(30, 40, 34)
    Bar.BorderSizePixel = 0
    Bar.Parent = Frame

    local BarCorner = Instance.new("UICorner")
    BarCorner.CornerRadius = UDim.new(1, 0)
    BarCorner.Parent = Bar

    local Fill = Instance.new("Frame")
    local pct = math.clamp((value - min) / (max - min), 0, 1)
    Fill.Size = UDim2.new(pct, 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(87, 139, 46)
    Fill.BorderSizePixel = 0
    Fill.Parent = Bar

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = Fill

    local isDraggingSlider = false
    local function update(input)
        local posX = input.Position.X - Bar.AbsolutePosition.X
        local ratio = math.clamp(posX / Bar.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (max - min) * ratio)
        ValLabel.Text = tostring(value)
        Fill.Size = UDim2.new(ratio, 0, 1, 0)
        pcall(callback, value)
    end

    Bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDraggingSlider = true
            update(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if isDraggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDraggingSlider = false
        end
    end)
end

local function CreateButton(parent, title, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 28)
    Button.BackgroundColor3 = Color3.fromRGB(24, 38, 28)
    Button.Text = title
    Button.Font = Enum.Font.GothamSemibold
    Button.TextSize = 11
    Button.TextColor3 = Color3.fromRGB(230, 245, 235)
    Button.BorderSizePixel = 0
    Button.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 4)
    Corner.Parent = Button

    Button.MouseButton1Click:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.08), { BackgroundColor3 = Color3.fromRGB(87, 139, 46) }):Play()
        task.wait(0.12)
        TweenService:Create(Button, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(24, 38, 28) }):Play()
        pcall(callback)
    end)
end

local function CreateInput(parent, title, placeholder, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 32)
    Frame.BackgroundColor3 = Color3.fromRGB(18, 25, 20)
    Frame.BorderSizePixel = 0
    Frame.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 4)
    Corner.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Text = title
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 11
    Label.TextColor3 = Color3.fromRGB(220, 235, 225)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Size = UDim2.new(0, 110, 1, 0)
    Label.Position = UDim2.new(0, 8, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Parent = Frame

    local Box = Instance.new("TextBox")
    Box.Size = UDim2.new(1, -126, 0, 22)
    Box.Position = UDim2.new(0, 120, 0.5, -11)
    Box.BackgroundColor3 = Color3.fromRGB(12, 17, 14)
    Box.BorderSizePixel = 0
    Box.Font = Enum.Font.Gotham
    Box.TextSize = 11
    Box.TextColor3 = Color3.fromRGB(240, 255, 240)
    Box.PlaceholderText = placeholder
    Box.PlaceholderColor3 = Color3.fromRGB(90, 110, 95)
    Box.ClearTextOnFocus = false
    Box.Parent = Frame

    local BoxCorner = Instance.new("UICorner")
    BoxCorner.CornerRadius = UDim.new(0, 3)
    BoxCorner.Parent = Box

    Box.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            pcall(callback, Box.Text)
        end
    end)
end

-- ============================================================================
-- PÁGINAS Y CARGA DE FUNCIONALIDADES
-- ============================================================================

-- PESTAÑA 1: COMBATE & AIM
local combatPage = CreateTab("Combate", "⚔️")
CreateSection(combatPage, "Aimbot Camera Lock")
CreateToggle(combatPage, "Activar Aimbot (Mantener Click Derecho)", false, function(s) State.Aim.Aimbot = s end)
CreateToggle(combatPage, "Dibujar Circulo FOV", false, function(s) State.Aim.DrawFOV = s end)
CreateSlider(combatPage, "Radio FOV Aimbot", 40, 400, 120, function(v) State.Aim.AimbotFOV = v end)
CreateSlider(combatPage, "Suavizado (Smooth)", 1, 15, 5, function(v) State.Aim.AimbotSmooth = v end)
CreateToggle(combatPage, "Apuntar a la Cabeza (Off: Torso)", true, function(s) State.Aim.TargetPart = s and "Head" or "HumanoidRootPart" end)
CreateToggle(combatPage, "Verificar Muros (Wall Check)", false, function(s) State.Aim.WallCheck = s end)
CreateToggle(combatPage, "Ignorar Companeros (Team Check)", false, function(s) State.Aim.TeamCheck = s end)

CreateSection(combatPage, "Silent Aim & Disparo")
CreateToggle(combatPage, "Activar Silent Aim (Redireccion de Disparo)", false, function(s) State.Aim.SilentAim = s end)
CreateSlider(combatPage, "Radio FOV Silent Aim", 40, 500, 150, function(v) State.Aim.SilentAimFOV = v end)
CreateToggle(combatPage, "Triggerbot (Disparar al pasar la mira)", false, function(s) State.Aim.Triggerbot = s end)

CreateSection(combatPage, "Hitbox Expander (HBE)")
CreateToggle(combatPage, "Agrandar Hitbox de Enemigos", false, function(s) State.Aim.HBE = s end)
CreateSlider(combatPage, "Tamano de Hitbox", 4, 30, 12, function(v) State.Aim.HBESize = v end)

-- PESTAÑA 2: MOVIMIENTO
local movePage = CreateTab("Movimiento", "🏃")
CreateSection(movePage, "Velocidad y Salto")
CreateToggle(movePage, "Super Velocidad (WalkSpeed)", false, function(s)
    State.Movement.Speed = s
    if not s then local h = GetHumanoid() if h then h.WalkSpeed = 16 end end
end)
CreateSlider(movePage, "Valor de Velocidad", 16, 250, 40, function(v) State.Movement.SpeedVal = v end)
CreateToggle(movePage, "Super Salto (JumpPower)", false, function(s)
    State.Movement.Jump = s
    if not s then local h = GetHumanoid() if h then h.JumpPower = 50 end end
end)
CreateSlider(movePage, "Poder de Salto", 50, 350, 85, function(v) State.Movement.JumpVal = v end)
CreateToggle(movePage, "Salto Infinito", false, function(s) State.Movement.InfJump = s end)

CreateSection(movePage, "Vuelo y Paredes")
CreateToggle(movePage, "Vuelo Libre 6-DOF (WASD + Space/Ctrl)", false, function(s) SetFly(s) end)
CreateSlider(movePage, "Velocidad de Vuelo", 20, 200, 65, function(v) State.Movement.FlySpeed = v end)
CreateToggle(movePage, "Atravesar Paredes (Noclip)", false, function(s) State.Movement.Noclip = s end)

CreateSection(movePage, "Fisicas Especiales")
CreateSlider(movePage, "Gravedad del Mundo", 0, 196, 196, function(v) State.Movement.Gravity = v end)
CreateToggle(movePage, "Flotar en el Aire (HipHeight)", false, function(s)
    State.Movement.HipHeight = s
    if not s then local h = GetHumanoid() if h then h.HipHeight = 0 end end
end)
CreateSlider(movePage, "Altura de Flote", 1, 30, 4, function(v) State.Movement.HipHeightVal = v end)
CreateToggle(movePage, "Spinbot (Giro Rapido 360)", false, function(s) State.Movement.Spinbot = s end)

-- PESTAÑA 3: VISUALES
local visPage = CreateTab("Visuales", "👁️")
CreateSection(visPage, "Iluminacion")
CreateToggle(visPage, "Iluminacion Total (Fullbright)", false, function(s)
    State.Visuals.Fullbright = s
    if not s then
        Lighting.Ambient = origLighting.Ambient
        Lighting.Brightness = origLighting.Brightness
        Lighting.GlobalShadows = origLighting.GlobalShadows
    end
end)
CreateToggle(visPage, "Eliminar Niebla (No Fog)", false, function(s)
    State.Visuals.NoFog = s
    if not s then Lighting.FogEnd = origLighting.FogEnd end
end)
CreateSlider(visPage, "Campo de Vision (FOV)", 30, 120, 70, function(v) State.Visuals.FOV = v end)
CreateSlider(visPage, "Hora del Dia (Reloj)", 0, 24, 14, function(v) State.Visuals.ClockTime = v end)

-- PESTAÑA 4: ESP JUGADORES
local espPage = CreateTab("ESP Radar", "🎯")
CreateSection(espPage, "Visuales de Jugador")
CreateToggle(espPage, "Activar ESP Maestro", false, function(s) State.ESP.Master = s end)
CreateToggle(espPage, "Chams (Resaltado de Cuerpos)", true, function(s) State.ESP.Chams = s end)
CreateToggle(espPage, "Etiquetas de Nombre y Distancia", true, function(s) State.ESP.Names = s end)
CreateToggle(espPage, "Ignorar Companeros de Equipo", false, function(s) State.ESP.TeamCheck = s end)

-- PESTAÑA 5: TELETRANSPORTE
local tpPage = CreateTab("Teleport", "⚡")
CreateSection(tpPage, "Accesos Rapidos")
CreateToggle(tpPage, "Click Teleport (Ctrl + Click)", false, function(s) State.Teleport.ClickTP = s end)
CreateButton(tpPage, "Teletransportar al Enemigo Mas Cercano", function()
    local myHRP = GetHRP()
    if not myHRP then return end
    local target = GetClosestTarget(9999, "HumanoidRootPart", false, false)
    if target then
        myHRP.CFrame = target.CFrame + Vector3.new(0, 3.5, 0)
    end
end)
CreateButton(tpPage, "Escape de Emergencia (+100 Studs al Cielo)", function()
    local myHRP = GetHRP()
    if myHRP then myHRP.CFrame = myHRP.CFrame + Vector3.new(0, 100, 0) end
end)
CreateSection(tpPage, "Guardar Posicion")
CreateButton(tpPage, "Guardar Coordenadas Actuales", function()
    local myHRP = GetHRP()
    if myHRP then State.Teleport.SavedCFrame = myHRP.CFrame end
end)
CreateButton(tpPage, "Teletransportar a la Posicion Guardada", function()
    local myHRP = GetHRP()
    if myHRP and State.Teleport.SavedCFrame then
        myHRP.CFrame = State.Teleport.SavedCFrame
    end
end)
CreateInput(tpPage, "Ir a Jugador", "Escribe nombre...", function(name)
    local myHRP = GetHRP()
    if not myHRP then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if string.find(string.lower(p.Name), string.lower(name)) or string.find(string.lower(p.DisplayName), string.lower(name)) then
            local hrp = GetHRP(p)
            if hrp then
                myHRP.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
                break
            end
        end
    end
end)

-- PESTAÑA 6: EXPLOITS Y RAGE
local exploitPage = CreateTab("Exploits", "💀")
CreateSection(exploitPage, "Ventajas de Juego")
CreateToggle(exploitPage, "Fast Loot (ProximityPrompt a 0s)", false, function(s) State.Exploits.FastLoot = s end)
CreateToggle(exploitPage, "Congelar Personaje (Anti-Empuje)", false, function(s) State.Exploits.Freeze = s end)
CreateButton(exploitPage, "Volverse Headless (Cabeza Invisible)", function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Head") then
        char.Head.Transparency = 1
        if char.Head:FindFirstChild("face") then char.Head.face.Transparency = 1 end
    end
end)
CreateButton(exploitPage, "Equipar Korblox Derecho", function()
    local char = LocalPlayer.Character
    if char then
        if char:FindFirstChild("RightLowerLeg") then char.RightLowerLeg.Transparency = 1 end
        if char:FindFirstChild("RightFoot") then char.RightFoot.Transparency = 1 end
    end
end)
CreateButton(exploitPage, "Reset Instantaneo de Personaje", function()
    local hum = GetHumanoid()
    if hum then hum.Health = 0 end
end)

-- PESTAÑA 7: EJECUTOR IN-GAME & HUB
local execPage = CreateTab("Scripts", "📜")
CreateSection(execPage, "Script Hub 1-Click")
CreateButton(execPage, "Ejecutar Steal an Egg (Fn)", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/caomod2077/Script/refs/heads/main/Fn-stealanegg.lua"))()
end)
CreateButton(execPage, "Ejecutar Infinite Yield (Comandos Admin)", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end)
CreateButton(execPage, "Ejecutar Dex Explorer V4", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()
end)
CreateButton(execPage, "Ejecutar SimpleSpy V3 (Remote Spy)", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua"))()
end)
CreateButton(execPage, "Ejecutar Hydroxide", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Upbolt/Hydroxide/revision/init.lua"))()
end)

-- PESTAÑA 8: UTILIDADES
local utilPage = CreateTab("Utilidades", "🛠️")
CreateSection(utilPage, "Servidor")
CreateToggle(utilPage, "Anti-AFK (Evitar kick por inactividad)", true, function(s) State.Exploits.AntiAFK = s end)
CreateButton(utilPage, "Reconectar al Servidor Actual", function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)
CreateButton(utilPage, "Cambiar a Otro Servidor (Server Hop)", function()
    pcall(function()
        local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
        if servers and servers.data then
            for _, s in ipairs(servers.data) do
                if s.id ~= game.JobId and s.playing < s.maxPlayers then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                    break
                end
            end
        end
    end)
end)

print("[Koio Ultimate Hub] Cargado completamente con exito. Presiona RightShift o Insert para abrir/cerrar.")
