local M = {}

local stored_im = { insert = "", cmdline = "" }
local default_im = ""
local get_im_cmd = ""
local switch_im_cmd = {}
local switch_im_para_loc = -1

-- ref https://stackoverflow.com/questions/1426954/split-string-in-lua
local function str_split(str, sep)
	if sep == nil then
		sep = "%s"
	end
	local t = {}
	for str_ in string.gmatch(str, "([^" .. sep .. "]+)") do
		table.insert(t, str_)
	end
	return t
end

local function str_trim(str)
	if str == nil then
		return ""
	end
	return (str:gsub("^%s*(.-)%s*$", "%1"))
end

local function swich_im(im)
	if switch_im_para_loc ~= -1 then
		switch_im_cmd[switch_im_para_loc] = im
	end
	vim.system(switch_im_cmd):wait()
end

function M.im_enter(mode)
	local cur_im = str_trim(vim.system({ get_im_cmd }, { text = true }):wait().stdout)
	if cur_im ~= default_im or stored_im[mode] == cur_im then
		return
	else
		swich_im(stored_im[mode])
	end
end

function M.im_leave(mode)
	stored_im[mode] = str_trim(vim.system({ get_im_cmd }, { text = true }):wait().stdout)
	if stored_im[mode] == default_im then
		return
	else
		swich_im(default_im)
	end
end

function M.register(mode)
	stored_im[mode] = default_im
end

function M.setup(opts)
	-- In ssh
	if vim.env.SSH_CLIENT ~= nil or vim.env.SSH_TTY ~= nil then
		return
	end

	default_im = opts.default_im
	get_im_cmd = opts.get_im_cmd
	switch_im_cmd = str_split(opts.switch_im_cmd)

	for index, value in ipairs(switch_im_cmd) do
		if value == "{}" then
			switch_im_para_loc = index
			break
		end
	end

	M.register("insert")
	M.register("search")

	local augroup = vim.api.nvim_create_augroup("imas", { clear = true })

	vim.api.nvim_create_autocmd("InsertEnter", {
		callback = function()
			M.im_enter("insert")
		end,
		group = augroup,
	})
	vim.api.nvim_create_autocmd("InsertLeave", {
		callback = function()
			M.im_leave("insert")
		end,
		group = augroup,
	})
	vim.api.nvim_create_autocmd("CmdlineEnter", {
		callback = function()
			M.im_enter("search")
		end,
		pattern = "[/?]",
		group = augroup,
	})
	vim.api.nvim_create_autocmd("CmdlineLeave", {
		callback = function()
			M.im_leave("search")
		end,
		pattern = "[/?]",
		group = augroup,
	})
end

return M
