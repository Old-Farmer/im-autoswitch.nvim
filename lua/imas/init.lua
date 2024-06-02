local M = {}

local modes = {} -- key: mode(string), value: im(string)
local stored_im = {} -- key: buf(number), value: modes(modes)
local default_im = ""
local get_im_cmd = ""
local switch_im_cmd = {} -- string[]
local switch_im_para_loc = -1 -- im placeholder index

-- help functions

local function tbl_shallow_copy(t)
  local t2 = {}
  for k, v in pairs(t) do
    t2[k] = v
  end
  return t2
end

-- local functions

local function swich_im(im)
  if switch_im_para_loc ~= -1 then
    switch_im_cmd[switch_im_para_loc] = im
  end
  vim.system(switch_im_cmd):wait()
end

local function init_buf(buf)
  stored_im[buf] = tbl_shallow_copy(modes)
end

local function del_buf(buf)
  stored_im[buf] = nil
end

-- modules functions

function M.im_enter(mode, buf)
  local cur_im = vim.trim(vim.system({ get_im_cmd }, { text = true }):wait().stdout)
  if cur_im ~= default_im or stored_im[buf][mode] == cur_im then
    return
  else
    swich_im(stored_im[buf][mode])
  end
end

function M.im_leave(mode, buf)
  stored_im[buf][mode] = vim.trim(vim.system({ get_im_cmd }, { text = true }):wait().stdout)
  if stored_im[buf][mode] == default_im then
    return
  else
    swich_im(default_im)
  end
end

function M.register(mode)
  modes[mode] = default_im
end

function M.setup(user_opts)
  -- In ssh
  if vim.env.SSH_CLIENT ~= nil or vim.env.SSH_TTY ~= nil then
    return
  end

  local default_opts = {
    cmd = {
      default_im = "",
      get_im_cmd = "",
      switch_im_cmd = "",
    },
    -- optional
    mode = {
      insert = true,
      search = true,
    },
  }

  local opts = vim.tbl_deep_extend("force", default_opts, user_opts)

  default_im = opts.cmd.default_im
  get_im_cmd = opts.cmd.get_im_cmd
  switch_im_cmd = vim.split(opts.cmd.switch_im_cmd, " ", { trimempty = true })

  for index, value in ipairs(switch_im_cmd) do
    if value == "{}" then
      switch_im_para_loc = index
      break
    end
  end

  local augroup = vim.api.nvim_create_augroup("imas", { clear = true })

  vim.api.nvim_create_autocmd("BufAdd", {
    callback = function(args)
      init_buf(args.buf)
    end,
  })
  vim.api.nvim_create_autocmd("BufDelete", {
    callback = function(args)
      del_buf(args.buf)
    end,
  })

  if opts.mode.insert then
    M.register("insert")
    vim.api.nvim_create_autocmd("InsertEnter", {
      callback = function(args)
        M.im_enter("insert", args.buf)
      end,
      group = augroup,
    })
    vim.api.nvim_create_autocmd("InsertLeave", {
      callback = function(args)
        M.im_leave("insert", args.buf)
      end,
      group = augroup,
    })
  end

  if opts.mode.search then
    M.register("search")
    vim.api.nvim_create_autocmd("CmdlineEnter", {
      callback = function(args)
        M.im_enter("search", args.buf)
      end,
      pattern = "[/?]",
      group = augroup,
    })
    vim.api.nvim_create_autocmd("CmdlineLeave", {
      callback = function(args)
        M.im_leave("search", args.buf)
      end,
      pattern = "[/?]",
      group = augroup,
    })
  end
end

return M
