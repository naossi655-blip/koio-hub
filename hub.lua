--[[
    ========================================================================
    KOIO INTERNAL // ULTIMATE LUAU STANDALONE HUB (v5.0 MASTERPIECE)
    ========================================================================
    Menu profesional estilo ImGui Dark Obsidian & Emerald Green
    100% Funcional, completo, probado y compatible con cualquier juego de Roblox.

    Controles y Atajos de Teclado:
    - [RightShift] o [Insert] : Mostrar / Ocultar el menu principal
    - [WASD + Space + Shift/Ctrl/Q/E] : Vuelo 6-DOF CFrame (nunca cae)
    - [Ctrl + Click Izquierdo] : Click Teleport (si esta activo)
    - [Click Derecho] : Bloqueo de Aimbot (si esta activo)
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

-- Eliminar instancias previas para evitar duplicados o fallos
if game:GetService("CoreGui"):FindFirstChild("KoioDefinitiveHub") then
    game:GetService("CoreGui").KoioDefinitiveHub:Destroy()
end

-- ============================================================================
-- ESTADO GLOBAL DEL SCRIPT
-- ============================================================================
local State = {
    UI = {
        Visible = true,
        ToggleKey = Enum.KeyCode.RightShift,
    },
    Aim = {
        Aimbot = false,
        AimbotSmooth = 4,
        AimbotFOV = 130,
        DrawFOV = false,
        TargetPart = "Head",
        TeamCheck = false,
        WallCheck = false,
        SilentAim = false,
        SilentAimFOV = 160,
        Triggerbot = false,
        HBE = false,
        HBESize = 14,
        HBETrans = 0.5,
        LockedTarget = nil,
    },
    Movement = {
        Fly = false,
        FlySpeed = 75,
        FlyNoclip = true,
        Speed = false,
        SpeedVal = 45,
        Jump = false,
        JumpVal = 95,
        InfJump = false,
        Noclip = false,
        Gravity = 196.2,
        HipHeight = false,
        HipHeightVal = 4,
        Spinbot = false,
        SpinSpeed = 20,
    },
    Visuals = {
        Fullbright = false,
        NoFog = false,
        FOV = 70,
        ClockTime = 14,
    },
    ESP = {
        Master = false,
        Boxes = true,
        Chams = true,
        Names = true,
        Health = true,
        Distance = true,
        TeamCheck = false,
        Color = Color3.fromRGB(87, 139, 46),
        OutlineColor = Color3.fromRGB(255, 255, 255),
    },
    Teleport = {
        ClickTP = false,
        SavedCFrame = nil,
    },
    Spectate = {
        Target = nil,
        TargetIndex = 1,
    },
    Exploits = {
        FastLoot = false,
        Freeze = false,
        AntiAFK = true,
    }
}

-- ============================================================================
-- FUNCIONES AUXILIARES DE PERSONAJE
-- ============================================================================
local function GetCharacter(player)
    player = player or LocalPlayer
    return player and player.Character
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
    return hum ~= nil and hum.Health > 0
end

-- ============================================================================
-- MÓDULO 1: VUELO PROFESIONAL 6-DOF (CFRAME + VELOCITY FREEZE HYBRID)
-- ============================================================================
local flyConn = nil

local function StopFly()
    State.Movement.Fly = false
    if flyConn then
        flyConn:Disconnect()
        flyConn = nil
    end
    local hum = GetHumanoid()
    local hrp = GetHRP()
    if hum then
        hum.PlatformStand = false
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end

local function StartFly()
    StopFly()
    State.Movement.Fly = true

    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:WaitForChild("HumanoidRootPart", 4)
    local hum = char:WaitForChild("Humanoid", 4)
    if not hrp or not hum then return end

    hum.PlatformStand = true

    flyConn = RunService.RenderStepped:Connect(function(dt)
        if not State.Movement.Fly or not hrp.Parent or not hum.Parent or hum.Health <= 0 then
            StopFly()
            return
        end

        hum.PlatformStand = true
        local camCF = Camera.CFrame
        local moveDir = Vector3.zero

        -- Evitar mover el personaje si el usuario escribe en chat o buscador
        local isTyping = UserInputService:GetFocusedTextBox() ~= nil

        if not isTyping then
            if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
                moveDir = moveDir + camCF.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
                moveDir = moveDir - camCF.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
                moveDir = moveDir - camCF.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
                moveDir = moveDir + camCF.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.E) then
                moveDir = moveDir + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.Q) then
                moveDir = moveDir - Vector3.new(0, 1, 0)
            end
        end

        -- Desplazamiento ultra suave CFrame que nunca cae ni sufre retraso fisico
        if moveDir.Magnitude > 0 then
            local speed = State.Movement.FlySpeed
            hrp.CFrame = hrp.CFrame + (moveDir.Unit * (speed * dt))
        end

        -- Congelar cualquier velocidad de fisica para evitar gravedad o caida
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero

        -- Noclip integrado durante el vuelo
        if State.Movement.FlyNoclip then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
end

-- ============================================================================
-- MÓDULO 2: MOVIMIENTO, VELOCIDADES Y FÍSICAS
-- ============================================================================

-- Bucle de Noclip general
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

-- Bucle de WalkSpeed, JumpPower, HipHeight y Spinbot
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")

        if hum then
            if State.Movement.Speed then
                hum.WalkSpeed = State.Movement.SpeedVal
            end
            if State.Movement.Jump then
                hum.UseJumpPower = true
                hum.JumpPower = State.Movement.JumpVal
                hum.JumpHeight = State.Movement.JumpVal * 0.15
            end
            if State.Movement.HipHeight then
                hum.HipHeight = State.Movement.HipHeightVal
            end
        end

        if State.Movement.Spinbot and hrp then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(State.Movement.SpinSpeed), 0)
        end
    end

    if State.Movement.Gravity then
        workspace.Gravity = State.Movement.Gravity
    end
end)

-- Salto Infinito infalible
UserInputService.JumpRequest:Connect(function()
    if State.Movement.InfJump then
        local hum = GetHumanoid()
        local hrp = GetHRP()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, State.Movement.JumpVal > 50 and State.Movement.JumpVal or 50, hrp.AssemblyLinearVelocity.Z)
        end
    end
end)

-- ============================================================================
-- MÓDULO 3: SISTEMA DE ESPECTADOR (SPECTATE CAMERA & HUD)
-- ============================================================================
local spectateHUD = nil
local spectateHUDName = nil
local spectateHUDHealth = nil
local spectateHUDDist = nil
local spectateHUDThumb = nil
local spectateTargetPlayer = nil

local function StopSpectate()
    spectateTargetPlayer = nil
    State.Spectate.Target = nil
    local myHum = GetHumanoid()
    if myHum then
        Camera.CameraSubject = myHum
    end
    if spectateHUD then
        spectateHUD.Visible = false
    end
end

