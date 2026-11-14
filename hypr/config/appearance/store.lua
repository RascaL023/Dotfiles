-- Shared reader for the palette and feel stores. Both files are data only;
-- a missing file leaves the caller's defaults in place.

local Store = {}

function Store.warn(message)
    if io and io.stderr then
        io.stderr:write("[theme] " .. message .. "\n")
        io.stderr:flush()
    end
end

-- Directory for one store's active WM, or nil when no root is configured.
function Store.dir(kind)
    local root = os.getenv("MYENV")
    if not root or root == "" then
        local home = os.getenv("HOME")
        if home and home ~= "" then
            root = home .. "/.myenv"
        end
    end

    if not root then
        return nil
    end

    return root .. "/theme/" .. kind .. "/current/hypr"
end

-- Returns (data, exists) so a missing file is distinguishable from a broken one.
function Store.load(path, label)
    local handle = io.open(path, "r")
    if not handle then
        return nil, false
    end

    local source = handle:read("*a")
    handle:close()

    local chunk = load(source, "@" .. path, "t", {})
    if not chunk then
        Store.warn(label .. ": " .. path .. " gagal dikompilasi")
        return nil, true
    end

    local ok, data = pcall(chunk)
    if not ok or type(data) ~= "table" then
        Store.warn(label .. ": " .. path .. " tidak mengembalikan tabel")
        return nil, true
    end

    return data, true
end

local function copy(value)
    if type(value) ~= "table" then
        return value
    end

    local result = {}
    for key, item in pairs(value) do
        result[key] = copy(item)
    end
    return result
end

-- Returns base with extra merged on top. Neither input is modified.
function Store.overlay(base, extra)
    local result = copy(base)

    for key, value in pairs(extra or {}) do
        if type(value) == "table" and type(result[key]) == "table" then
            result[key] = Store.overlay(result[key], value)
        else
            result[key] = copy(value)
        end
    end

    return result
end

return Store
