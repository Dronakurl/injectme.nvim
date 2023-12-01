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
      description = "Python syntax in all text elements in HTML that have an attribute set to 'python' ",
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
      description = "Lua syntax in all text elements in HTML that have an attribute set to 'lua' ",
    },
  },
  lua = {
    system_cmd = {
      code = [[
(function_call                                  
  name: ((dot_index_expression) @_mm
    (#any-of? @_mm "vim.fn.system" "vim.system"))
  arguments: (arguments 
    ( string content:  
      (string_content) @injection.content 
      (#set! injection.language "bash"))))]],
      description = "bash highlighting int lua vim.system and vim.fn.system",
    },
  },
  markdown = {
    codeblocks_as_lua = {
      code = [[((code_fence_content) @injection.content (#set! injection.language "lua"))]],
    },
  },
  rust = {
    html_templates = {
      code = [[(
      (raw_string_literal) @html
      (#match? @html ".*DOCTYPE.*")
      (#set! injection.language "html")
      ) @injection.content]],
      description = "HTML syntax in all text elements which have a DOCTYPE substring",
    },
  },
  python = {
    sql_in_call = {
      code = [[(
 call
  function: (attribute attribute: (identifier) @id (#match? @id "execute|read_sql"))
  arguments: (argument_list
     (string (string_content) @sql)
  )
)]],
      description = "SQL syntanx for strings which reside inside a `execute` or `read_sql` funciton call",
    },
    rst_for_docstring = {
      code = [[
      (function_definition
        (block
          (expression_statement
            (string
                (string_content) @injection.content (#set! injection.language "rst")))))
      ]],
      description = "restructured text syntax in all python docstrings",
    },
    javascript_variables = {
      code = [[
        (assignment
            ((identifier) @_varx (#match? @_varx ".*js$"))
            (string
                (string_content) @injection.content (#set! injection.language "javascript"))) 
      ]],
      description = "JavaScript syntax in all strings in assignments of identifiers that end with 'js'",
    },
    html_variables = {
      code = [[
        (assignment
            ((identifier) @_varx (#match? @_varx ".*html$"))
            (string
                (string_content) @injection.content (#set! injection.language "html"))) 
      ]],
      description = "HTML syntax in all strings in assignments of identifiers that end with 'html'",
    },
    css_variables = {
      code = [[
        (assignment
            ((identifier) @_varx (#match? @_varx ".*css$"))
            (string
                (string_content) @injection.content (#set! injection.language "css"))) 
      ]],
      description = "CSS syntax in all strings in assignments of identifiers that end with 'css'",
    },
    style_attribute_css = {
      code = [[
        (call
          function: (attribute
              attribute: (identifier) @_idd (#eq? @_idd "style"))
          arguments: (argument_list
            (string (string_content) @injection.content (#set! injection.language "css")))) 
      ]],
      description = "CSS syntax in all strings in call expressions that are methods named 'style'",
    },
    loads_attribute_json = {
      code = [[
        (call
          function: (attribute
              attribute: (identifier) @_idd (#eq? @_idd "loads"))
          arguments: (argument_list
            (string (string_content) @injection.content (#set! injection.language "json") ) ) )
      ]],
      description = "JSON syntax in all strings in call expressions that are method calls named 'loads'",
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