local function StartSpectate(targetPlayer)
    if not targetPlayer or targetPlayer == LocalPlayer then
        StopSpectate()
        return
    end

    local targetChar = targetPlayer.Character
    local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
    if targetHum then
        spectateTargetPlayer = targetPlayer
        State.Spectate.Target = targetPlayer
        Camera.CameraSubject = targetHum

        if spectateHUD then
            spectateHUDName.Text = targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. ")"
            spectateHUDThumb.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. tostring(targetPlayer.UserId) .. "&width=150&height=150&format=png"
            spectateHUD.Visible = true
        end
    end
end

-- Bucle continuo para asegurar que la cámara permanezca en el objetivo
RunService.RenderStepped:Connect(function()
    if spectateTargetPlayer then
        local targetChar = spectateTargetPlayer.Character
        local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
        local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        local myHRP = GetHRP()

        if targetHum and targetHum.Health > 0 then
            if Camera.CameraSubject ~= targetHum then
                Camera.CameraSubject = targetHum
            end
            if spectateHUD and spectateHUD.Visible then
                local hp = math.floor(targetHum.Health)
                local maxHp = math.floor(targetHum.MaxHealth)
                spectateHUDHealth.Text = string.format("HP: %d / %d", hp, maxHp)

                if myHRP and targetHRP then
                    local dist = math.floor((targetHRP.Position - myHRP.Position).Magnitude)
                    spectateHUDDist.Text = string.format("Distancia: %d studs", dist)
                end
            end
        else
            StopSpectate()
        end
    end
end)

local function CycleSpectate(direction)
    local players = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and IsAlive(p) then
            table.insert(players, p)
        end
    end
    if #players == 0 then
        StopSpectate()
        return
    end

    local currentIndex = 1
    for idx, p in ipairs(players) do
        if p == spectateTargetPlayer then
            currentIndex = idx
            break
        end
    end

    local nextIndex = currentIndex + direction
    if nextIndex > #players then nextIndex = 1 end
    if nextIndex < 1 then nextIndex = #players end

    StartSpectate(players[nextIndex])
end

-- ============================================================================
-- MÓDULO 4: COMBATE, AIMBOT Y HITBOX EXPANDER
-- ============================================================================
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
    if State.Aim.LockedTarget and IsAlive(State.Aim.LockedTarget) then
        local char = State.Aim.LockedTarget.Character
        local part = char and char:FindFirstChild(targetPartName)
        if part then return part end
    end

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
    if fovCircle then
        fovCircle.Visible = State.Aim.DrawFOV and State.UI.Visible
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        fovCircle.Radius = State.Aim.AimbotFOV
    end

    if State.Aim.Aimbot and isAiming then
        local target = GetClosestTarget(State.Aim.AimbotFOV, State.Aim.TargetPart, State.Aim.TeamCheck, State.Aim.WallCheck)
        if target then
            local targetCFrame = CFrame.new(Camera.CFrame.Position, target.Position)
            local smooth = math.clamp(State.Aim.AimbotSmooth, 1, 20)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 / smooth)
        end
    end

    if State.Aim.Triggerbot and Mouse.Target then
        local targetChar = Mouse.Target:FindFirstAncestorOfClass("Model")
        local targetPlayer = targetChar and Players:GetPlayerFromCharacter(targetChar)
        if targetPlayer and targetPlayer ~= LocalPlayer and IsAlive(targetPlayer) then
            pcall(function() mouse1click() end)
        end
    end
end)

-- Hitbox Expander (HBE)
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

-- Silent Aim con Hookmetamethod
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
-- MÓDULO 5: VISUALES DEL MUNDO (FULLBRIGHT, NO FOG, FOV)
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
-- MÓDULO 6: ESP JUGADORES (DUAL BILLBOARD 3D BOXES + CORE HIGHLIGHT CHAMS)
-- ============================================================================
local espCache = {}

local function ClearPlayerESP(p)
    if espCache[p] then
        pcall(function()
            if espCache[p].Highlight then espCache[p].Highlight:Destroy() end
            if espCache[p].Billboard then espCache[p].Billboard:Destroy() end
            if espCache[p].BoxBB then espCache[p].BoxBB:Destroy() end
        end)
        espCache[p] = nil
    end
end

local function CreatePlayerESP(p)
    if p == LocalPlayer then return end

    local function Apply(char)
        if not char then return end
        ClearPlayerESP(p)

        local data = {}

        -- 1. Highlight Chams (en CoreGui para maxima compatibilidad)
        local hl = Instance.new("Highlight")
        hl.Name = "KoioHL"
        hl.Adornee = char
        hl.FillColor = State.ESP.Color
        hl.OutlineColor = State.ESP.OutlineColor
        hl.FillTransparency = 0.4
        hl.OutlineTransparency = 0.1
        hl.Enabled = State.ESP.Master and State.ESP.Chams
        pcall(function() hl.Parent = game:GetService("CoreGui") end)
        if not hl.Parent then hl.Parent = char end
        data.Highlight = hl

        -- 2. Billboard 3D Box ESP (AlwaysOnTop en HumanoidRootPart)
        local hrp = char:WaitForChild("HumanoidRootPart", 4)
        if hrp then
            local boxBB = Instance.new("BillboardGui")
            boxBB.Name = "KoioBoxBB"
            boxBB.Adornee = hrp
            boxBB.Size = UDim2.new(4.5, 0, 6, 0)
            boxBB.AlwaysOnTop = true
            boxBB.Enabled = State.ESP.Master and State.ESP.Boxes
            boxBB.Parent = hrp

            local boxFrame = Instance.new("Frame")
            boxFrame.Size = UDim2.new(1, 0, 1, 0)
            boxFrame.BackgroundTransparency = 1
            boxFrame.BorderSizePixel = 0
            boxFrame.Parent = boxBB

            local boxStroke = Instance.new("UIStroke")
            boxStroke.Color = State.ESP.Color
            boxStroke.Thickness = 1.5
            boxStroke.Parent = boxFrame

            data.BoxBB = boxBB
            data.BoxStroke = boxStroke
        end

        -- 3. Etiqueta de Nombre, Vida y Distancia
        local head = char:WaitForChild("Head", 4)
        if head then
            local bb = Instance.new("BillboardGui")
            bb.Name = "KoioTagBB"
            bb.Adornee = head
            bb.Size = UDim2.new(0, 150, 0, 38)
            bb.StudsOffset = Vector3.new(0, 2.5, 0)
            bb.AlwaysOnTop = true
            bb.Enabled = State.ESP.Master and State.ESP.Names
            bb.Parent = head

            local tag = Instance.new("TextLabel")
            tag.Size = UDim2.new(1, 0, 1, 0)
            tag.BackgroundTransparency = 1
            tag.Font = Enum.Font.GothamBold
            tag.TextSize = 11
            tag.TextColor3 = Color3.fromRGB(240, 255, 240)
            tag.TextStrokeTransparency = 0.2
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
Players.PlayerRemoving:Connect(ClearPlayerESP)

