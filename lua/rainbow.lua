local queries = require("nvim-treesitter.query")

local M = {}

function M.init()
        require("nvim-treesitter").define_modules({
                rainbow = {
                        module_path = "rainbow.internal",
                        is_supported = function(lang)
                                return queries.get_query(lang, "rainbow") ~= nil
                        end,
                        extended_mode = true,
                        colors = {},
                        termcolors = {},
                },
        })
end

return M
