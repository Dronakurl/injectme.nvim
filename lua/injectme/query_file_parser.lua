--- This module reads the file_injections
--- NOTE: Structure of the output
--- local python = {
---   injection1 = { code = "(something) @jkajdsaj", standard_or_custom = "standard or custom", enabled = true, order = 23 },
---   python_2 = { ... } for injections without an id }
--- queries = {python = the above, otherlang = ...}
--- order is the order given in the scm files

local file_injections = {}

--- Parse one scm file and return the table in the structure above containing all the injections in this file
--- @param filename string
--- @param lang string
--- @param startcnt table Contains cnt and order to start from, passed as table, so it can be altered
--- @param standard_or_custom string "standard" when all queries should be labeled as standard otherwise "custom"
local function parse_file(filename, lang, startcnt, standard_or_custom)
  -- print("DEBUG filename = " .. filename)
  if string.find(filename, ".scm$") == nil then
    vim.notify("ERROR tried to parse a filename with other extension than scm" .. filename, vim.log.levels.ERROR)
    return {}
  end

  -- Read the whole file into a string
  local f = io.open(filename, "r")
  if f == nil then
    vim.notify("ERROR Could not open " .. filename, vim.log.levels.ERROR)
    return {}
  end
  local content = f:read("*all")
  f:close()

  -- split into paragraphs
  if not content:find("\n\n$") then
    content = content .. "\n"
  end
  local parts = {}
  for part in string.gmatch(content, "(.-)\n%s*\n") do
    -- print("DEBUG part = " .. part)
    table.insert(parts, part)
  end

  -- parse each paragraph
  local res = {}
  local current_key = ""

  local function parse_line(line)
    -- strip leading and trailing whitespace
    local stripped = line:match("^%s*(.-)%s*$")
    -- Can be ignored, maybe it's important to keep the order
    if string.find(stripped, "^[;]+%s*extends%s*$") then
      return
    end
    if string.find(stripped, "^[;]+%s*inherits") then
      return
    end
    if string.find(stripped, "^[;]+%s*$") then
      return
    end
    -- Get the key from the first comment in the block
    if current_key == "" and stripped:sub(1, 1) == ";" then
      current_key = stripped:sub(2)
      current_key = current_key:match("^%s*(.-)%s*$")
      current_key = current_key:gsub('[%s%@()."]', "")
      res[current_key] = { order = startcnt.order, enabled = true, code = "" }
      startcnt.order = startcnt.order + 1
    elseif string.find(stripped, "^[;]+%s*standard_override%s*$") then
      -- standard injections can overriden. In after files
      if current_key == "" then
        vim.notify("ERROR parsing " .. line, vim.log.levels.ERROR)
      end
      res[current_key]["standard_or_custom"] = "standard_override"
    elseif stripped:sub(1, 1) == ";" then
      -- ignore other comments
    else
      -- if first line is not a comment, generate an injection id with acounter
      if current_key == "" then
        current_key = lang .. "_" .. startcnt.cnt
        startcnt.cnt = startcnt.cnt + 1
        res[current_key] = { order = startcnt.order, enabled = true, code = "" }
        startcnt.order = startcnt.order + 1
      end
      -- write a line of code
      if current_key ~= "" and stripped ~= "" then
        res[current_key].code = res[current_key].code .. stripped .. "\n"
      end
    end
  end

  --- Get the key of an injection based on the paragraph
  --- @param paragraph string multiline string to look for a key
  local function get_key(paragraph)
    current_key = paragraph:match('#set! injection.language "(.-)"')
    paragraph = paragraph:gsub(";+%s*extends%s*\n", "")
    paragraph = paragraph:gsub(";+%s*inherits.*\n", "")

    local first_line = paragraph:match("([^\n]*)")
    if standard_or_custom == "custom" and first_line:sub(1, 1) == ";" then
      -- first priority: the custom id in the first line
      current_key = first_line:sub(2)
      current_key = current_key:match("^%s*;*%s*(.-)%s*$")
      current_key = current_key:gsub('[%s%@()."]', "")
      res[current_key] = { order = startcnt.order, enabled = true, code = "" }
      startcnt.order = startcnt.order + 1
    elseif current_key ~= nil then
      -- second priority: The target injection language
      if res[current_key] ~= nil then
        -- There is another injection with the same target injection language
        local cnt = 1
        while res[current_key .. "_" .. cnt] ~= nil do
          cnt = cnt + 1
        end
        current_key = current_key .. "_" .. cnt
        startcnt.cnt = startcnt.cnt + 1
      end
      res[current_key] = { order = startcnt.order, enabled = true, code = "" }
      startcnt.order = startcnt.order + 1
    else
      -- third priority: just the language with the order
      current_key = lang .. "_" .. startcnt.order
      if res[current_key] ~= nil then
        vim.notify("ERROR parsing file for part = " .. paragraph, vim.log.levels.ERROR)
      end
      res[current_key] = { order = startcnt.order, enabled = true, code = "" }
      startcnt.order = startcnt.order + 1
    end
  end

  -- parse each paragraph
  for _, part in ipairs(parts) do
    get_key(part)
    -- each block is parsed for an ID part
    for line in string.gmatch(part, "[^\r\n]+") do
      parse_line(line)
    end
  end

  -- remove parsed injections with no code (only comments)
  -- Some filenames are from other languages that are included via ;;inherits
  local sourcelang = filename:match("queries/(.-)/")
  for k, v in pairs(res) do
    res[k]["sourcelang"] = sourcelang
    if v["standard_or_custom"] == nil then
      res[k]["standard_or_custom"] = standard_or_custom
    end
    if v.code == "" then
      res[k] = nil
    end
  end

  return res
