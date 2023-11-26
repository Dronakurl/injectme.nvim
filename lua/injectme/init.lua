local M = {}

M.config = {
  mode = "standard",
  reload_all_buffers = true,
  reset_treesitter = true,
}

-- injections defined by this plugin
M.preset_injections = require("injectme.preset_injections")

-- injections previously saved in a plugin file or read from the scm files in the runtime
M.file_injections = {}
local injections_file = vim.fn.stdpath("data") .. "/state_injectme.lua"

local function _save_injections()
  local expstr = vim.inspect(M.injections)
  os.remove(injections_file)
  local file = io.open(injections_file, "w")
  if file ~= nil then
    file:write("return " .. expstr)
    file:close()
  end
end

-- Load current injections
local read_from_data_file = false
if vim.fn.filereadable(injections_file) == 1 then
  -- First priority: Load from injections file if possible
  -- print("DEBUG Read injections table lua")
  local status, result = pcall(function()
    M.file_injections = dofile(injections_file)
  end)
  if not status then
    vim.notify("Error occurred: " .. result, vim.log.levels.ERROR)
  else
    read_from_data_file = true
  end
end
if read_from_data_file == false then
  -- Second priority: Read from queries/../*.scm files
  -- print("DEBUG Read injections table from scm files")
  -- all injections from the files in the runtime
  -- disabled standards injections are included as queries that should null out the injection
  M.file_injections = require("injectme.query_file_parser")
end

-- Glue it together to one master table containing injections from files
-- and configured new injections
M.injections = vim.tbl_deep_extend("keep", M.file_injections, M.preset_injections)

-- Descriptions
local expl = require("injectme.explain")
for lang, tab in pairs(M.injections) do
  for injectionid, injection in pairs(tab) do
    injection.description = injection.description or expl[lang] and expl[lang][injectionid] or ""
  end
end

-- queries for currently enabled injections
M.injections_code = {}

--- Concatenate code of all enabled injections for a given language
--- @param language string The language for which the injections code should be prepared
local function _set_injection_code(language)
  -- print("DEBUG set_injections_code for " .. language)
  if language == nil then
    return
  end
  M.injections_code[language] = ""
  if M.injections[language] then
    for _, v in pairs(M.injections[language]) do
      if v.enabled then
        M.injections_code[language] = M.injections_code[language] .. v.code .. "\n"
      end
    end
  else
    -- print("DEBUG No injections found for given language.")
  end
end

--- Concatenate code for given language
--- @param language string language
local function _set_injections_code(language)
  -- print("DEBUG set_injections_code_all")
  if language == nil then
    return
  end
  if language == "ALL" then
    for lang, _ in pairs(M.injections) do
      _set_injection_code(lang)
    end
  else
    _set_injection_code(language)
  end
end

--- Remove or add all injections for a given language or all of them if language is omitted
--- @param language string|nil The language for which all injections should be removed or added
--- @param enabled boolean set to true to set all injections
local function _set_all_injections(language, enabled)
  for lang, tab in pairs(M.injections) do
    for _, injection_table in pairs(tab) do
      if language == nil or language == lang then
        if vim._ts_has_language(lang) then
          injection_table.enabled = enabled
        end
      end
    end
  end

  M.apply_injections(language)
end

--- reset treesitter parser, so that injections are applied
local function _reset_treesitter()
  -- local parser = vim.treesitter.get_parser()
  -- parser:parse(true)
end

--- reload all buffers with a defined language injection
local function _reload_all_buffers()
  local buffers = vim.api.nvim_list_bufs()
  local languages = {}
  for k, _ in pairs(M.injections) do
    table.insert(languages, k)
  end

  -- local cur_buf = vim.api.nvim_get_current_buf()

  for _, buffer in ipairs(buffers) do
    if vim.api.nvim_buf_is_valid(buffer) then
      -- vim.api.nvim_set_current_buf(buffer)

      -- get the treesitter language of the current buffer
      -- local lang = vim.api.nvim_buf_get_option(buffer, 'ft')
      local lang = vim.api.nvim_get_option_value("ft", { buf = buffer })
      local updateme = false
      for _, existing_lang in ipairs(languages) do
        if lang == existing_lang then
          updateme = true
          break
        end
      end
      -- print("DEBUG: " .. vim.inspect(buffer) .. " " .. lang .. " " .. vim.inspect(updateme))
      if updateme then
        -- print("DEBUG: write " .. vim.inspect(buffer) .. " " .. lang .. " " .. vim.inspect(updateme))
        if
          vim.api.nvim_buf_call(buffer, function()
            ---@diagnostic disable-next-line:redundant-return-value
            return vim.bo.modified
          end)
        then
          local choice =
            vim.fn.confirm("Save and reload buffer to show code syntax injections", "&Save\nS&kip", "Save", "Question")
          if choice == 1 then
            vim.api.nvim_buf_call(buffer, function()
              vim.cmd("w")
            end)
            vim.api.nvim_buf_call(buffer, function()
              vim.cmd("e")
            end)
            -- vim.cmd("w")
            -- vim.cmd("e")
          elseif choice == 2 then
            -- print("DEBUG skipped")
          end
        else
          vim.api.nvim_buf_call(buffer, function()
            vim.cmd("e")
          end)
          -- vim.cmd("e")
        end
      end
    else
      -- print("DEBUG Buffer does not exist!")
    end
  end
  -- if vim.api.nvim_buf_is_valid(cur_buf) then
  --   vim.api.nvim_set_current_buf(cur_buf)
  -- end
end

--- Set the treesitter query for all languages
--- @param language string
--- @param ignore_empty boolean if true, ignores languages with empty treesitter code
local function _set_treesitter_query(language, ignore_empty)
  -- print("DEBUG set_treesitter_query language " .. language .. " ignore_empty:" .. vim.inspect(ignore_empty))
  for lang, code in pairs(M.injections_code) do
    -- print("DEBUG lang " .. lang)
    if lang == language or language == "ALL" then
      local mycode = string.gsub(code, "^%s*(.-)%s*$", "%1")
      if mycode ~= "" or ignore_empty == false then
        -- This prevents that injections for languages are set, which are not installed
        if vim._ts_has_language(lang) then
          vim.treesitter.query.set(lang, "injections", mycode)
        end
      end
    end
  end
end

M.apply_injections = function(language)
  _set_injections_code(language)
  local ignore_empty = (language == "ALL")
  _set_treesitter_query(language, ignore_empty)
  if M.config.reload_all_buffers then
    _reload_all_buffers()
  end
  if M.config.reset_treesitter then
    _reset_treesitter()
  end
  _save_injections()
end

--- Toggle an injection
--- @param language string The language for which to include the injection
--- @param injection_id string ID of the injection to be added
M.toggle_injection = function(language, injection_id)
  -- print("DEBUG toggle_injection for " .. language .. " and injection ID " .. injection_id)
  if M.injections[language] == nil then
    vim.notify("injectme.nvim: Could not find " .. language .. " in configured injections.", vim.log.levels.ERROR)
    return
  end
  if vim._ts_has_language(language) == false then
    vim.notify("injectme.nvim: language " .. language .. " is not installed in treesitter", vim.log.levels.ERROR)
    return
  end
  local injection = M.injections[language][injection_id]
  if injection == nil then
    vim.notify(
      "injectme.nvim: Could not find '"
        .. injection_id
        .. "' for language '"
        .. language
        .. "' in configured injections.",
      vim.log.levels.ERROR
    )
    return
  end
  injection.enabled = not injection.enabled
  M.apply_injections(language)
  local injectionstr = ""
  if injection.enabled then
    injectionstr = "enabled"
  else
    injectionstr = "disabled"
  end
  vim.notify(
    "injectme.nvim: Injection "
      .. injection_id
      .. " is now "
      .. injectionstr
      .. ". Use :InjectmeSave "
      .. language
      .. " to keep in all sessions.",
    vim.log.levels.INFO
  )
end

--- Remove all custom injections for a given language or all of them if language is omitted
--- @param language string|nil The language for which all injections should be removed
M.remove_all_injections = function(language)
  _set_all_injections(language, false)
end

--- Add all custom injections for a given language or all of them if language is omitted
--- @param language string|nil The language for which all injections should be added
M.add_all_injections = function(language)
  _set_all_injections(language, true)
end

--- Saves the selected injections to your runtime, set mode to "standard".
--- @param language string The language for which all injections should be saved
M.save_injections = function(language)
  -- First, save to the runtime the plugin custom file
  _save_injections()
  -- print("DEBUG save_injections with argument " .. vim.inspect(language))
  for lang, tab in pairs(M.injections) do
    if language == "ALL" or language == lang then
      -- print("DEBUG save_injections for language " .. lang)
      local standard_touched = false
      for _, v in pairs(tab) do
        if v.enabled == false and v.standard_or_custom == "standard" then
          standard_touched = true
        end
      end
      -- print("DEBUG standard_touched = " .. vim.inspect(standard_touched))
      local write = ""
      if standard_touched == false then
        -- when no standard injection is touched, no need to save all injections
        write = write .. ";extends\n"
      end
      local n = 0
      local sorted_keys = {}
      for k in pairs(tab) do
        table.insert(sorted_keys, k)
      end
      table.sort(sorted_keys, function(a, b)
        if tab[a].order < tab[b].order then
          return true
        elseif tab[a].order == tab[b].order and a < b then
          return true
        else
          return false
        end
      end)
      local inherited_langs_to_override = {}
      for _, injectionid in ipairs(sorted_keys) do
        local conten = tab[injectionid]
        -- print("DEBUG: injectionid = " .. injectionid .. " order= " .. conten.order)
        if conten.enabled and (standard_touched or conten.standard_or_custom == "custom") then
          if conten.sourcelang ~= lang then
            table.insert(inherited_langs_to_override, conten.sourcelang)
          end
          n = n + 1
          write = write .. ";" .. injectionid .. "\n"
          write = write .. conten.code .. "\n"
        end
      end
      -- print("DEBUG: n = " .. n)
      if n > 0 or standard_touched == true then
        local file_path = vim.fn.stdpath("config") .. "/queries/" .. lang
        local existing_file = io.open(file_path .. "/injections.scm", "r")

        local existing = ""
        if existing_file ~= nil then
          existing = existing_file:read("*all")
          io.close(existing_file)
        end
        if require("injectme.helper").compareStrings(existing, write) then
          vim.notify("injectme.nvim: Nothing to do for language " .. lang .. ", saved already", vim.log.levels.INFO)
        else
          local ch = nil
          if existing_file ~= nil then
            ch = vim.fn.confirm("Overwrite the existing injections for " .. lang .. " in your config?", "&Do it\n&Skip")
          else
            ch = vim.fn.confirm("Write the injections for " .. lang .. " in your config?", "&Do it\n&Skip")
          end
          if ch == 1 then
            -- If directory does not exist, create it
            vim.fn.mkdir(file_path, "p")
            local file = assert(io.open(file_path .. "/injections.scm", "w"))
            file:write(write)
            file:close()
            for _, f in ipairs(inherited_langs_to_override) do
              local ip = vim.fn.stdpath("config") .. "/queries/" .. f
              vim.fn.mkdir(ip, "p")
              local ff = assert(io.open(ip .. "/injections.scm", "w"))
              ff:write("")
              ff:close()
            end
          end
        end
      else
        -- No enabled custom notifications
        if language ~= "ALL" then
          vim.notify("injectme.nvim: No injections set for language " .. lang, vim.log.levels.INFO)
        end
        local file_path = vim.fn.stdpath("config") .. "/queries/" .. lang
        local existing_file = io.open(file_path .. "/injections.scm", "r")
        if existing_file then
          vim.notify(
            "injectme.nvim: Deleted existing custom queries file, no non-standard injections are set",
            vim.log.levels.INFO
          )
          existing_file:close() -- ensure the file is closed before deleting
          os.remove(file_path .. "/injections.scm")
        end
        for _, v in pairs(tab) do
          if v.sourcelang ~= lang then
            local status, result = pcall(function()
              os.remove(vim.fn.stdpath("config") .. "/queries/" .. v.sourcelang)
            end)
            if not status then
              vim.notify("ERROR: Something went wrong with deleting inherited langs scm files", vim.log.levels.ERROR)
              print(result)
            end
          end
        end
      end
    end
  end
end

--- Reset all injections to standard and delete the json file
M.reset_injectme = function()
  local choices = {
    "Save queries to neovin runtime",
    "Delete injectme.nvim settings",
    "Both: Ready to leave injectme.nvim",
    "Abort",
  }
  vim.ui.select(choices, { prompt = "Ready to leave injectme.nvim? Save travels!" }, function(_, choice)
    if choice == 1 or choice == 3 then
      M.save_injections("ALL")
    end
    if choice == 2 or choice == 3 then
      os.remove(injections_file)
    end
  end)
end

M.install = function()
  vim.api.nvim_command("helptags " .. vim.fn.stdpath("config") .. "/injectme.nvim/doc")
end

M.setup = function(user_config)
  M.config = vim.tbl_deep_extend("force", {}, M.config, user_config)
  if M.config.mode == "all" then
    M.add_all_injections(nil)
  elseif M.config.mode == "none" then
    M.remove_all_injections(nil)
  end
end

return M
