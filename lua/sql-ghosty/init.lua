local M = {}

---@alias SqlGhostyOptions
---| 'show_hints_by_default'

--- @type table<SqlGhostyOptions, any>
local default_config = {
	show_hints_by_default = true,
	highlight_group = "DiagnosticHint",
}

M.config = default_config

-- Namespace for extmarks
local ns_id = vim.api.nvim_create_namespace("sql_inlay_hints")

--- @param node TSNode
local function get_node_type(node)
	if node and type(node) == "userdata" and node.type then
		return node:type()
	end
	return nil
end

--- @param node TSNode insert node to process
--- @param bufnr number buffer number
--- @return string? schema
--- @return string? table_name
--- @return table<string> columns
--- @return table<table<{text: string, row: number, col: number}>> value_rows
--- @return integer? values_start_pos The (row, col) position of the VALUES clause or nil if not found.
local function process_insert_node(node, bufnr)
	local schema = nil
	local table_name = nil
	local columns = {}
	local value_rows = {}
	local values_start_pos = nil

	-- Traverse child nodes of the insert node
	for child in node:iter_children() do
		local child_type = get_node_type(child)
		if not child_type then
			vim.notify("Skipping invalid node: " .. vim.inspect(child), vim.log.levels.DEBUG)
			goto continue
		end

		if child_type == "object_reference" then
			local schema_node = child:field("schema")[1]
			if schema_node then
				schema = vim.treesitter.get_node_text(schema_node, bufnr) or ""
			end
			local table_node = child:field("name")[1]
			if table_node then
				table_name = vim.treesitter.get_node_text(table_node, bufnr) or ""
			end
		elseif child_type == "list" then
			-- First list is columns, second is values
			if #columns == 0 then
				-- Column list
				for col_node in child:iter_children() do
					if get_node_type(col_node) == "column" then
						for subchild in col_node:iter_children() do
							if get_node_type(subchild) == "identifier" then
								local col_text = vim.treesitter.get_node_text(subchild, bufnr)
								if col_text then
									table.insert(columns, col_text)
								end
							end
						end
					end
				end
			else
				-- Values list (one row)
				local row_values = {}
				for val_node in child:iter_children() do
					if get_node_type(val_node) == "literal" then
						local val_text = vim.treesitter.get_node_text(val_node, bufnr)
						local start_row, start_col = val_node:start()
						if val_text and start_row and start_col then
							table.insert(row_values, { text = val_text, row = start_row, col = start_col })
						end
					end
				end
				if #row_values > 0 then
					table.insert(value_rows, row_values)
				end
				if not values_start_pos then
					values_start_pos = child:start()
				end
			end
		end
		::continue::
	end

	return schema, table_name, columns, value_rows, values_start_pos
end

--- @param node TSNode
--- @param bufnr number
local function add_ghost_text_for_insert(node, bufnr)
	local schema, table_name, columns, value_rows, _ = process_insert_node(node, bufnr)
	if not table_name or #columns == 0 or #value_rows == 0 then
		-- vim.notify(
		-- 	"Incomplete insert node: "
		-- 		.. vim.inspect({ schema = schema, table_name = table_name, columns = #columns, values = #value_rows }),
		-- 	vim.log.levels.TRACE
		-- )
		return
	end

	if #columns == 0 then
		return
	end

	-- Add ghost text for each value
	for _, row in ipairs(value_rows) do
		for i, value in ipairs(row) do
			if i > #columns then
				break
			end
			vim.api.nvim_buf_set_extmark(bufnr, ns_id, value.row, value.col, {
				virt_text = { { columns[i] .. ": ", M.config.highlight_group } },
				virt_text_pos = "inline",
			})
		end
	end
end

local function show_sql_inlay_hints()
	local bufnr = vim.api.nvim_get_current_buf()
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "sql")
	if not ok or not parser then
		vim.notify("Failed to get SQL parser", vim.log.levels.ERROR)
		return
	end

	local tree = parser:parse()[1]
	if not tree then
		vim.notify("No parse tree available", vim.log.levels.WARN)
		return
	end

	local root = tree:root()
	if not root then
		vim.notify("No root node in parse tree", vim.log.levels.WARN)
		return
	end

	-- Clear previous inlay hints
	vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

	-- Iterate over statement nodes
	for statement_node, _ in root:iter_children() do
		if get_node_type(statement_node) == "statement" then
			for child in statement_node:iter_children() do
				if get_node_type(child) == "insert" then
					add_ghost_text_for_insert(child, bufnr)
				end
			end
		end
	end
end

M.setup = function(opts)
	M.config = vim.tbl_extend("force", default_config, opts or {})
	local cfg = M.config

	vim.api.nvim_create_autocmd({ "BufEnter" }, {
		pattern = "*.sql",
		callback = function()
			if cfg.show_hints_by_default then
				show_sql_inlay_hints()
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
		pattern = "*.sql",
		callback = function()
			if cfg.show_hints_by_default then
				show_sql_inlay_hints()
			end
		end,
	})

	-- Command to toggle inlay hints manually
	vim.api.nvim_create_user_command("SqlInlayHintsToggle", function()
		if vim.bo.filetype ~= "sql" then
			vim.notify("SqlInlayHintsToggle only works in SQL buffers, see :h setfiletype", vim.log.levels.WARN)
			return
		end

		if cfg.show_hints_by_default then
			vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
			cfg.show_hints_by_default = false
		else
			show_sql_inlay_hints()
			cfg.show_hints_by_default = true
		end
	end, {})
end

return M