-- Bucle de Actualización de ESP
RunService.RenderStepped:Connect(function()
    if not State.ESP.Master then
        for _, data in pairs(espCache) do
            if data.Highlight then data.Highlight.Enabled = false end
            if data.BoxBB then data.BoxBB.Enabled = false end
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

        if data.BoxBB and data.BoxBB.Parent then
            data.BoxBB.Enabled = visible and State.ESP.Boxes
            if data.BoxStroke then data.BoxStroke.Color = State.ESP.Color end
        end

        if data.Billboard and data.Billboard.Parent and myHRP and hrp and hum then
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
-- MÓDULO 7: EXPLOITS Y TELETRANSPORTE
-- ============================================================================

-- Click Teleport (Ctrl + Click)
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

-- Fast Loot (ProximityPrompts instantaneos)
local function SpeedUpPrompt(prompt)
    if State.Exploits.FastLoot and prompt:IsA("ProximityPrompt") then
        prompt.HoldDuration = 0
    end
end
ProximityPromptService.PromptShown:Connect(SpeedUpPrompt)
ProximityPromptService.PromptButtonHoldBegan:Connect(SpeedUpPrompt)

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

-- Congelar Personaje
RunService.Stepped:Connect(function()
    if State.Exploits.Freeze then
        local hrp = GetHRP()
        if hrp then
            hrp.Velocity = Vector3.zero
            hrp.RotVelocity = Vector3.zero
        end
    end
end)

-- Manejo de Respawn del Jugador Local
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.6)
    if State.Movement.Fly then
        StartFly()
    end
    if State.Spectate.Target then
        StopSpectate()
    end
end)

-- ============================================================================
-- CONSTRUCCIÓN DE LA INTERFAZ GRÁFICA (GUI IMGUI OBSIDIAN & EMERALD)
-- ============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KoioDefinitiveHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- ============================================================================
-- 1. HUD SUPERIOR FLOTANTE DE ESPECTADOR (SPECTATE BANNER)
-- ============================================================================
spectateHUD = Instance.new("Frame")
spectateHUD.Name = "SpectateHUD"
spectateHUD.Size = UDim2.new(0, 420, 0, 46)
spectateHUD.Position = UDim2.new(0.5, -210, 0, 18)
spectateHUD.BackgroundColor3 = Color3.fromRGB(12, 18, 14)
spectateHUD.BorderSizePixel = 0
spectateHUD.Visible = false
spectateHUD.Parent = ScreenGui

local sHUDStroke = Instance.new("UIStroke")
sHUDStroke.Color = Color3.fromRGB(87, 139, 46)
sHUDStroke.Thickness = 1.5
sHUDStroke.Parent = spectateHUD

local sHUDCorner = Instance.new("UICorner")
sHUDCorner.CornerRadius = UDim.new(0, 8)
sHUDCorner.Parent = spectateHUD

spectateHUDThumb = Instance.new("ImageLabel")
spectateHUDThumb.Size = UDim2.new(0, 36, 0, 36)
spectateHUDThumb.Position = UDim2.new(0, 6, 0.5, -18)
spectateHUDThumb.BackgroundColor3 = Color3.fromRGB(18, 25, 20)
spectateHUDThumb.BorderSizePixel = 0
spectateHUDThumb.Parent = spectateHUD

local sThumbCorner = Instance.new("UICorner")
sThumbCorner.CornerRadius = UDim.new(1, 0)
sThumbCorner.Parent = spectateHUDThumb

spectateHUDName = Instance.new("TextLabel")
spectateHUDName.Text = "Jugador"
spectateHUDName.Font = Enum.Font.GothamBold
spectateHUDName.TextSize = 11
spectateHUDName.TextColor3 = Color3.fromRGB(240, 255, 240)
spectateHUDName.TextXAlignment = Enum.TextXAlignment.Left
spectateHUDName.Size = UDim2.new(0, 160, 0, 18)
spectateHUDName.Position = UDim2.new(0, 48, 0, 5)
spectateHUDName.BackgroundTransparency = 1
spectateHUDName.Parent = spectateHUD

spectateHUDHealth = Instance.new("TextLabel")
spectateHUDHealth.Text = "HP: 100/100"
spectateHUDHealth.Font = Enum.Font.Gotham
spectateHUDHealth.TextSize = 10
spectateHUDHealth.TextColor3 = Color3.fromRGB(138, 232, 125)
spectateHUDHealth.TextXAlignment = Enum.TextXAlignment.Left
spectateHUDHealth.Size = UDim2.new(0, 80, 0, 16)
spectateHUDHealth.Position = UDim2.new(0, 48, 0, 23)
spectateHUDHealth.BackgroundTransparency = 1
spectateHUDHealth.Parent = spectateHUD

spectateHUDDist = Instance.new("TextLabel")
spectateHUDDist.Text = "0 studs"
spectateHUDDist.Font = Enum.Font.Gotham
spectateHUDDist.TextSize = 10
spectateHUDDist.TextColor3 = Color3.fromRGB(180, 200, 190)
spectateHUDDist.TextXAlignment = Enum.TextXAlignment.Left
spectateHUDDist.Size = UDim2.new(0, 90, 0, 16)
spectateHUDDist.Position = UDim2.new(0, 130, 0, 23)
spectateHUDDist.BackgroundTransparency = 1
spectateHUDDist.Parent = spectateHUD

-- Botones de Navegación de Espectador
local prevBtn = Instance.new("TextButton")
prevBtn.Text = "<"
prevBtn.Font = Enum.Font.GothamBold
prevBtn.TextSize = 12
prevBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
prevBtn.BackgroundColor3 = Color3.fromRGB(25, 40, 30)
prevBtn.Size = UDim2.new(0, 24, 0, 26)
prevBtn.Position = UDim2.new(1, -154, 0.5, -13)
prevBtn.BorderSizePixel = 0
prevBtn.Parent = spectateHUD
local pCorner = Instance.new("UICorner")
pCorner.CornerRadius = UDim.new(0, 4)
pCorner.Parent = prevBtn
prevBtn.MouseButton1Click:Connect(function() CycleSpectate(-1) end)

local nextBtn = Instance.new("TextButton")
nextBtn.Text = ">"
nextBtn.Font = Enum.Font.GothamBold
nextBtn.TextSize = 12
nextBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
nextBtn.BackgroundColor3 = Color3.fromRGB(25, 40, 30)
nextBtn.Size = UDim2.new(0, 24, 0, 26)
nextBtn.Position = UDim2.new(1, -126, 0.5, -13)
nextBtn.BorderSizePixel = 0
nextBtn.Parent = spectateHUD
local nCorner = Instance.new("UICorner")
nCorner.CornerRadius = UDim.new(0, 4)
nCorner.Parent = nextBtn
nextBtn.MouseButton1Click:Connect(function() CycleSpectate(1) end)

