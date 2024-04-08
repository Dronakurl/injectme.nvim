local preset_injections = {
  go = {
    sql = {
      code = [[; SQL syntax highlighting within strings (NVIM v0.9.4)
(
    [
        (raw_string_literal)
        (interpreted_string_literal)
    ] @injection.content
    (#match? @injection.content "(SELECT|INSERT|UPDATE|DELETE).+(FROM|INTO|VALUES|SET).*(WHERE|GROUP BY)?")
    (#set! injection.language "sql")
)]],
      description = "SQL syntax highlighting within strings (NVIM v0.10.0)",
    },
  },
  typescript = {
    sql_for_parts = {
      code = [[
(
    [
        (string_fragment)
    ] @injection.content
    (#match? @injection.content "(SELECT|INSERT|UPDATE|DELETE).+(FROM|INTO|VALUES|SET).*(WHERE|GROUP BY)?")
    (#set! injection.language "sql")
)
(
    [
        (template_string)
    ] @injection.content
    (#match? @injection.content "(SELECT|INSERT|UPDATE|DELETE).+(FROM|INTO|VALUES|SET).*(WHERE|GROUP BY)?")
    (#offset! @injection.content 0 1 0 -1)
    (#set! injection.language "sql")
)
      ]],
      description = "SQL syntax highlighting within strings (NVIM v0.10.0)",
    },
  },
  javascript = {
    sql_for_parts = {
      code = [[
(
    [
        (string_fragment)
    ] @injection.content
    (#match? @injection.content "(SELECT|INSERT|UPDATE|DELETE).+(FROM|INTO|VALUES|SET).*(WHERE|GROUP BY)?")
    (#set! injection.language "sql")
)
(
    [
        (template_string)
    ] @injection.content
    (#match? @injection.content "(SELECT|INSERT|UPDATE|DELETE).+(FROM|INTO|VALUES|SET).*(WHERE|GROUP BY)?")
    (#offset! @injection.content 0 1 0 -1)
    (#set! injection.language "sql")
)
      ]],
      description = "SQL syntax highlighting within strings (NVIM v0.10.0)",
    },
    quotes_indicator = {
      code = [[
; variable (with angled quotes)
; /* html */ `<html>`
; /* sql */ `SELECT * FROM foo`
(variable_declarator
	(comment) @injection.language (#offset! @injection.language 0 3 0 -3)
	(template_string) @injection.content (#offset! @injection.content 0 1 0 -1)
	)

; variable (with single/double quotes)
(variable_declarator
	(comment) @injection.language (#offset! @injection.language 0 3 0 -3)
	(string (string_fragment) @injection.content)
	)

; argument (with angled quotes)
; foo(/* html */ `<span>`)
; foo(/* sql */ `SELECT * FROM foo`)
(call_expression
	arguments:
	[
	 (arguments
		 (comment) @injection.language (#offset! @injection.language 0 3 0 -3)
		 (template_string) @injection.content (#offset! @injection.content 0 1 0 -1)
		 )
	 ]
	)

; argument (with single/double quotes)
(call_expression
	arguments:
	[
	 (arguments
		 (comment) @injection.language (#offset! @injection.language 0 3 0 -3)
		 (string (string_fragment) @injection.content)
		 )
	 ]
	)
  ]],
      description = [[
const myhtml = /* html */ ` <html> <body></body> </html> `;
const mysql = /* sql */ `SELECT * FROM foo`;
foo(/* html */ `<span>`)]],
    },
  },
  html = {
    xdata = {
      code = [[
((element
  (start_tag
    (attribute
      (attribute_name) @_name
      (quoted_attribute_value (attribute_value) @injection.content))))
 (#eq? @_name "x-data")
  (#set! injection.language javascript))
    ]],
      description = "x-data element attributes as javascript",
    },
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
      description = "bash highlighting in lua vim.system and vim.fn.system",
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
      (#match? @html "*DOCTYPE.*")
      (#set! injection.language "html")
      ) @injection.content]],
      description = "HTML syntax in all text elements which have a DOCTYPE substring",
    },
  },
  python = {
    vue_for_add_slot = {
      code = [[
(call
  function: (attribute attribute: (identifier) @id (#match? @id "add_slot"))
  arguments: (argument_list
     (string (string_content) @injection.content (#set! injection.language "vue"))))
      ]],
      description = "In NiceGUI, you can add a template slot for elements. This is in ",
    },
    sql_in_call = {
      code = [[
(call
  function: (attribute attribute: (identifier) @id (#match? @id "execute|read_sql"))
  arguments: (argument_list
     (string (string_content) @injection.content (#set! injection.language "sql"))))
     ]],
      description = "SQL syntax for strings which reside inside a `execute` or `read_sql` funciton call",
    },
    all_sql = {
      code = [[

  (string 
    (string_content) @injection.content
      (#vim-match? @injection.content "^\w*SELECT|FROM|INNER JOIN|WHERE|CREATE|DROP|INSERT|UPDATE|ALTER.*$")
      (#set! injection.language "sql"))
]],
      description = "SQL syntax for all strings containing uppercase SQL commands",
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
            ((identifier) @_varx (#match? @_varx ".*[hH][tT][mM][lL]$"))
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
