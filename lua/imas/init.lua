local M = {}

---@type table<string, string>
local modes = {} -- key: mode(string), value: im(string)
---@type table<number, table<string, string>>
local stored_im = {} -- key: buf(number), value: modes(modes)
local default_im = ""
local get_im_cmd = ""
local switch_im_cmd = {} ---@type string[]
local switch_im_para_loc = -1 ---@type number im placeholder index

-- help functions

--- shallo copy a table
---@param t table
---@return table new table
local function tbl_shallow_copy(t)
  local t2 = {}
  for k, v in pairs(t) do
    t2[k] = v
  end
  return t2
end

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
---@param im string im to be switched
local function swich_im(im)
  if switch_im_para_loc ~= -1 then
    switch_im_cmd[switch_im_para_loc] = im
  end
  vim.system(switch_im_cmd, { stderr = false, stdout = false })
end

-- modules functions

--- enter a mode and switch im if necessay
---@param mode string which mode?
---@param buf number which buffer?
function M.im_enter(mode, buf)
  if stored_im[buf] == nil then
    stored_im[buf] = tbl_shallow_copy(modes)
  end
  vim.system({ get_im_cmd }, { text = true, stderr = false }, function(out)
    local cur_im = vim.trim(out.stdout)
    if cur_im ~= default_im then -- not in default im
      return
    elseif stored_im[buf] == nil then -- already BufUnload
      return
    elseif stored_im[buf][mode] == cur_im then
      return
    else
      swich_im(stored_im[buf][mode])
    end
  end)
end

--- leave a mode and switch im if necessay
---@param mode string which mode?
---@param buf number which buffer?
function M.im_leave(mode, buf)
  if stored_im[buf] == nil then
    stored_im[buf] = tbl_shallow_copy(modes)
  end
  vim.system({ get_im_cmd }, { text = true, stderr = false }, function(out)
    local cur_im = vim.trim(out.stdout)
    -- have not BufUnloaded
    if stored_im[buf] ~= nil then
      stored_im[buf][mode] = cur_im
    end
    if cur_im == default_im then
      return
    else
      swich_im(default_im)
    end
  end)
end

--- swich to default im
function M.im_default()
  vim.system({ get_im_cmd }, { text = true, stderr = false }, function(out)
    if vim.trim(out.stdout) == default_im then
      return
    else
      swich_im(default_im)
    end
  end)
end

--- register a mode into modes
---@param mode string what mode?
function M.register(mode)
  modes[mode] = default_im
end


--- setup function for the plugin
---@param user_opts table user config
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
    cmd_os = {},
    mode = {
      insert = "autoswitch",
      search = "autoswitch",
      cmdline = { "leave_default" },
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

  local augroup = vim.api.nvim_create_augroup("imas", { clear = true })

  vim.api.nvim_create_autocmd("BufUnload", {
    callback = function(args)
      if stored_im[args.buf] ~= nil then
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
      enter = { "CmdlineEnter", pattern = { "/", "\\?" } },
      leave = { "CmdlineLeave", pattern = { "/", "\\?" } },
    },
    cmdline = {
      enter = { "CmdlineEnter", pattern = ":" },
      leave = { "CmdlineLeave", pattern = ":" },
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
      M.register(mode)
      vim.api.nvim_create_autocmd(mode_autocmd.enter[1], {
        callback = function(args)
          M.im_enter(mode, args.buf)
        end,
        pattern = mode_autocmd.enter.pattern,
        group = augroup,
      })
      vim.api.nvim_create_autocmd(mode_autocmd.leave[1], {
        callback = function(args)
          M.im_leave(mode, args.buf)
        end,
        pattern = mode_autocmd.leave.pattern,
        group = augroup,
      })
    elseif mode_opt == "default" then
      vim.api.nvim_create_autocmd({ mode_autocmd.enter[1], mode_autocmd.leave[1] }, {
        callback = M.im_default,
        group = augroup,
      })
    elseif type(mode_opt) == "table" and vim.islist(mode_opt) then
      for _, v in ipairs(mode_opt) do
        if v == "enter_default" then
          vim.api.nvim_create_autocmd(mode_autocmd.enter[1], {
            callback = M.im_default,
            pattern = mode_autocmd.enter.pattern,
            group = augroup,
          })
        elseif v == "leave_default" then
          vim.api.nvim_create_autocmd(mode_autocmd.leave[1], {
            callback = M.im_default,
            pattern = mode_autocmd.leave.pattern,
            group = augroup,
          })
        end
      end
    else
      print("Wrong mode spec of", mode, "mode!")
    end
    ::continue::
  end
end

return M
