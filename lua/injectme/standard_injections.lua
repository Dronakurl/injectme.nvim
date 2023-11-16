M = {}
M.standard_injections = {}

local function readfile(f, lang)
  local content = f:read("*all")
  f:close()
  M.standard_injections[lang] = M.standard_injections[lang] .. content
end

--- Find all languages that have parsers and get the standard injections for them
local paths = vim.api.nvim_get_runtime_file("parser/*.so", true)
for _, v in ipairs(paths) do
  local lang = string.match(v, "([^/]-)%.so$")
  local files = vim.treesitter.query.get_files(lang, "injections", nil)
  M.standard_injections[lang] = ""
  for _, filename in ipairs(files) do
    local f = io.open(filename, "rb")
    if f then
      readfile(f, lang)
    end
  end
end

return M
