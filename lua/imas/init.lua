local M = {}

---@type table<number, table<string, string>>
local stored_im = {} -- key: buf(number), value: modes(mode name as key, current im as value)
local default_im = ""
local get_im_cmd = ""
local switch_im_cmd = {} ---@type string[]
local switch_im_para_loc = -1 ---@type number im placeholder index

local swich_im_lock = false -- im lock

-- local functions

--- get os name
local function get_os_name()
  local os_name = vim.uv.os_uname().sysname
  if os_name == "Linux" then
    return "linux"
  elseif os_name == "Windows_NT" then
    return "windows"
  elseif os_name == "Darwin" then
    return "macos"
  else
    return os_name
  end
end

--- switch im using switch_im_cmd
--- swich_im_lock has already been held
---@param im string im to be switched
local function swich_im(im)
  if switch_im_para_loc ~= -1 then
    switch_im_cmd[switch_im_para_loc] = im
  end
  vim.system(switch_im_cmd, { text = true, stderr = false }, function()
    swich_im_lock = false
  end)
end

-- modules functions

--- enter a mode and switch im if necessay.
--- assume buf ids will not wrap very quickly
--- (although wrapping is nearly impossible), same in im_leave
---@param mode string which mode?
---@param buf number which buffer?
function M.im_enter(mode, buf)
  local function inner()
    -- if lock, schedule it later
    -- same in im_leave
    if swich_im_lock then
      vim.schedule(inner)
      return
    end

    swich_im_lock = true
    vim.system({ get_im_cmd }, { text = true, stderr = false }, function(out)
      local cur_im = vim.trim(out.stdout)
      if
        cur_im ~= default_im -- not in default im
        or stored_im[buf] == nil -- already BufUnload, no need to continue
        or stored_im[buf][mode] == cur_im -- in current im
        or stored_im[buf][mode] == nil -- first enter this mode in this buffer
      then
        swich_im_lock = false
      else
        swich_im(stored_im[buf][mode])
      end
    end)
  end

  if stored_im[buf] == nil then
    stored_im[buf] = {}
  end
  inner()
end

--- leave a mode and switch im if necessay
---@param mode string which mode?
---@param buf number which buffer?
function M.im_leave(mode, buf)
  local function inner()
    if swich_im_lock then
      vim.schedule(inner)
      return
    end

    swich_im_lock = true
    vim.system({ get_im_cmd }, { text = true, stderr = false }, function(out)
      local cur_im = vim.trim(out.stdout)
      -- have not BufUnloaded
      -- but if bufunload, still continue because get_im_cmd executes async
      if stored_im[buf] ~= nil then
        stored_im[buf][mode] = cur_im
      end
      if cur_im == default_im then
        swich_im_lock = false
      else
        swich_im(default_im)
      end
    end)
  end

  if stored_im[buf] == nil then
    stored_im[buf] = {}
  end
  inner()
end

--- swich to default im
function M.im_default()
  if swich_im_lock then
    vim.schedule(M.im_default)
    return
  end
  swich_im_lock = true
  vim.system({ get_im_cmd }, { text = true, stderr = false }, function(out)
    if vim.trim(out.stdout) == default_im then
      swich_im_lock = false
    else
      swich_im(default_im)
    end
  end)
end

--- setup function for the plugin
---@param user_opts table user config
function M.setup(user_opts)
  -- In ssh
  if vim.env.SSH_CLIENT ~= nil or vim.env.SSH_TTY ~= nil then
    return
  end

  local default_opts = {
    cmd = {},
    cmd_os = {},
    mode = {
      insert = "autoswitch",
      search = "autoswitch",
      cmdline = "leave_default",
      terminal = "default",
    },
  }

  local opts = vim.tbl_deep_extend("force", default_opts, user_opts)
  local cmd = opts.cmd_os[get_os_name()]

  if cmd == nil then
    cmd = opts.cmd -- fall back to opt.cmd
  end

  default_im = cmd.default_im
  get_im_cmd = cmd.get_im_cmd
  switch_im_cmd = vim.split(cmd.switch_im_cmd, " ", { trimempty = true })

  for index, value in ipairs(switch_im_cmd) do
    if value == "{}" then
      switch_im_para_loc = index
      break
    end
  end

  -- set autocmds

  local augroup = vim.api.nvim_create_augroup("imas", { clear = true })

  vim.api.nvim_create_autocmd("BufUnload", {
    callback = function(args)
      if stored_im[args.buf] then
        stored_im[args.buf] = nil
      end
    end,
    group = augroup,
  })

  local mode_to_autocmd = {
    insert = {
      enter = { "InsertEnter" },
      leave = { "InsertLeave" },
    },
    search = {
      enter = { "CmdlineEnter" },
      leave = { "CmdlineLeave" },
      pattern = { "/", "\\?" },
    },
    cmdline = {
      enter = { "CmdlineEnter" },
      leave = { "CmdlineLeave" },
      pattern = ":",
    },
    terminal = {
      enter = { "TermEnter" },
      leave = { "TermLeave" },
    },
  }

  for mode, mode_opt in pairs(opts.mode) do
    if mode_opt == false then
      goto continue
    end

    local mode_autocmd = mode_to_autocmd[mode]
    if mode_opt == "autoswitch" then
      vim.api.nvim_create_autocmd(mode_autocmd.enter[1], {
        callback = function(args)
          M.im_enter(mode, args.buf)
        end,
        pattern = mode_autocmd.pattern,
        group = augroup,
      })
      vim.api.nvim_create_autocmd(mode_autocmd.leave[1], {
        callback = function(args)
          M.im_leave(mode, args.buf)
        end,
        pattern = mode_autocmd.pattern,
        group = augroup,
      })
    elseif mode_opt == "default" then
      vim.api.nvim_create_autocmd({ mode_autocmd.enter[1], mode_autocmd.leave[1] }, {
        callback = M.im_default,
        pattern = mode_autocmd.pattern,
        group = augroup,
      })
    elseif mode_opt == "enter_default" then
      vim.api.nvim_create_autocmd(mode_autocmd.enter[1], {
        callback = M.im_default,
        pattern = mode_autocmd.pattern,
        group = augroup,
      })
    elseif mode_opt == "leave_default" then
      vim.api.nvim_create_autocmd(mode_autocmd.leave[1], {
        callback = M.im_default,
        pattern = mode_autocmd.pattern,
        group = augroup,
      })
    else
      print("Wrong mode spec of", mode, "mode!")
    end
    ::continue::
  end
end

return M