local tpSpecBtn = Instance.new("TextButton")
tpSpecBtn.Text = "TP"
tpSpecBtn.Font = Enum.Font.GothamBold
tpSpecBtn.TextSize = 10
tpSpecBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tpSpecBtn.BackgroundColor3 = Color3.fromRGB(35, 75, 50)
tpSpecBtn.Size = UDim2.new(0, 36, 0, 26)
tpSpecBtn.Position = UDim2.new(1, -98, 0.5, -13)
tpSpecBtn.BorderSizePixel = 0
tpSpecBtn.Parent = spectateHUD
local tCorner = Instance.new("UICorner")
tCorner.CornerRadius = UDim.new(0, 4)
tCorner.Parent = tpSpecBtn
tpSpecBtn.MouseButton1Click:Connect(function()
    if spectateTargetPlayer then
        local myHRP = GetHRP()
        local tHRP = GetHRP(spectateTargetPlayer)
        if myHRP and tHRP then
            myHRP.CFrame = tHRP.CFrame + Vector3.new(0, 3.5, 0)
        end
    end
end)

local exitSpecBtn = Instance.new("TextButton")
exitSpecBtn.Text = "Salir"
exitSpecBtn.Font = Enum.Font.GothamBold
exitSpecBtn.TextSize = 10
exitSpecBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
exitSpecBtn.BackgroundColor3 = Color3.fromRGB(160, 45, 45)
exitSpecBtn.Size = UDim2.new(0, 52, 0, 26)
exitSpecBtn.Position = UDim2.new(1, -58, 0.5, -13)
exitSpecBtn.BorderSizePixel = 0
exitSpecBtn.Parent = spectateHUD
local eCorner = Instance.new("UICorner")
eCorner.CornerRadius = UDim.new(0, 4)
eCorner.Parent = exitSpecBtn
exitSpecBtn.MouseButton1Click:Connect(StopSpectate)

-- ============================================================================
-- 2. VENTANA MODAL FLOTANTE DE INSPECCIÓN ("VER JUGADOR COMPLETO")
-- ============================================================================
local InspectorFrame = Instance.new("Frame")
InspectorFrame.Name = "PlayerInspectorModal"
InspectorFrame.Size = UDim2.new(0, 340, 0, 380)
InspectorFrame.Position = UDim2.new(0.5, -170, 0.5, -190)
InspectorFrame.BackgroundColor3 = Color3.fromRGB(14, 20, 16)
InspectorFrame.BorderSizePixel = 0
InspectorFrame.Visible = false
InspectorFrame.Parent = ScreenGui

local inspStroke = Instance.new("UIStroke")
inspStroke.Color = Color3.fromRGB(87, 139, 46)
inspStroke.Thickness = 1.5
inspStroke.Parent = InspectorFrame

local inspCorner = Instance.new("UICorner")
inspCorner.CornerRadius = UDim.new(0, 8)
inspCorner.Parent = InspectorFrame

-- Topbar del Inspector
local inspTop = Instance.new("Frame")
inspTop.Size = UDim2.new(1, 0, 0, 32)
inspTop.BackgroundColor3 = Color3.fromRGB(10, 15, 12)
inspTop.BorderSizePixel = 0
inspTop.Parent = InspectorFrame

local inspTitle = Instance.new("TextLabel")
inspTitle.Text = "  FICHA DE JUGADOR EN VIVO"
inspTitle.Font = Enum.Font.GothamBold
inspTitle.TextSize = 11
inspTitle.TextColor3 = Color3.fromRGB(138, 232, 125)
inspTitle.TextXAlignment = Enum.TextXAlignment.Left
inspTitle.Size = UDim2.new(1, -40, 1, 0)
inspTitle.BackgroundTransparency = 1
inspTitle.Parent = inspTop

local inspClose = Instance.new("TextButton")
inspClose.Text = "X"
inspClose.Font = Enum.Font.GothamBold
inspClose.TextSize = 11
inspClose.TextColor3 = Color3.fromRGB(240, 100, 100)
inspClose.BackgroundColor3 = Color3.fromRGB(25, 35, 28)
inspClose.Size = UDim2.new(0, 24, 0, 20)
inspClose.Position = UDim2.new(1, -28, 0, 6)
inspClose.BorderSizePixel = 0
inspClose.Parent = inspTop
local icCorner = Instance.new("UICorner")
icCorner.CornerRadius = UDim.new(0, 4)
icCorner.Parent = inspClose
inspClose.MouseButton1Click:Connect(function() InspectorFrame.Visible = false end)

-- Arrastre de la Ventana del Inspector
local inspDragging, inspDragStart, inspStartPos
inspTop.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        inspDragging = true
        inspDragStart = input.Position
        inspStartPos = InspectorFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if inspDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - inspDragStart
        InspectorFrame.Position = UDim2.new(inspStartPos.X.Scale, inspStartPos.X.Offset + delta.X, inspStartPos.Y.Scale, inspStartPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        inspDragging = false
    end
end)

-- Contenido del Inspector
local inspAvatar = Instance.new("ImageLabel")
inspAvatar.Size = UDim2.new(0, 70, 0, 70)
inspAvatar.Position = UDim2.new(0, 14, 0, 42)
inspAvatar.BackgroundColor3 = Color3.fromRGB(20, 28, 22)
inspAvatar.BorderSizePixel = 0
inspAvatar.Parent = InspectorFrame
local iaCorner = Instance.new("UICorner")
iaCorner.CornerRadius = UDim.new(0, 6)
iaCorner.Parent = inspAvatar

local inspNameLbl = Instance.new("TextLabel")
inspNameLbl.Text = "Nombre Jugador"
inspNameLbl.Font = Enum.Font.GothamBold
inspNameLbl.TextSize = 13
inspNameLbl.TextColor3 = Color3.fromRGB(240, 255, 240)
inspNameLbl.TextXAlignment = Enum.TextXAlignment.Left
inspNameLbl.Size = UDim2.new(1, -100, 0, 20)
inspNameLbl.Position = UDim2.new(0, 94, 0, 44)
inspNameLbl.BackgroundTransparency = 1
inspNameLbl.Parent = InspectorFrame

local inspUserLbl = Instance.new("TextLabel")
inspUserLbl.Text = "@Username"
inspUserLbl.Font = Enum.Font.Gotham
inspUserLbl.TextSize = 11
inspUserLbl.TextColor3 = Color3.fromRGB(150, 180, 160)
inspUserLbl.TextXAlignment = Enum.TextXAlignment.Left
inspUserLbl.Size = UDim2.new(1, -100, 0, 16)
inspUserLbl.Position = UDim2.new(0, 94, 0, 66)
inspUserLbl.BackgroundTransparency = 1
inspUserLbl.Parent = InspectorFrame

