-- Rebuild locally authored mesh geometry after Studio/runtime cloning.
-- Mesh object references do not survive the Edit -> Play boundary.
local AssetService = game:GetService("AssetService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local storage = game:GetService("ReplicatedStorage"):WaitForChild("VehicleMeshRuntimeData")
local collection = workspace:WaitForChild("ReferenceVehicleCollection")
local player = Players.LocalPlayer
local cache = {}
local loaded = 0
local errors = 0
local processed = setmetatable({}, {__mode = "k"})

local function build(key)
    if cache[key] then return cache[key].template end
    local folder = storage:WaitForChild(key, 20)
    assert(folder, "Missing saved geometry: " .. key)
    local chunks = folder:GetChildren()
    table.sort(chunks, function(a, b) return a.Name < b.Name end)
    local strings = {}
    for _, chunk in chunks do table.insert(strings, chunk.Value) end
    local data = HttpService:JSONDecode(table.concat(strings))
    local mesh = AssetService:CreateEditableMesh()
    assert(mesh, "Editable mesh memory budget exceeded")
    local vertices, normals, uvs = {}, {}, {}
    for i = 1, #data.v, 3 do
        vertices[#vertices + 1] = mesh:AddVertex(Vector3.new(data.v[i], data.v[i + 1], data.v[i + 2]))
        if i % 4500 == 1 then task.wait() end
    end
    for i = 1, #data.n, 3 do
        normals[#normals + 1] = mesh:AddNormal(Vector3.new(data.n[i], data.n[i + 1], data.n[i + 2]))
    end
    for i = 1, #data.uv, 2 do
        uvs[#uvs + 1] = mesh:AddUV(Vector2.new(data.uv[i], data.uv[i + 1]))
    end
    for i = 1, #data.f, 3 do
        local face = mesh:AddTriangle(vertices[data.f[i]], vertices[data.f[i + 1]], vertices[data.f[i + 2]])
        mesh:SetFaceNormals(face, {normals[data.fn[i]], normals[data.fn[i + 1]], normals[data.fn[i + 2]]})
        mesh:SetFaceUVs(face, {uvs[data.fu[i]], uvs[data.fu[i + 1]], uvs[data.fu[i + 2]]})
        if i % 4500 == 1 then task.wait() end
    end
    mesh:RemoveUnused()
    -- Fixed topology uses substantially less of Roblox's editable mesh budget.
    local fixed = AssetService:CreateEditableMeshAsync(Content.fromObject(mesh), {FixedSize = true})
    assert(fixed, "Unable to allocate compact vehicle mesh")
    mesh:Destroy()
    mesh = fixed
    local template = AssetService:CreateMeshPartAsync(Content.fromObject(mesh), {
        CollisionFidelity = Enum.CollisionFidelity.Box,
    })
    cache[key] = {mesh = mesh, template = template}
    return template
end

local function restore(part)
    if not part:IsA("MeshPart") or processed[part] then return end
    local key = part:GetAttribute("VehicleMeshKey")
    if not key then return end
    processed[part] = true
    part.LocalTransparencyModifier = 1
    local ok, message = pcall(function()
        local template = build(key)
        if not part.Parent then return end
        local size, texture = part.Size, part.TextureContent
        part:ApplyMesh(template)
        part.Size = size
        part.TextureContent = texture
        part.LocalTransparencyModifier = 0
        part:SetAttribute("RuntimeMeshRestored", true)
        loaded += 1
    end)
    if not ok then
        errors += 1
        part:SetAttribute("RuntimeMeshError", tostring(message))
        warn("Vehicle mesh restoration failed: " .. part:GetFullName() .. ": " .. tostring(message))
    end
    player:SetAttribute("VehicleMeshesLoaded", loaded)
    player:SetAttribute("VehicleMeshErrors", errors)
end

-- Process in one queue so duplicate wheel meshes are built only once.
local queue = collection:GetDescendants()
collection.DescendantAdded:Connect(function(part) table.insert(queue, part) end)
local index = 1
while true do
    while index <= #queue do
        restore(queue[index])
        index += 1
    end
    player:SetAttribute("VehicleMeshesReady", loaded >= (storage:GetAttribute("TargetParts") or 0) and errors == 0)
    task.wait(0.25)
end
