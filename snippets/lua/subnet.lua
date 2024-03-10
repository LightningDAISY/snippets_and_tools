local M = {}
local rex   = require "rex_pcre2"
local bit32 = require "bit32"
local errorMessage = ""

local l2a = {
  "128.0.0.0", -- 1
  "192.0.0.0", -- 2
  "224.0.0.0", -- 3
  "240.0.0.0", -- 4
  "248.0.0.0", -- 5
  "252.0.0.0", -- 6
  "254.0.0.0", -- 7
  "255.0.0.0", -- 8
  "255.128.0.0", -- 9
  "255.192.0.0", -- 10
  "255.224.0.0", -- 11
  "255.240.0.0", -- 12
  "255.248.0.0", -- 13
  "255.252.0.0", -- 14
  "255.254.0.0", -- 15
  "255.255.0.0", -- 16
  "255.255.128.0", -- 17
  "255.255.192.0", -- 18
  "255.255.224.0", -- 19
  "255.255.240.0", -- 20
  "255.255.248.0", -- 21
  "255.255.252.0", -- 22
  "255.255.254.0", -- 23
  "255.255.255.0", -- 24
  "255.255.255.128", -- 25
  "255.255.255.192", -- 26
  "255.255.255.224", -- 27
  "255.255.255.240", -- 28
  "255.255.255.248", -- 29
  "255.255.255.252", -- 30
  "255.255.255.254", -- 31
  "255.255.255.255",  --32
}

local isConfigure = rex.new("(\\d+\\.[^\\s;]+)")
local isAddress = rex.new("\\.")
local bySlash = rex.new("/")
isConfigure:jit_compile()
isAddress:jit_compile()
bySlash:jit_compile()

local function fread(path)
  local fp = assert(io.open(path, "r"))
  local fbody = fp:read("*all")
  fp:close()
  return fbody
end

local function splitAddress(address)
  local itr = rex.split(address, isAddress)
  local decs = {}
  for dec in itr do
    table.insert(decs, dec)
  end
  return decs
end

local function getSubnetAddress(adr, mask)
  if not mask then return adr end
  local addressColumns = splitAddress(adr)
  local maskColumns    = splitAddress(mask)
  local subnetColumns  = {}
  for i = 1, 4, 1 do
    table.insert(subnetColumns, bit32.band(addressColumns[i], maskColumns[i]))
  end
  return table.concat(subnetColumns, ".")
end
--
-- ex.
--     if isSubnetMember("111.7.80.66", "111.7.80.64/27") then
--       print("111.7.80.66 in 111.7.80.64/27")
--     end
--
local function isSubnetMember(adr, subnet)
  local itr = rex.split(subnet, bySlash)
  local subnetAddress = itr()
  local mask = itr()
  if mask then
    if not rex.match(mask, isAddress) then
      mask = l2a[mask + 0]
      if not mask then return end
    end
  end
  if subnetAddress == getSubnetAddress(adr, mask) then return true end
  return false
end

--
-- allows.conf example
--
--   122.22.4.0/24
--   210.34.92.5/255.255.252.0
--   127.0.0.1
--
function M.isAllowed(sourceAddress, filePath)
  local fbody = fread(filePath)
  for subnet in rex.gmatch(fbody, isConfigure) do
    if isSubnetMember(sourceAddress, subnet) then
      return true
    end
  end
  return false
end

function M.new(o)
  o = o or {}
  return o
end

return M

