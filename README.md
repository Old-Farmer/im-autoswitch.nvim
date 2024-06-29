# 🛺im-autoswitch.nvim

A highly configurable & flexible input method(im) auto-switch plugin for neovim

## ✨Features

1. 🛺Auto switch input methods between modes(e.g. keep im default in normal mode, restore im in other mode if necessary)
2. 📚Manage input method states per buffer respectively
3. ⚙️High configurability and flexibility for different input methods, im switch behaviors and OSs
4. 🚀Blazingly fast because external commands are executed asynchronously
5. 💻[VSCode Neovim](https://github.com/vscode-neovim/vscode-neovim) compatible

## ⚡️ Requirements

- neovim >= 0.10.0
- An im switch tool is needed. For Linux, if you use fcitx, check `fcitx-remote` or `fcitx5-remote`; for Windows or MacOS, check `im-select`: [im-select](https://github.com/daipeihust/im-select).

## 📦Installation

Installing this plugin is very easy!

With lazy.nvim

```lua
-- e.g. fcitx5 v5.0.14
{
  "Old-Farmer/im-autoswitch.nvim",
  event = "BufEnter",
  opts = {
    cmd = {
      -- default im
      default_im = "1",
      -- get current im
      get_im_cmd = "fcitx5-remote",
      -- cmd to switch im. the plugin will put an im name in "{}"
      -- or
      -- cmd to switch im between active/inactive
      switch_im_cmd = "fcitx5-remote -t",
    },
  },
}
```

## ⚙️Configuration

Default Configuration

```lua
{
  -- fallback cmd, check "cmd_os" bellow
  cmd = {
    default_im = "", -- default im
    get_im_cmd = "", -- get current im, output will be trimmed by this plugin
    switch_im_cmd = "", -- cmd to switch im; use {} as an im placholder
                        -- or just a cmd which switches im between active/inactive
  },
  cmd_os = {}, -- specify your per OS cmd here, the plugin will check your current environment
               -- and fallback to "cmd" if necessary
               -- leave it empty and only set "cmd" if you use only one OS
               -- see the following example!!
               -- keys in "cmd_os" can be set to different OS names:
               -- for linux is "linux", for windows is "windows" and for macos is "macos"
               -- for other OSs, use `vim.uv.os_uname().sysname` to get your OS name, then
               -- use this name as a key in cmd_os
  --[[
  -- e.g. to specify your linux cmd
  cmd_os = {
    linux = {
      default_im = "",
      get_im_cmd = "",
      switch_im_cmd = "",
    }
  }
  --]]

  -- im swich behaviors per mode
  mode = {
    -- mode spec:
    -- "autoswitch"(string): smart im-autoswitch
    -- "default"(string): always back to default im
    -- { "enter_default", "leave_default" }(string[]): back to default im at enter & leave
    -- false(boolean): do nothing
    insert = "autoswitch", -- im-autoswitch trigger at InsertEnter/InsertLeave
    search = "autoswitch", -- im-autoswitch trigger at CmdlineEnter/CmdlineLeave(/ or \?)
    cmdline = { "leave_default" }, -- not back to default im at CmdlineEnter(:) by default
                                    -- because some ims can't produce ":" directly;
                                    -- back to default im at CmdlineLeave(:)
    terminal = "default", -- always back to default im at TermEnter/TermLeave
  },
}
```

## ⚠️Limitation

- No effect in ssh. This plugin will not be loaded in ssh environment.

## 🚀Advanced Usage

You can call module functions of im-autoswitch.nvim directly for more flexible use.

```lua
-- just go back to default im
require("imas").im_default()

-- or

-- first register a mode(string). "insert" "search" "cmdline" "terminal" are all reserved
local mode = "xxx"
require("imas").register(mode)

-- then use the following two functions to switch im as you need
-- the type of buf is number, and can be get from vim.api.nvim_get_current_buf()
-- or autocmd callback parameter: opts.buf
require("imas").im_enter(mode, buf) -- restore im if your are in default im
require("imas").im_leave(mode, buf) -- go back to default im, and store current im state
```

## 📦Other Similar (Neo)Vim Plugins

- [fcitx.nvim](https://github.com/h-hg/fcitx.nvim)
- [im-select.nvim](https://github.com/keaising/im-select.nvim)
- [fcitx.vim](https://github.com/lilydjwg/fcitx.vim)
- [vim-barbaric](https://github.com/rlue/vim-barbaric)

## 🤝Contribution

`PRs` of any kind are welcome!