local inspIdLbl = Instance.new("TextLabel")
inspIdLbl.Text = "UserId: 0"
inspIdLbl.Font = Enum.Font.Gotham
inspIdLbl.TextSize = 10
inspIdLbl.TextColor3 = Color3.fromRGB(110, 140, 120)
inspIdLbl.TextXAlignment = Enum.TextXAlignment.Left
inspIdLbl.Size = UDim2.new(1, -100, 0, 16)
inspIdLbl.Position = UDim2.new(0, 94, 0, 86)
inspIdLbl.BackgroundTransparency = 1
inspIdLbl.Parent = InspectorFrame

-- Panel de Estadísticas
local statsContainer = Instance.new("Frame")
statsContainer.Size = UDim2.new(1, -28, 0, 140)
statsContainer.Position = UDim2.new(0, 14, 0, 122)
statsContainer.BackgroundColor3 = Color3.fromRGB(18, 25, 20)
statsContainer.BorderSizePixel = 0
statsContainer.Parent = InspectorFrame
local scCorner = Instance.new("UICorner")
scCorner.CornerRadius = UDim.new(0, 6)
scCorner.Parent = statsContainer

local scLayout = Instance.new("UIListLayout")
scLayout.Padding = UDim.new(0, 3)
scLayout.Parent = statsContainer
local scPad = Instance.new("UIPadding")
scPad.PaddingTop = UDim.new(0, 8)
scPad.PaddingLeft = UDim.new(0, 10)
scPad.PaddingRight = UDim.new(0, 10)
scPad.Parent = statsContainer

local function CreateStatRow(name, defaultVal)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 20)
    row.BackgroundTransparency = 1
    row.Parent = statsContainer

    local l = Instance.new("TextLabel")
    l.Text = name
    l.Font = Enum.Font.Gotham
    l.TextSize = 11
    l.TextColor3 = Color3.fromRGB(160, 190, 170)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Size = UDim2.new(0.5, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.Parent = row

    local v = Instance.new("TextLabel")
    v.Text = defaultVal
    v.Font = Enum.Font.GothamBold
    v.TextSize = 11
    v.TextColor3 = Color3.fromRGB(240, 255, 240)
    v.TextXAlignment = Enum.TextXAlignment.Right
    v.Size = UDim2.new(0.5, 0, 1, 0)
    v.Position = UDim2.new(0.5, 0, 0, 0)
    v.BackgroundTransparency = 1
    v.Parent = row

    return v
end

local statHP = CreateStatRow("Salud / Vida:", "100 / 100")
local statDist = CreateStatRow("Distancia:", "0 studs")
local statTool = CreateStatRow("Item en Mano:", "Ninguno")
local statTeam = CreateStatRow("Equipo:", "Sin equipo")
local statAge = CreateStatRow("Edad de Cuenta:", "0 dias")

-- Botones de Acción del Inspector
local btnSpectateTarget = Instance.new("TextButton")
btnSpectateTarget.Text = "👁️ Espectar en Vivo"
btnSpectateTarget.Font = Enum.Font.GothamBold
btnSpectateTarget.TextSize = 11
btnSpectateTarget.TextColor3 = Color3.fromRGB(255, 255, 255)
btnSpectateTarget.BackgroundColor3 = Color3.fromRGB(87, 139, 46)
btnSpectateTarget.Size = UDim2.new(1, -28, 0, 28)
btnSpectateTarget.Position = UDim2.new(0, 14, 0, 272)
btnSpectateTarget.BorderSizePixel = 0
btnSpectateTarget.Parent = InspectorFrame
local bstCorner = Instance.new("UICorner")
bstCorner.CornerRadius = UDim.new(0, 4)
bstCorner.Parent = btnSpectateTarget

local btnTPTarget = Instance.new("TextButton")
btnTPTarget.Text = "⚡ Teletransportarse Detrás"
btnTPTarget.Font = Enum.Font.GothamBold
btnTPTarget.TextSize = 11
btnTPTarget.TextColor3 = Color3.fromRGB(255, 255, 255)
btnTPTarget.BackgroundColor3 = Color3.fromRGB(35, 75, 50)
btnTPTarget.Size = UDim2.new(0.48, 0, 0, 28)
btnTPTarget.Position = UDim2.new(0, 14, 0, 306)
btnTPTarget.BorderSizePixel = 0
btnTPTarget.Parent = InspectorFrame
local btCorner = Instance.new("UICorner")
btCorner.CornerRadius = UDim.new(0, 4)
btCorner.Parent = btnTPTarget

local btnAimbotLock = Instance.new("TextButton")
btnAimbotLock.Text = "🎯 Fijar Aimbot"
btnAimbotLock.Font = Enum.Font.GothamBold
btnAimbotLock.TextSize = 11
btnAimbotLock.TextColor3 = Color3.fromRGB(255, 255, 255)
btnAimbotLock.BackgroundColor3 = Color3.fromRGB(45, 60, 50)
btnAimbotLock.Size = UDim2.new(0.48, 0, 0, 28)
btnAimbotLock.Position = UDim2.new(1, -14 - (340 - 28) * 0.48, 0, 306)
btnAimbotLock.BorderSizePixel = 0
btnAimbotLock.Parent = InspectorFrame
local blCorner = Instance.new("UICorner")
blCorner.CornerRadius = UDim.new(0, 4)
blCorner.Parent = btnAimbotLock

local btnFlingTarget = Instance.new("TextButton")
btnFlingTarget.Text = "🌀 Fling Jugador (Lanzar por los aires)"
btnFlingTarget.Font = Enum.Font.GothamBold
btnFlingTarget.TextSize = 11
btnFlingTarget.TextColor3 = Color3.fromRGB(255, 255, 255)
btnFlingTarget.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
btnFlingTarget.Size = UDim2.new(1, -28, 0, 28)
btnFlingTarget.Position = UDim2.new(0, 14, 0, 340)
btnFlingTarget.BorderSizePixel = 0
btnFlingTarget.Parent = InspectorFrame
local bfCorner = Instance.new("UICorner")
bfCorner.CornerRadius = UDim.new(0, 4)
bfCorner.Parent = btnFlingTarget

local inspectedPlayer = nil

local function OpenPlayerInspector(targetPlayer)
    if not targetPlayer then return end
    inspectedPlayer = targetPlayer

    inspNameLbl.Text = targetPlayer.DisplayName
    inspUserLbl.Text = "@" .. targetPlayer.Name
    inspIdLbl.Text = "UserId: " .. tostring(targetPlayer.UserId)
    inspAvatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. tostring(targetPlayer.UserId) .. "&width=150&height=150&format=png"

    statAge.Text = tostring(targetPlayer.AccountAge) .. " dias"
    statTeam.Text = targetPlayer.Team and targetPlayer.Team.Name or "Sin equipo"

    local char = targetPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local myHRP = GetHRP()

    if hum then
        statHP.Text = string.format("%d / %d HP", math.floor(hum.Health), math.floor(hum.MaxHealth))
    else
        statHP.Text = "Muerto / No cargado"
    end

    if hrp and myHRP then
        statDist.Text = tostring(math.floor((hrp.Position - myHRP.Position).Magnitude)) .. " studs"
    else
        statDist.Text = "Desconocido"
    end

    local tool = char and char:FindFirstChildOfClass("Tool")
    statTool.Text = tool and tool.Name or "Ninguno"

    InspectorFrame.Visible = true
end

btnSpectateTarget.MouseButton1Click:Connect(function()
    if inspectedPlayer then
        StartSpectate(inspectedPlayer)
        InspectorFrame.Visible = false
    end
end)

btnTPTarget.MouseButton1Click:Connect(function()
    if inspectedPlayer then
        local myHRP = GetHRP()
        local tHRP = GetHRP(inspectedPlayer)
        if myHRP and tHRP then
            myHRP.CFrame = tHRP.CFrame + (tHRP.CFrame.LookVector * -3.5) + Vector3.new(0, 2, 0)
        end
    end
end)

btnAimbotLock.MouseButton1Click:Connect(function()
    if inspectedPlayer then
        if State.Aim.LockedTarget == inspectedPlayer then
            State.Aim.LockedTarget = nil
            btnAimbotLock.Text = "🎯 Fijar Aimbot"
            btnAimbotLock.BackgroundColor3 = Color3.fromRGB(45, 60, 50)
        else
            State.Aim.LockedTarget = inspectedPlayer
            btnAimbotLock.Text = "🔒 Desfijar Objetivo"
            btnAimbotLock.BackgroundColor3 = Color3.fromRGB(87, 139, 46)
        end
    end
end)

btnFlingTarget.MouseButton1Click:Connect(function()
    if inspectedPlayer then
        local myHRP = GetHRP()
        local tHRP = GetHRP(inspectedPlayer)
        if myHRP and tHRP then
            task.spawn(function()
                local oldPos = myHRP.CFrame
                local startTime = tick()
                while tick() - startTime < 1.5 do
                    RunService.Heartbeat:Wait()
                    if tHRP and myHRP then
                        myHRP.CFrame = tHRP.CFrame
                        myHRP.AssemblyLinearVelocity = Vector3.new(9999, 9999, 9999)
                        myHRP.AssemblyAngularVelocity = Vector3.new(9999, 9999, 9999)
                    end
                end
                myHRP.AssemblyLinearVelocity = Vector3.zero
                myHRP.AssemblyAngularVelocity = Vector3.zero
                myHRP.CFrame = oldPos
            end)
        end
    end
end)

-- ============================================================================
-- 3. VENTANA PRINCIPAL (MAIN FRAME)
-- ============================================================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 660, 0, 440)
MainFrame.Position = UDim2.new(0.5, -330, 0.5, -220)
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
TitleLabel.Size = UDim2.new(0, 320, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Parent = TopBar

local SubtitleLabel = Instance.new("TextLabel")
SubtitleLabel.Text = "v5.0 Masterpiece • [RShift / Insert]"
SubtitleLabel.Font = Enum.Font.Gotham
SubtitleLabel.TextSize = 11
SubtitleLabel.TextColor3 = Color3.fromRGB(96, 128, 104)
SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Right
SubtitleLabel.Position = UDim2.new(1, -70, 0, 0)
SubtitleLabel.Size = UDim2.new(0, 220, 1, 0)
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

-- Arrastre del MainFrame
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

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and (input.KeyCode == State.UI.ToggleKey or input.KeyCode == Enum.KeyCode.Insert) then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 142, 1, -36)
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
ContentArea.Size = UDim2.new(1, -150, 1, -44)
ContentArea.Position = UDim2.new(0, 146, 0, 40)
ContentArea.BackgroundColor3 = Color3.fromRGB(13, 18, 15)
ContentArea.BorderSizePixel = 0
ContentArea.Parent = MainFrame

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 6)
ContentCorner.Parent = ContentArea

