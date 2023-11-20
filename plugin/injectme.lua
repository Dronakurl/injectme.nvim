---@module "injectme.nvim"
---@author Dronakurl
---@license MIT
local injections = require("injectme").injections

--- User command to display the config
vim.api.nvim_create_user_command("InjectmeInfo", function()
  local im = require("injectme")
  local lang = vim.treesitter.language.get_lang(vim.bo[0].filetype)
  local injs = im.injections[lang]
  local nin = 0
  for _, tab in pairs(im.injections) do
    for _, cont in pairs(tab) do
      if cont.enabled then
        nin = nin + 1
      end
    end
  end
  local output = "injectme.nvim (" .. vim.inspect(nin) .. " total): injections for current buffer (" .. lang .. ")\n"
  if injs == nil then
    output = output .. "no injections for language = " .. lang .. "\n"
  else
    local sorted_keys = {}
    for k in pairs(injs) do
      table.insert(sorted_keys, k)
    end
    table.sort(sorted_keys, function(a, b)
      if injs[a].standard_or_custom > injs[b].standard_or_custom then
        return true
      elseif injs[a].standard_or_custom == injs[b].standard_or_custom and a < b then
        return true
      else
        return false
      end
    end)
    for _, k in ipairs(sorted_keys) do
      local v = injs[k]
      if v.enabled then
        output = output .. "[✔️]"
      else
        output = output .. "[✖️]"
      end
      local soc = ""
      if v.standard_or_custom == "standard" then
        soc = "nvim-treesitter standard"
      else
        soc = "custom"
      end
      output = output .. " (" .. soc .. ") " .. k .. "\n"
    end
  end
  vim.notify(output, vim.log.levels.INFO)
end, { nargs = 0 })

--- User command to save the config to the runtime path under .config/after
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
  complete = function(_, line)
    local lang_completions = {}
    for lang, _ in pairs(injections) do
      if vim._ts_has_language(lang) then
        table.insert(lang_completions, lang)
      end
    end
    local l = vim.split(line, "%s+")
    if #l == 2 then
      return vim.tbl_filter(function(val)
        return vim.startswith(val, l[2])
      end, lang_completions)
    end
  end,
})

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
  complete = function(_, line)
    local lang_completions = {}
    for lang, _ in pairs(injections) do
      if vim._ts_has_language(lang) then
        table.insert(lang_completions, lang)
      end
    end
    local l = vim.split(line, "%s+")
    if #l == 2 then
      return vim.tbl_filter(function(val)
        return vim.startswith(val, l[2])
      end, lang_completions)
    elseif #l == 3 then
      local completions = {}
      local lang = injections[l[2]]
      if lang == nil then
        return {}
      end
      for k, _ in pairs(lang) do
        if vim.startswith(k, l[3]) then
          table.insert(completions, k)
        end
      end
      table.sort(completions)
      return completions
    end
  end,
  force = true,
})

vim.api.nvim_create_user_command("InjectmeReset", function()
  require("injectme").reset_injectme()
end, {
  nargs = "*",
  desc = "Reset the injectme.nvim plugin with confirmation. Your queries/../*.scm files will be left untouched",
})

-- vim.cmd([[autocmd! User LazyClean lua os.remove(vim.fn.stdpath("data") .. "/injectme.lua" )]])

-- TODO: A menu to pick the injections
