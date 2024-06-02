# im-autoswitch.nvim

A highly configurable and expansible input method(im) auto-switch plugin for neovim

## Features

1. Auto restore & switch input method between modes(i.e. keep im default in normal mode, restore im in other mode if necessary)
2. Manage input method states for every buffer respectively
3. High configurability && expandability no matter what input method framework you use
4. Blazingly fast because external commands are executed asynchronously

## Requirements

Require neovim >= 0.10.0

## Getting Started

With lazy.nvim

```lua
{
  "Old-Farmer/im-autoswitch.nvim",
  opts = {
    -- mandatory
    cmd = {
      default_im = "", -- default im
      get_im_cmd = "", -- get current im, output will be trimmed by this plugin
      switch_im_cmd = "", -- cmd to switch im; use {} as an im placholder
                          -- or just a cmd which switches im between active/inactive
    },

    -- optinal
    -- leave them empty if you like the default
    mode = {
      insert = true, -- im-autoswitch trigger at InsertEnter/InsertLeave
      search = true, -- im-autoswitch trigger at search(/ or ?)
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

## Advanced usage

you may want to use im-autoswitch to other places, I have a solution.

```lua
-- first register a mode(string). "insert" & "search" have already been used by default.
local mode = "xxx"
require("imas").register(mode)

-- then use the following two functions to switch im as you need
-- buf can be get from vim.apt.nvim_get_current_buf()
-- or autocmd callback parameter
require("imas").im_enter(mode, buf) -- restore im if your are in default im
require("imas").im_leave(mode, buf) -- go back to default im
```