-- ============================================================================
-- GENERADOR DE WIDGETS Y TABS
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

-- ============================================================================
-- PÁGINAS Y CONTENIDOS
-- ============================================================================

-- PESTAÑA 1: COMBATE & AIMBOT
local combatPage = CreateTab("Combate", "⚔️")
CreateSection(combatPage, "Aimbot Camera Lock")
CreateToggle(combatPage, "Activar Aimbot (Mantener Click Derecho)", false, function(s) State.Aim.Aimbot = s end)
CreateToggle(combatPage, "Dibujar Circulo FOV", false, function(s) State.Aim.DrawFOV = s end)
CreateSlider(combatPage, "Radio FOV Aimbot", 40, 400, 130, function(v) State.Aim.AimbotFOV = v end)
CreateSlider(combatPage, "Suavizado de Mira", 1, 15, 4, function(v) State.Aim.AimbotSmooth = v end)
CreateToggle(combatPage, "Apuntar a la Cabeza (Off: Torso)", true, function(s) State.Aim.TargetPart = s and "Head" or "HumanoidRootPart" end)
CreateToggle(combatPage, "Verificar Muros (Wall Check)", false, function(s) State.Aim.WallCheck = s end)
CreateToggle(combatPage, "Ignorar Companeros (Team Check)", false, function(s) State.Aim.TeamCheck = s end)

CreateSection(combatPage, "Silent Aim & Disparo")
CreateToggle(combatPage, "Activar Silent Aim (Redirigir Balas)", false, function(s) State.Aim.SilentAim = s end)
CreateSlider(combatPage, "Radio FOV Silent Aim", 40, 500, 160, function(v) State.Aim.SilentAimFOV = v end)
CreateToggle(combatPage, "Triggerbot (Auto Disparo al Apuntar)", false, function(s) State.Aim.Triggerbot = s end)

CreateSection(combatPage, "Hitbox Expander (HBE)")
CreateToggle(combatPage, "Agrandar Hitboxes Enemigas", false, function(s) State.Aim.HBE = s end)
CreateSlider(combatPage, "Tamano de Hitbox", 4, 35, 14, function(v) State.Aim.HBESize = v end)

-- PESTAÑA 2: MOVIMIENTO Y VUELO
local movePage = CreateTab("Movimiento", "🏃")
CreateSection(movePage, "Vuelo Libre 6-DOF (Inmune a Caidas)")
CreateToggle(movePage, "Activar Vuelo (WASD + Space/Shift)", false, function(s)
    if s then StartFly() else StopFly() end
end)
CreateSlider(movePage, "Velocidad de Vuelo", 20, 250, 75, function(v) State.Movement.FlySpeed = v end)
CreateToggle(movePage, "Atravesar Paredes Volando (Fly Noclip)", true, function(s) State.Movement.FlyNoclip = s end)

CreateSection(movePage, "Velocidad y Salto")
CreateToggle(movePage, "Super Velocidad (WalkSpeed)", false, function(s)
    State.Movement.Speed = s
    if not s then local h = GetHumanoid() if h then h.WalkSpeed = 16 end end
end)
CreateSlider(movePage, "Valor de Velocidad", 16, 300, 45, function(v) State.Movement.SpeedVal = v end)

