M = {}

local injections = require("injectme").injections

M.injectme_picker = function(opts)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  -- local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local previewers = require("telescope.previewers")

  -- TODO: Picker: Only for current language

  -- -- TDO: Provide the option to show all injections, not just the ones for the current language
  -- local lang = vim.treesitter.language.get_lang(vim.bo[0].filetype)
  -- if vim._ts_has_language(lang) == false then
  --   vim.notify("WARNING treesitter does not support " .. lang .. ". Please install first.", vim.log.levels.WARN)
  --   return
  -- end
  -- local injections = require("injectme").injections[lang]
  -- if injections == nil then
  --   vim.notify("WARNING no injections found for " .. lang .. ". ", vim.log.levels.WARN)
  -- end

  local function injection_to_data()
    local my_data = {}
    for lang, tab in pairs(injections) do
      for k, injection in pairs(tab) do
        table.insert(my_data, {
          value = lang .. " " .. k,
          description = injection.description,
          code = injection.code,
          enabled = injection.enabled,
          standard_or_custom = injection.standard_or_custom,
        })
      end
    end
    return my_data
  end

  opts = opts or {}

  local picker = pickers.new(opts, {
    prompt_title = "injectme.nvim: Pick injections",
    finder = finders.new_table({
      results = injection_to_data(),
      entry_maker = function(entry)
        local display_text = entry.enabled and "[x] " or "[ ] "
        local soc = ""
        if entry.standard_or_custom == "standard" then
          soc = "(standard) "
        else
          soc = "( custom ) "
        end
        display_text = display_text .. soc .. entry.value
        return {
          value = entry.value,
          display = display_text,
          -- ordinal = entry.value .. entry.description .. entry.code,
          ordinal = entry.value,
          code = entry.code,
          description = entry.description,
          standard_or_custom = entry.standard_or_custom,
        }
      end,
    }),
    previewer = previewers.new_buffer_previewer({
      -- NOTE: Syntax highlighting for the preview buffer would be great
      title = "Description and treesitter query",
      -- setup = function(_)
      --   vim.wo.wrap = true
      --   vim.cmd("set wrap")
      --   return {}
      -- end,
      define_preview = function(self, entry, _)
        -- Display the code in the preview window
        local soc = ""
        if entry.standard_or_custom == "standard" then
          soc = ";standard injection provided by treesitter "
        else
          soc = ";custom injection provided by injectme.nvim "
        end
        local all_lines = { ";" .. entry.display, soc }
        if entry.description ~= nil then
          local desc_lines = vim.split(entry.description, "\n")
          for _, v in ipairs(desc_lines) do
            table.insert(all_lines, "; " .. v)
          end
        end
        local code_lines = vim.split(entry.code, "\n")
        for _, v in ipairs(code_lines) do
          table.insert(all_lines, vim.trim(v))
        end
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, all_lines)
        vim.api.nvim_win_set_option(self.state.winid, "wrap", true)
      end,
    }),
    layout_strategy = "horizontal",
    layout_config = {
      preview_cutoff = 2,
      preview_width = 0.6,
      -- width = 0.6,
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(_, map)
      map({ "i", "n" }, "<CR>", function(prompt_bufnr)
        local sel_lang = ""
        local selection = action_state.get_selected_entry()
        for lang, tab in pairs(injections) do
          for k, injection in pairs(tab) do
            if lang .. " " .. k == selection.value then
              injection.enabled = not injection.enabled
              sel_lang = lang
              break
            end
          end
        end
        if sel_lang == "" then
          vim.notify("ERROR: No valid language " .. vim.inspect(selection), vim.log.levels.ERROR)
          return
        end
        require("injectme").apply_injections(sel_lang)
        local current_picker = action_state.get_current_picker(prompt_bufnr)
        current_picker:refresh(finders.new_table({
          results = injection_to_data(),
          entry_maker = function(entry)
            local display_text = entry.enabled and "[x] " or "[ ] "
            display_text = display_text .. entry.value
            return {
              value = entry.value,
              display = display_text,
              ordinal = entry.value,
              code = entry.code,
              description = entry.description,
              standard_or_custom = entry.standard_or_custom,
            }
          end,
        }))
      end)
      return true
    end,

    -- on_complete = {
    --   function()
    --     vim.cmd("stopinsert")
    --   end,
    -- },
  })

  picker:find()
end

return M
