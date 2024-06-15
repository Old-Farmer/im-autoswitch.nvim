# 🛺im-autoswitch.nvim

A highly configurable & flexible input method(im) auto-switch plugin for neovim

## ✨Features

1. 🛺Auto restore & switch input method between modes(i.e. keep im default in normal mode, restore im in other mode if necessary)
2. 📚Manage input method states per buffer respectively
3. ⚙️High configurability & flexibility no matter what input method framework you use
4. 🚀Blazingly fast because external commands are executed asynchronously
5. 💻[VSCode Neovim](https://github.com/vscode-neovim/vscode-neovim) compatible

## ⚡️ Requirements

Require neovim >= 0.10.0

## 📦Installation & ⚙️Configuration

With lazy.nvim

```lua
{
  "Old-Farmer/im-autoswitch.nvim",
  event = "BufEnter",
  opts = {
    -- mandatory
    cmd = {
      default_im = "", -- default im
      get_im_cmd = "", -- get current im, output will be trimmed by this plugin
      switch_im_cmd = "", -- cmd to switch im; use {} as an im placholder
                          -- or just a cmd which switches im between active/inactive
    },

    -- optional
    -- leave them empty if you like the default
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
  },
}
```

e.g.

```lua
-- fcitx5 v5.0.14
{
  "Old-Farmer/im-autoswitch.nvim",
  event = "BufEnter",
  opts = {
    cmd = {
      default_im = "1",
      get_im_cmd = "fcitx5-remote",
      switch_im_cmd = "fcitx5-remote -t",
    },
  },
}
```

## ⚠️Limitation

- No effect in ssh. This plugin will not be loaded in ssh environment.

## 🚀Advanced Usage

You can call module functions of im-autoswitch directly for more flexible use.

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
