---@module "injectme.nvim"
---@author Dronakurl
---@license MIT
local injections = require("injectme.injection_table").injections

--- User command to display the config
vim.api.nvim_create_user_command("InjectmeInfo", function()
  local im = require("injectme")
  local output = "injectme.nvim:" .. "\n"
  output = output .. "Mode: " .. vim.inspect(im.config.mode) .. "\n"
  output = output .. "Reload buffers: " .. vim.inspect(im.config.reload_all_buffers) .. "\n"
  output = output .. "Reset treesitter: " .. vim.inspect(im.config.reset_treesitter) .. "\n"
  local nin = 0
  for _, tab in pairs(im.injections) do
    for _, cont in pairs(tab) do
      if cont.enabled then
        nin = nin + 1
      end
    end
  end
  output = output .. "# total of injections: " .. vim.inspect(nin)
  vim.notify(output, vim.log.levels.INFO)
end, { nargs = 0 })

local lang_completions = {}
for lang, _ in pairs(injections) do
  table.insert(lang_completions, lang)
end

--- User command to display the config
vim.api.nvim_create_user_command("InjectmeSave", function(xx)
  local im = require("injectme")
  local args = vim.split(xx["args"], "%s")
  local lang = args[1]
  if lang == "" then
    lang = "ALL"
  end
  im.save_injections(lang)
end, {
  nargs = "?",
  complete = function()
    return lang_completions
  end,
})

local completions = {}
for lang, tab in pairs(injections) do
  for k, _ in pairs(tab) do
    table.insert(completions, lang .. " " .. k)
  end
end

--- Set Injection for language and id
vim.api.nvim_create_user_command("InjectmeToggle", function(xx)
  local args = vim.split(xx["args"], "%s")
  -- vim.notify(vim.inspect(args))
  local language, injectionid = args[1], args[2]
  local im = require("injectme")
  if language == nil or injectionid == nil then
    vim.notify(
      "injectme.nvim: Something is wrong with the arguments: "
        .. xx["args"]
        .. "\n"
        .. "Usage: InjectmeToggle {language} {id string of the injection, e.g. rst_for_docstring}",
      vim.log.levels.WARNING
    )
    return nil
  end
  im.toggle_injection(language, injectionid)
end, {
  nargs = "*",
  desc = "Language and injection ID, e.g. python rst_for_docstring",
  complete = function()
    return completions
  end,
  force = true,
})

-- TODO: A menu to pick the injections
