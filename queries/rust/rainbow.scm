[
  "{"
  "}"
  "["
  "]"
  "("
  ")"
] @rainbow.paren

(type_arguments
  "<" @rainbow.paren
  ">" @rainbow.paren)

(type_parameters
  "<" @rainbow.paren
  ">" @rainbow.paren)

[
  (arguments)
  (array_expression)
  (attribute_item)
  (block)
  (declaration_list)
  (field_declaration_list)
  (macro_definition)
  (match_block)
  (meta_arguments)
  (parameters)
  (parenthesized_expression)
  (tuple_pattern)
  (tuple_struct_pattern)
  (type_arguments)
  (type_parameters)
  (unit_type)
  (use_list)
] @rainbow.level