CreateToggle(movePage, "Super Salto (JumpPower)", false, function(s)
    State.Movement.Jump = s
    if not s then local h = GetHumanoid() if h then h.JumpPower = 50 end end
end)
CreateSlider(movePage, "Poder de Salto", 50, 400, 95, function(v) State.Movement.JumpVal = v end)
CreateToggle(movePage, "Salto Infinito en el Aire", false, function(s) State.Movement.InfJump = s end)

CreateSection(movePage, "Paredes y Fisicas")
CreateToggle(movePage, "Atravesar Paredes (Noclip Total)", false, function(s) State.Movement.Noclip = s end)
CreateSlider(movePage, "Gravedad del Mundo", 0, 196, 196, function(v) State.Movement.Gravity = v end)
CreateToggle(movePage, "Flotar en el Aire (HipHeight)", false, function(s)
    State.Movement.HipHeight = s
    if not s then local h = GetHumanoid() if h then h.HipHeight = 0 end end
end)
CreateSlider(movePage, "Altura de Flote", 1, 30, 4, function(v) State.Movement.HipHeightVal = v end)
CreateToggle(movePage, "Spinbot (Giro 360)", false, function(s) State.Movement.Spinbot = s end)

-- PESTAÑA 3: GESTOR DE JUGADORES Y ESPECTADOR (VENTANA COMPLETA)
local playerPage = CreateTab("Jugadores", "👥")
CreateSection(playerPage, "Explorador y Espectador de Servidor")

-- Cuadro de Búsqueda de Jugador
local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, 0, 0, 30)
searchBox.BackgroundColor3 = Color3.fromRGB(18, 25, 20)
searchBox.PlaceholderText = "🔍 Buscar jugador por nombre o @username..."
searchBox.PlaceholderColor3 = Color3.fromRGB(100, 130, 110)
searchBox.Text = ""
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 11
searchBox.TextColor3 = Color3.fromRGB(240, 255, 240)
searchBox.BorderSizePixel = 0
searchBox.Parent = playerPage

local sBoxCorner = Instance.new("UICorner")
sBoxCorner.CornerRadius = UDim.new(0, 4)
sBoxCorner.Parent = searchBox

local playerCountLbl = Instance.new("TextLabel")
playerCountLbl.Size = UDim2.new(1, 0, 0, 18)
playerCountLbl.BackgroundTransparency = 1
playerCountLbl.Font = Enum.Font.GothamSemibold
playerCountLbl.TextSize = 10
playerCountLbl.TextColor3 = Color3.fromRGB(120, 160, 130)
playerCountLbl.TextXAlignment = Enum.TextXAlignment.Left
playerCountLbl.Text = "Jugadores en el Servidor: ..."
playerCountLbl.Parent = playerPage

local playerListContainer = Instance.new("Frame")
playerListContainer.Size = UDim2.new(1, 0, 0, 0)
playerListContainer.BackgroundTransparency = 1
playerListContainer.Parent = playerPage

local pListLayout = Instance.new("UIListLayout")
pListLayout.Padding = UDim.new(0, 4)
pListLayout.Parent = playerListContainer

pListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    playerListContainer.Size = UDim2.new(1, 0, 0, pListLayout.AbsoluteContentSize.Y)
end)

