local queries = require("nvim-treesitter.query")
local nvim_query = require("vim.treesitter.query")
local parsers = require("nvim-treesitter.parsers")
local configs = require("nvim-treesitter.configs")
local nsid = vim.api.nvim_create_namespace("rainbow_ns")
local colors = require("rainbow.colors")
local termcolors = require("rainbow.termcolors")
local state_table = {} -- tracks which buffers have rainbow disabled
local extended_languages = {
        "bash",
        "html",
        "jsx",
        "latex",
        "lua",
        "ocaml",
        "ruby",
        "verilog",
        "json",
        "yaml",
}

-- finds the nesting level of given node
local function color_no(mynode, len, levels)
        local counter = 0
        local current = mynode:parent() -- we don't want to count the current node
        while current:parent() ~= nil do
                if levels[current:type()] then
                        counter = counter + 1
                end
                current = current:parent()
        end
        if (counter % len == 0) then
                return len
        else
                return (counter % len)
        end
end

-- get the rainbow level nodes for a specific syntax
local function get_rainbow_levels(bufnr, root, lang)
        local matches =
                queries.get_capture_matches(bufnr, "@rainbow.level", "rainbow", root, lang)
        local levels = {}
        for _, node in ipairs(matches) do
                levels[node.node:type()] = true
        end

        return levels
end

local callbackfn = function(bufnr, parser)
        -- no need to do anything when pum is open
        if vim.fn.pumvisible() == 1 then
                return
        end

        --clear highlights or code commented out later has highlights too
        vim.api.nvim_buf_clear_namespace(bufnr, nsid, 0, -1)
        parser:parse()
        parser:for_each_tree(function(tree, lang_tree)
                local root_node = tree:root()

                local lang = lang_tree:lang()
                local query = queries.get_query(lang, "rainbow")
                local levels = get_rainbow_levels(bufnr, root_node, lang)

                if query ~= nil then
                        for capture, node, _ in query:iter_captures(root_node, bufnr) do
                                if query.captures[capture] == "rainbow.paren" then
                                        -- set colour for this nesting level
                                        local color_no_ = color_no(node, #colors, levels)
                                        -- range of the capture, zero-indexed
                                        local _, startCol, endRow, endCol = node:range()
                                        vim.highlight.range(
                                                bufnr,
                                                nsid,
                                                "rainbowcol" .. color_no_,
                                                { endRow, startCol },
                                                { endRow, endCol - 1 },
                                                "blockwise",
                                                true
                                        )
                                end
                        end
                end
        end)
end

local function try_async(f, bufnr, parser)
        local cancel = false
        return function()
                if cancel then
                        return true
                end
                local async_handle
                async_handle = vim.loop.new_async(vim.schedule_wrap(function()
                        f(bufnr, parser)
                        async_handle:close()
                end))
                async_handle:send()
        end, function()
                cancel = true
        end
end

local function register_predicates(config)
        for _, lang in ipairs(extended_languages) do
                local enable_extended_mode
                if type(config.extended_mode) == "table" then
                        enable_extended_mode = config.extended_mode[lang]
                else
                        enable_extended_mode = config.extended_mode
                end
                nvim_query.add_predicate(lang .. "-extended-rainbow-mode?", function()
                        return enable_extended_mode
                end, true)
        end
end

local function merge_tables(t1, t2)
        local merged = {}
        for i, v in ipairs(t1) do
                merged[i] = v
        end
        for i, v in ipairs(t2) do
                merged[i] = v
        end
        return merged
end

-- define highlight groups
colors = merge_tables(colors, configs.get_module("rainbow").colors)
termcolors = merge_tables(termcolors, configs.get_module("rainbow").termcolors)
for i = 1, #colors do
        local s = "highlight default rainbowcol"
                .. i
                .. " guifg="
                .. colors[i]
                .. " ctermfg="
                .. termcolors[i]
        vim.cmd(s)
end

local M = {}

function M.attach(bufnr, lang)
        local parser = parsers.get_parser(bufnr, lang)
        local config = configs.get_module("rainbow")
        register_predicates(config)

        local attachf, detachf = try_async(callbackfn, bufnr, parser)
        state_table[bufnr] = detachf
        callbackfn(bufnr, parser) -- do it on attach
        vim.api.nvim_buf_attach(bufnr, false, { on_lines = attachf }) --do it on every change
end

function M.detach(bufnr)
        local detachf = state_table[bufnr]
        detachf()
        local hlmap = vim.treesitter.highlighter.hl_map
        hlmap["punctuation.bracket"] = "TSPunctBracket"
        vim.api.nvim_buf_clear_namespace(bufnr, nsid, 0, -1)
end

return M
