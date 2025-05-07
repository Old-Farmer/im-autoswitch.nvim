local M = {}

---@type table<number, table<string, string>>
local stored_im = {} -- key: buf(number), value: modes(mode name as key, current im as value)
local default_im = ""
local get_im_cmd = {} ---@type string[]
local switch_im_cmd = {} ---@type string[]
local switch_im_para_loc = -1 ---@type number im placeholder index

-- We use an integer order number to gaurantee the im switching order.
-- When an im switching is coming, we give it an order number.
-- If the order is not equal to the current order, it will be scheduled by vim.schedule().
-- The order number is nearly impossible to loop around,
-- so we don't need to think about two im-switching sharing the same order number.

-- We use this simple order mechanism and vim.schedule() to handle fast switching,
-- so users won't pay for this in normal usage.

-- Variables to ensure the order when switching im very fast
local order_generator = 0
local cur_order = 1

local switch_im_lock = false -- im lock

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
--- switch_im_lock has already been held
---@param im string im to be switched
---@param async boolean async or not?
local function switch_im(im, async)
  if switch_im_para_loc ~= -1 then
    switch_im_cmd[switch_im_para_loc] = im
  end

  local function on_exit()
    cur_order = cur_order + 1
    switch_im_lock = false
  end

  if async then
    vim.system(switch_im_cmd, { stdout = false, stderr = false }, on_exit)
  else
    vim.system(switch_im_cmd, { stdout = false, stderr = false }):wait()
    on_exit()
  end
end

--- Generate order
---@return number order
local function gen_order()
  order_generator = order_generator + 1
  return order_generator
end

--- Is this order correct ?
--- @param order number
--- @return boolean
local function is_order_correct(order)
  return cur_order == order
end

--- Do neovim command
---@param command string command is a key sequence;Now command is not translated with nvim_replace_termcodes
local function do_command(command)
  vim.api.nvim_feedkeys(tostring(vim.v.count1) .. command, "n", true)
end

--- enter a mode and switch im if necessary.
--- assume buf ids will not wrap very quickly
--- (although wrapping is nearly impossible), same in im_leave
---@param mode string which mode?
---@param buf number which buffer?
---@param async boolean async or not? NOTE: set async to false only make the function as sync for best effort
function M.im_enter(mode, buf, async)
  local function inner(order, inner_async)
    -- if lock or not in the correct order, schedule it later
    -- same in im_leave
    if switch_im_lock or not is_order_correct(order) then
      vim.schedule(function()
        inner(order, true)
      end)
      return
    end

    local function on_exit(out)
      local cur_im = vim.trim(out.stdout)
      if
        stored_im[buf] == nil -- already BufUnload, no need to continue
        or stored_im[buf][mode] == cur_im -- in current im
        or stored_im[buf][mode] == default_im -- not necessary to switch im when stored_im is default_im
        or stored_im[buf][mode] == nil -- first enter this mode in this buffer
      then
        cur_order = cur_order + 1
        switch_im_lock = false
      else
        switch_im(stored_im[buf][mode], inner_async)
      end
    end

    switch_im_lock = true
    if switch_im_para_loc ~= -1 then
      if stored_im[buf][mode] ~= nil and stored_im[buf][mode] ~= default_im then
        switch_im(stored_im[buf][mode], inner_async)
      else
        cur_order = cur_order + 1
        switch_im_lock = false
      end
    else
      if inner_async then
        vim.system(get_im_cmd, { text = true, stderr = false }, on_exit)
      else
        local out = vim.system(get_im_cmd, { text = true, stderr = false }):wait()
        on_exit(out)
      end
    end
  end

  if stored_im[buf] == nil then
    stored_im[buf] = {}
  end
  inner(gen_order(), async)
end

--- leave a mode and switch im if necessay
---@param mode string which mode?
---@param buf number which buffer?
---@param async boolean async or not? NOTE: set async to false only make the function as sync for best effort
function M.im_leave(mode, buf, async)
  local function inner(order, inner_async)
    if switch_im_lock or not is_order_correct(order) then
      vim.schedule(function()
        inner(order, true)
      end)
      return
    end

    local function on_exit(out)
      local cur_im = vim.trim(out.stdout)
      -- have not BufUnloaded
      -- but if bufunload, still continue because get_im_cmd executes async
      if stored_im[buf] ~= nil then
        stored_im[buf][mode] = cur_im
      end
      if cur_im == default_im then
        cur_order = cur_order + 1
        switch_im_lock = false
      else
        switch_im(default_im, inner_async)
      end
    end

    switch_im_lock = true
    if inner_async then
      vim.system(get_im_cmd, { text = true, stderr = false }, on_exit)
    else
      local out = vim.system(get_im_cmd, { text = true, stderr = false }):wait()
      on_exit(out)
    end
  end

  if stored_im[buf] == nil then
    stored_im[buf] = {}
  end
  inner(gen_order(), async)
