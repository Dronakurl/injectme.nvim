local preset_injections = {
  html = {
    pythoncode = {
      code = [[
        (element
          (start_tag
            (attribute
              (quoted_attribute_value
                ((attribute_value) @_idd (#eq? @_idd "python")))))
          ((text) @injection.content (#set! injection.language "python")))
      ]],
    },
    luacode = {
      code = [[
        (element
          (start_tag
            (attribute
              (quoted_attribute_value
                ((attribute_value) @_idd (#eq? @_idd "lua")))))
          ((text) @injection.content (#set! injection.language "lua")))
      ]],
    },
  },
  markdown = {
    codeblocks_as_lua = {
      code = [[((code_fence_content) @injection.content (#set! injection.language "lua"))]],
    },
  },
  python = {
    rst_for_docstring = {
      code = [[
      (function_definition
        (block
          (expression_statement
            (string
                (string_content) @injection.content (#set! injection.language "rst")))))
      ]],
    },
    javascript_variables = {
      code = [[
        (assignment
            ((identifier) @_varx (#match? @_varx ".*js$"))
            (string
                (string_content) @injection.content (#set! injection.language "javascript"))) 
      ]],
    },
    html_variables = {
      code = [[
        (assignment
            ((identifier) @_varx (#match? @_varx ".*html$"))
            (string
                (string_content) @injection.content (#set! injection.language "html"))) 
      ]],
    },
    css_variables = {
      code = [[
        (assignment
            ((identifier) @_varx (#match? @_varx ".*css$"))
            (string
                (string_content) @injection.content (#set! injection.language "css"))) 
      ]],
    },
    style_attribute_css = {
      code = [[
        (call
          function: (attribute
              attribute: (identifier) @_idd (#eq? @_idd "style"))
          arguments: (argument_list
            (string (string_content) @injection.content (#set! injection.language "css")))) 
      ]],
    },
    loads_attribute_json = {
      code = [[
        (call
          function: (attribute
              attribute: (identifier) @_idd (#eq? @_idd "loads"))
          arguments: (argument_list
            (string (string_content) @injection.content (#set! injection.language "json") ) ) )
      ]],
    },
  },
}

for lang, _ in pairs(preset_injections) do
  for k, _ in pairs(preset_injections[lang]) do
    preset_injections[lang][k]["standard_or_custom"] = "custom"
    preset_injections[lang][k]["order"] = 0
    preset_injections[lang][k]["enabled"] = false
    preset_injections[lang][k]["sourcelang"] = lang
  end
end

return preset_injections
