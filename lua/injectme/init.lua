local function compareStrings(str1, str2)
  -- Remove whitespaces from both strings
  str1 = string.gsub(str1, "%s+", "")
  str2 = string.gsub(str2, "%s+", "")

  -- Compare the two strings
  if str1 == str2 then
    return true
  else
    return false
  end
end
local M = {}

M.config = {
  mode = "standard",
  -- "all"/ "none" if all/no injections should be activated
  -- "standard", if no injections should be changed from standard settings in
  -- the runtime directory, i.e. ~/.config/nvim/after/queries/<language>/injections.scm
  reload_all_buffers = true,
  -- after toggling an injection, all buffers are reloaded to reset treesitter
  reset_treesitter = true,
  -- after toggling an injections, the treesitter parser is reset, so that injections are shown
}

M.injections = require("injectme.injection_table").injections
M.standard_injections = require("injectme.standard_injections").standard_injections
M.injections_code = {}

--- Concatenate code of all enabled injections for a given language
--- @param language string The language for which the injections code should be prepared
function M._set_injections_code(language)
  -- print("DEBUG set_injections_code for " .. language)
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

--- Concatenate code for all languages
function M._set_injections_code_all()
  -- print("DEBUG set_injections_code_all")
  for lang, _ in pairs(M.injections) do
    M._set_injections_code(lang)
  end
end

--- Remove or add all injections for a given language or all of them if language is omitted
--- @param language string|nil The language for which all injections should be removed or added
--- @param enabled boolean set to true to set all injections
M._set_all_injections = function(language, enabled)
  for lang, tab in pairs(M.injections) do
    for _, injection_table in pairs(tab) do
      if language == nil or language == lang then
        if M.standard_injections[lang] ~= nil then
          injection_table.enabled = enabled
        end
      end
    end
  end
  M._set_injections_code_all()
  M._set_treesitter_query(false)
  if M.config.reload_all_buffers then
    M._reload_all_buffers()
  end
  if M.config.reset_treesitter then
    M._reset_treesitter()
  end
end

--- reset treesitter parser, so that injections are applied
M._reset_treesitter = function()
  -- local parser = vim.treesitter.get_parser()
  -- parser:parse(true)
end

--- reload all buffers with a defined language injection
M._reload_all_buffers = function()
  local buffers = vim.api.nvim_list_bufs()
  local languages = {}
  for k, _ in pairs(M.injections) do
    table.insert(languages, k)
  end

  local cur_buf = vim.api.nvim_get_current_buf()

  for _, buffer in ipairs(buffers) do
    if vim.api.nvim_buf_is_valid(buffer) then
      vim.api.nvim_set_current_buf(buffer)

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
        if vim.bo.modified then
          local choice =
            vim.fn.confirm("Save and reload buffer to show code syntax injections", "&Save\nS&kip", "Save", "Question")
          if choice == 1 then
            vim.cmd("w")
            vim.cmd("e")
          elseif choice == 2 then
            -- print("DEBUG skipped")
          end
        else
          vim.cmd("e")
        end
      end
    else
      -- print("DEBUG Buffer does not exist!")
    end
  end
  if vim.api.nvim_buf_is_valid(cur_buf) then
    vim.api.nvim_set_current_buf(cur_buf)
  end
end

--- Set the treesitter query for all languages
--- @param ignore_empty boolean if true, ignores languages with empty treesitter code
M._set_treesitter_query = function(ignore_empty)
  -- print("DEBUG set_treesitter_query" .. vim.inspect(ignore_empty))
  if ignore_empty == nil then
    ignore_empty = false
  end
  for lang, code in pairs(M.injections_code) do
    -- print("DEBUG " .. lang)
    local mycode = string.gsub(code, "^%s*(.-)%s*$", "%1")
    if mycode ~= "" or ignore_empty == false then
      local standard_code = M.standard_injections[lang] or ""
      mycode = standard_code .. "\n" .. mycode
      -- This prevents that injections for languages are set, which are not installed
      if M.standard_injections[lang] ~= nil then
        vim.treesitter.query.set(lang, "injections", mycode)
      end
    end
  end
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
  if M.standard_injections[language] == nil then
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
  M._set_injections_code(language)
  M._set_treesitter_query(true)
  if M.config.reload_all_buffers then
    M._reload_all_buffers()
  end
  if M.config.reset_treesitter then
    M._reset_treesitter()
  end
end

--- Remove all injections for a given language or all of them if language is omitted
--- @param language string|nil The language for which all injections should be removed
M.remove_all_injections = function(language)
  M._set_all_injections(language, false)
end

--- Add all injections for a given language or all of them if language is omitted
--- @param language string|nil The language for which all injections should be added
M.add_all_injections = function(language)
  M._set_all_injections(language, true)
end

--- Saves the selected injections to your runtime, set mode to "standard".
--- @param language string The language for which all injections should be saved
M.save_injections = function(language)
  -- print("DEBUG save_injections " .. vim.inspect(language))
  for lang, tab in pairs(M.injections) do
    local write = ";extends\n"
    local n = 0
    if language == "ALL" or language == lang then
      -- print("DEBUG save_injections " .. lang)
      local sorted_keys = {}
      for k in pairs(tab) do
        table.insert(sorted_keys, k)
      end
      table.sort(sorted_keys)
      for _, injectionid in ipairs(sorted_keys) do
        local conten = tab[injectionid]
        if conten.enabled then
          n = n + 1
          write = write .. ";" .. injectionid .. "\n"
          write = write .. conten.code .. "\n"
        end
      end
      if n > 0 then
        local file_path = vim.fn.stdpath("config") .. "/after/queries/" .. lang
        local existing_file = io.open(file_path .. "/injections.scm", "r")

        local existing = ""
        if existing_file ~= nil then
          existing = existing_file:read("*all")
          -- if lang == "python" then
          --   print("************ " .. lang .. " ************")
          --   print(">>" .. existing .. "<<")
          --   print(">>" .. write .. "<<")
          -- end
          io.close(existing_file)
        end
        if compareStrings(existing, write) then
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
          end
        end
      else
        if language ~= "ALL" then
          vim.notify("injectme.nvim: No injections set for language " .. lang, vim.log.levels.WARN)
        end
      end
    end
  end
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