end

--- switch to default im
---@param async boolean async or not? NOTE: set async to false only make the function as sync for best effort
function M.im_default(async)
  local function inner(order, inner_async)
    if switch_im_lock or not is_order_correct(order) then
      vim.schedule(function()
        inner(order, true)
      end)
      return
    end

    local function on_exit(out)
      if vim.trim(out.stdout) == default_im then
        cur_order = cur_order + 1
        switch_im_lock = false
      else
        switch_im(default_im, inner_async)
      end
    end

    switch_im_lock = true
    if switch_im_para_loc ~= -1 then
      switch_im(default_im, inner_async)
    else
      if inner_async then
        vim.system(get_im_cmd, { text = true, stderr = false }, on_exit)
      else
        local out = vim.system(get_im_cmd, { text = true, stderr = false }):wait()
        on_exit(out)
      end
    end
  end

  inner(gen_order(), async)
end

--- a wrapper to do im switch when executing command(enter - do - leave)
---@param command string command: explained in do_command
---@param mode string mode
---@param buf number buf
---@param enter_async boolean async or not for im_enter?
---@param leave_async boolean async or not for im_leave?
local function command_wrapper_with_enter_leave(command, mode, buf, enter_async, leave_async)
  M.im_enter(mode, buf, enter_async)
  do_command(command)
  M.im_leave(mode, buf, leave_async)
end

---a wrapper to do im switch when executing command(default - do)
---@param command string command
---@param async boolean async or not?
local function command_wrapper_with_enter_default(command, async)
  M.im_default(async)
  do_command(command)
end

---a wrapper to do im switch when executing command(do - default)
---@param command string command
---@param async boolean async or not?
local function command_wrapper_with_leave_default(command, async)
  do_command(command)
  M.im_default(async)
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
    keymap = {
      r = "r",
      gr = false,
    },
    async = true,
    macos_sync_enter = true,
  }

  local opts = vim.tbl_deep_extend("force", default_opts, user_opts)
  local os = get_os_name()
  local cmd = opts.cmd_os[os]

  if cmd == nil then
    cmd = opts.cmd -- fall back to opt.cmd
  end

  local sync_enter = (os == "macos" and opts.macos_sync_enter)

  default_im = cmd.default_im
  get_im_cmd = vim.split(cmd.get_im_cmd, " ", { trimempty = true })
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
          M.im_enter(mode, args.buf, opts.async and not sync_enter)
        end,
        pattern = mode_autocmd.pattern,
        group = augroup,
      })
      vim.api.nvim_create_autocmd(mode_autocmd.leave[1], {
        callback = function(args)
          M.im_leave(mode, args.buf, opts.async)
        end,
        pattern = mode_autocmd.pattern,
        group = augroup,
      })
    elseif mode_opt == "default" then
      vim.api.nvim_create_autocmd({ mode_autocmd.enter[1], mode_autocmd.leave[1] }, {
        callback = function()
          M.im_default(opts.async)
        end,
        pattern = mode_autocmd.pattern,
        group = augroup,
      })
    elseif mode_opt == "enter_default" then
      vim.api.nvim_create_autocmd(mode_autocmd.enter[1], {
        callback = function()
          M.im_default(opts.async)
        end,
        pattern = mode_autocmd.pattern,
        group = augroup,
      })
    elseif mode_opt == "leave_default" then
      vim.api.nvim_create_autocmd(mode_autocmd.leave[1], {
        callback = function()
          M.im_default(opts.async)
        end,
        pattern = mode_autocmd.pattern,
        group = augroup,
      })
    else
      print("Wrong mode spec of", mode, "mode!")
    end
    ::continue::
  end

  -- set keymap
  for command, lhs in pairs(opts.keymap) do
    -- ignore false
    if not lhs then
      goto continue
    end

    if opts.mode.insert == "autoswitch" then
      vim.keymap.set("n", lhs, function()
        command_wrapper_with_enter_leave(
          command,
          "insert",
          vim.api.nvim_get_current_buf(),
          opts.async and not sync_enter,
          opts.async
        )
      end)
    elseif opts.mode.insert == "enter_default" then
      vim.keymap.set("n", lhs, function()
        command_wrapper_with_enter_default(command, opts.async)
      end)
    elseif opts.mode.insert == "leave_default" then
      vim.keymap.set("n", lhs, function()
        command_wrapper_with_leave_default(command, opts.async)
      end)
    end
    ::continue::
  end
end

return M