end

--- Find all languages that have parsers and get the standard injections for them
local paths = vim.api.nvim_get_runtime_file("parser/*.so", true)
-- This loops over languages
for _, lang_path in ipairs(paths) do
  -- print("DEBUG lang_path " .. lang_path)
  local lang = string.match(lang_path, "([^/]-)%.so$")
  local files = vim.treesitter.query.get_files(lang, "injections", nil)
  -- local files = { "/home/konrad/nvimplugins/injectme.nvim/tests/injections_mock.scm" }
  -- custom contains all the files in the user config folder
  local customs = {}
  -- standards contains all files set by nvim-treesitter
  local standards = {}
  -- custom overrides that are stre
  for _, filename in ipairs(files) do
    if string.find(filename, "nvim-treesitter/queries", 1, true) ~= nil then
      table.insert(standards, filename)
    elseif string.find(filename, "after") ~= nil then
      table.insert(customs, filename)
    elseif string.find(filename, "queries") ~= nil then
      table.insert(customs, filename)
    end
  end
  if #standards == 0 and #customs == 0 then
    file_injections[lang] = {}
  end
  local startcnt = { cnt = 1, order = 1 }

  --- Writes the parsed contents to queries
  local function parse_and_set_injections(filename, standard_or_custom)
    local current_parsed = parse_file(filename, lang, startcnt, standard_or_custom)
    if file_injections[lang] == nil then
      file_injections[lang] = {}
    end
    for key, value in pairs(current_parsed) do
      if type(value) == "table" and value["code"] ~= nil then
        if file_injections[lang][key] == nil or file_injections[lang][key]["code"] ~= value["code"] then
          file_injections[lang][key] = value
        end
      end
    end
    return current_parsed
  end

  for _, filename in ipairs(standards) do
    parse_and_set_injections(filename, "standard")
  end
  for _, filename in ipairs(customs) do
    parse_and_set_injections(filename, "custom")
  end
  -- print("DEBUG lang = " .. lang)

  for k, v in pairs(file_injections[lang]) do
    if v["standard_or_custom"] == "standard_override" then
      local overriden_standard_id = k:match("^(.-)_override$")
      if file_injections[lang][overriden_standard_id] == nil then
        vim.notify("ERROR parsing for language " .. lang, vim.log.levels.ERROR)
        vim.print(file_injections[lang])
      else
        -- print("DEBUG found override " .. k)
        file_injections[lang][overriden_standard_id].enabled = false
        file_injections[lang][k] = nil
      end
    end
  end
end

return file_injections
