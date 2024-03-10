local M = {}
local ffi = require "ffi"
local crypt = ffi.load("crypt")
ffi.cdef [[
char* crypt(
  const char* key,
  const char* salt
);
]]

function M.des(text, salt)
  local cdata = crypt.crypt(text, salt)
  return cdata and ffi.string(cdata) or nil
end

return M

--[[

example

  local crypt = require "ffi_example"
  local hash = crypt.des("abcdef", "XX")
  print(hash)

--]]
