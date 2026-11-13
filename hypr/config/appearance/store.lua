-- Shared reader for the two theme stores rendered outside this repo:
--
--   ~/.myenv/theme/palette/current/hypr/theme.lua   colours (palette.lua)
--   ~/.myenv/theme/feel/current/hypr/feel.lua       feel    (feel.lua)
--
-- Both files are pure data (`return { ... }` only). A missing file is not an
-- error: the caller keeps the defaults it declared.

local Store = {}

function Store.warn(message)
    if io and io.stderr then
        io.stderr:write("[theme] " .. message .. "\n")
        io.stderr:flush()
    end
end

-- WM directory of one store, or nil when neither MYENV nor HOME is set.
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

-- Returns (data, exists) so a missing file can be told apart from a broken one.
-- Mode "t" + empty env: the file may only return a table, no functions.
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

-- Recursive merge: a store may emit only the keys it owns.
function Store.merge(base, extra)
    for key, value in pairs(extra) do
        if type(value) == "table" and type(base[key]) == "table" then
            Store.merge(base[key], value)
        else
            base[key] = value
        end
    end
end

return Store
