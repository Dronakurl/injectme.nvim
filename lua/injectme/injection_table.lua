M = {}
M.injections = {
  html = {
    pythoncode = {
      enabled = false,
      code = [[
        (element
          (start_tag
            (attribute
              (quoted_attribute_value
                ((attribute_value) @_idd (#eq? @_idd "python")))))
          ((text) @injection.content (#set! injection.language "python")))
      ]],
    },
  },
  markdown = {
    codeblocks_as_lua = {
      enabled = false,
      code = [[((code_fence_content) @injection.content (#set! injection.language "lua"))]],
    },
  },
  python = {
    rst_for_docstring = {
      enabled = false,
      code = [[
      (function_definition
        (block
          (expression_statement
            (string
                (string_content) @injection.content (#set! injection.language "rst")))))
      ]],
    },
    javascript_variables = {
      enabled = false,
      code = [[
        (assignment
            ((identifier) @_varx (#match? @_varx ".*js$"))
            (string
                (string_content) @injection.content (#set! injection.language "javascript"))) 
      ]],
    },
    html_variables = {
      enabled = false,
      code = [[
        (assignment
            ((identifier) @_varx (#match? @_varx ".*html$"))
            (string
                (string_content) @injection.content (#set! injection.language "html"))) 
      ]],
    },
    css_variables = {
      enabled = false,
      code = [[
        (assignment
            ((identifier) @_varx (#match? @_varx ".*css$"))
            (string
                (string_content) @injection.content (#set! injection.language "css"))) 
      ]],
    },
    style_attribute_css = {
      enabled = false,
      code = [[
        (call
          function: (attribute
              attribute: (identifier) @_idd (#eq? @_idd "style"))
          arguments: (argument_list
            (string (string_content) @injection.content (#set! injection.language "css")))) 
      ]],
    },
    loads_attribute_json = {
      enabled = false,
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
return M