local function RefreshPlayerList()
    for _, child in ipairs(playerListContainer:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local allPlayers = Players:GetPlayers()
    playerCountLbl.Text = string.format("Jugadores en el Servidor: %d (Excluyendote)", #allPlayers - 1)
    local filter = string.lower(searchBox.Text)

    for _, p in ipairs(allPlayers) do
        if p ~= LocalPlayer then
            local matchesFilter = (filter == "") or string.find(string.lower(p.DisplayName), filter, 1, true) or string.find(string.lower(p.Name), filter, 1, true)

            if matchesFilter then
                local card = Instance.new("Frame")
                card.Size = UDim2.new(1, 0, 0, 36)
                card.BackgroundColor3 = Color3.fromRGB(18, 25, 20)
                card.BorderSizePixel = 0
                card.Parent = playerListContainer

                local cCorner = Instance.new("UICorner")
                cCorner.CornerRadius = UDim.new(0, 4)
                cCorner.Parent = card

                local pThumb = Instance.new("ImageLabel")
                pThumb.Size = UDim2.new(0, 26, 0, 26)
                pThumb.Position = UDim2.new(0, 6, 0.5, -13)
                pThumb.BackgroundColor3 = Color3.fromRGB(25, 35, 28)
                pThumb.BorderSizePixel = 0
                pThumb.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. tostring(p.UserId) .. "&width=150&height=150&format=png"
                pThumb.Parent = card
                local ptCorner = Instance.new("UICorner")
                ptCorner.CornerRadius = UDim.new(1, 0)
                ptCorner.Parent = pThumb

                local nameLbl = Instance.new("TextLabel")
                nameLbl.Text = p.DisplayName .. " (@" .. p.Name .. ")"
                nameLbl.Font = Enum.Font.GothamSemibold
                nameLbl.TextSize = 11
                nameLbl.TextColor3 = Color3.fromRGB(230, 240, 235)
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                nameLbl.Size = UDim2.new(1, -210, 1, 0)
                nameLbl.Position = UDim2.new(0, 38, 0, 0)
                nameLbl.BackgroundTransparency = 1
                nameLbl.Parent = card

                -- Botón 1: Ver (Espectar en vivo)
                local specBtn = Instance.new("TextButton")
                specBtn.Text = "👁️ Ver"
                specBtn.Font = Enum.Font.GothamBold
                specBtn.TextSize = 10
                specBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                specBtn.BackgroundColor3 = Color3.fromRGB(87, 139, 46)
                specBtn.Size = UDim2.new(0, 50, 0, 24)
                specBtn.Position = UDim2.new(1, -164, 0.5, -12)
                specBtn.BorderSizePixel = 0
                specBtn.Parent = card
                local sCorner = Instance.new("UICorner")
                sCorner.CornerRadius = UDim.new(0, 4)
                sCorner.Parent = specBtn
                specBtn.MouseButton1Click:Connect(function()
                    StartSpectate(p)
                end)

                -- Botón 2: Ficha (Abrir ventana modal de inspección)
                local infoBtn = Instance.new("TextButton")
                infoBtn.Text = "📋 Ficha"
                infoBtn.Font = Enum.Font.GothamBold
                infoBtn.TextSize = 10
                infoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                infoBtn.BackgroundColor3 = Color3.fromRGB(35, 55, 75)
                infoBtn.Size = UDim2.new(0, 52, 0, 24)
                infoBtn.Position = UDim2.new(1, -108, 0.5, -12)
                infoBtn.BorderSizePixel = 0
                infoBtn.Parent = card
                local iCorner = Instance.new("UICorner")
                iCorner.CornerRadius = UDim.new(0, 4)
                iCorner.Parent = infoBtn
                infoBtn.MouseButton1Click:Connect(function()
                    OpenPlayerInspector(p)
                end)

                -- Botón 3: TP (Teletransportarse detrás)
                local tpBtn = Instance.new("TextButton")
                tpBtn.Text = "⚡ TP"
                tpBtn.Font = Enum.Font.GothamBold
                tpBtn.TextSize = 10
                tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                tpBtn.BackgroundColor3 = Color3.fromRGB(35, 75, 50)
                tpBtn.Size = UDim2.new(0, 44, 0, 24)
                tpBtn.Position = UDim2.new(1, -50, 0.5, -12)
                tpBtn.BorderSizePixel = 0
                tpBtn.Parent = card
                local tCorner = Instance.new("UICorner")
                tCorner.CornerRadius = UDim.new(0, 4)
                tCorner.Parent = tpBtn
                tpBtn.MouseButton1Click:Connect(function()
                    local myHRP = GetHRP()
                    local targetHRP = GetHRP(p)
                    if myHRP and targetHRP then
                        myHRP.CFrame = targetHRP.CFrame + (targetHRP.CFrame.LookVector * -3.5) + Vector3.new(0, 2, 0)
                    end
                end)
            end
        end
    end
end

searchBox:GetPropertyChangedSignal("Text"):Connect(RefreshPlayerList)
CreateButton(playerPage, "🔄 Actualizar Lista Manualmente", RefreshPlayerList)
task.spawn(RefreshPlayerList)
Players.PlayerAdded:Connect(function() task.wait(1); RefreshPlayerList() end)
Players.PlayerRemoving:Connect(function() task.wait(0.5); RefreshPlayerList() end)

-- PESTAÑA 4: ESP Y VISUALES DE JUGADOR
local espPage = CreateTab("ESP Radar", "🎯")
CreateSection(espPage, "Visuales de Jugadores")
CreateToggle(espPage, "Activar ESP Maestro", false, function(s) State.ESP.Master = s end)
CreateToggle(espPage, "Cajas 3D (Boxes)", true, function(s) State.ESP.Boxes = s end)
CreateToggle(espPage, "Resaltar Siluetas (Chams)", true, function(s) State.ESP.Chams = s end)
CreateToggle(espPage, "Etiquetas de Nombre, Salud y Distancia", true, function(s) State.ESP.Names = s end)
CreateToggle(espPage, "Ignorar Companeros de Equipo", false, function(s) State.ESP.TeamCheck = s end)

CreateSection(espPage, "Colores de ESP")
CreateButton(espPage, "Color Verde Esmeralda (Predeterminado)", function()
    State.ESP.Color = Color3.fromRGB(87, 139, 46)
end)
CreateButton(espPage, "Color Cyan Neon", function()
    State.ESP.Color = Color3.fromRGB(0, 230, 255)
end)
CreateButton(espPage, "Color Rojo Carmesi", function()
    State.ESP.Color = Color3.fromRGB(255, 50, 50)
end)
CreateButton(espPage, "Color Dorado Brillante", function()
    State.ESP.Color = Color3.fromRGB(255, 215, 0)
end)

-- PESTAÑA 5: VISUALES DEL MUNDO
local visPage = CreateTab("Visuales", "👁️")
CreateSection(visPage, "Iluminacion del Mundo")
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

-- PESTAÑA 6: TELETRANSPORTE
local tpPage = CreateTab("Teleport", "⚡")
CreateSection(tpPage, "Accesos Rapidos")
CreateToggle(tpPage, "Click Teleport (Ctrl + Click)", false, function(s) State.Teleport.ClickTP = s end)
CreateButton(tpPage, "Teletransporte al Enemigo Mas Cercano", function()
    local myHRP = GetHRP()
    if not myHRP then return end
    local target = GetClosestTarget(9999, "HumanoidRootPart", false, false)
    if target then myHRP.CFrame = target.CFrame + Vector3.new(0, 3.5, 0) end
end)
CreateButton(tpPage, "Escape al Cielo (+120 Studs)", function()
    local myHRP = GetHRP()
    if myHRP then myHRP.CFrame = myHRP.CFrame + Vector3.new(0, 120, 0) end
end)
CreateSection(tpPage, "Guardar Posicion")
CreateButton(tpPage, "Guardar Coordenadas Actuales", function()
    local myHRP = GetHRP()
    if myHRP then State.Teleport.SavedCFrame = myHRP.CFrame end
end)
CreateButton(tpPage, "Cargar Posicion Guardada", function()
    local myHRP = GetHRP()
    if myHRP and State.Teleport.SavedCFrame then myHRP.CFrame = State.Teleport.SavedCFrame end
end)

-- PESTAÑA 7: EXPLOITS Y RAGE
local exploitPage = CreateTab("Exploits", "💀")
CreateSection(exploitPage, "Ventajas de Juego")
CreateToggle(exploitPage, "Fast Loot (ProximityPrompt Instantaneo a 0s)", false, function(s) State.Exploits.FastLoot = s end)
CreateToggle(exploitPage, "Congelar Personaje (Anti-Knockback)", false, function(s) State.Exploits.Freeze = s end)
CreateButton(exploitPage, "Volverse Headless (Cabeza Invisible)", function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Head") then
        char.Head.Transparency = 1
        if char.Head:FindFirstChild("face") then char.Head.face.Transparency = 1 end
    end
end)
CreateButton(exploitPage, "Equipar Korblox Derecho (Visual)", function()
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

-- PESTAÑA 8: SCRIPT HUB (1-CLICK)
local hubPage = CreateTab("Scripts", "📜")
CreateSection(hubPage, "Scripts Populares 1-Click")
CreateButton(hubPage, "Ejecutar Steal an Egg (Fn)", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/caomod2077/Script/refs/heads/main/Fn-stealanegg.lua"))()
end)
CreateButton(hubPage, "Ejecutar Infinite Yield (Comandos Admin)", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end)
CreateButton(hubPage, "Ejecutar Dex Explorer V4", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()
end)
CreateButton(hubPage, "Ejecutar SimpleSpy V3 (Remote Spy)", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua"))()
end)
CreateButton(hubPage, "Ejecutar Hydroxide", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Upbolt/Hydroxide/revision/init.lua"))()
end)

-- PESTAÑA 9: UTILIDADES
local utilPage = CreateTab("Utilidades", "🛠️")
CreateSection(utilPage, "Servidor")
CreateToggle(utilPage, "Anti-AFK (Prevenir kick por 20min)", true, function(s) State.Exploits.AntiAFK = s end)
CreateButton(utilPage, "Reconectar al Servidor Actual", function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)
CreateButton(utilPage, "Cambiar de Servidor (Server Hop)", function()
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

print("[Koio Ultimate Hub v5.0] Cargado exitosamente. Presiona RightShift o Insert para abrir.")
