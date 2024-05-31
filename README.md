# im-autoswitch.nvim

A highly configurable input method auto-switch plugin for neovim

Require neovim >= 0.10.0

With lazy.nvim

```lua
{
  "Old-Farmer/im-autoswitch.nvim",
  event = "BufEnter",
  opts = {
      default_im = "", -- default input method
      get_im_cmd = "", -- get current input method, output will be trimmed by this plugin
      switch_im_cmd = "", -- switch input method, use {} as an im name placholder,
                          -- or just a cmd which switches input method between active/inactive
  }
}
```

e.g.

```lua
-- fcitx5 v5.0.14
{
  "Old-Farmer/im-autoswitch.nvim",
  event = "BufEnter",
  opts = {
    default_im = "1",
    get_im_cmd = "fcitx5-remote",
    switch_im_cmd = "fcitx5-remote -t",
  },
},

```

im-autoswitch happens in InsertEnter/InsertLeave & CmdlineEnter/CmdlineLeave(just search)

## Advanced usage

you may want to use im-autoswitch to other places, I have the solution.

```lua
-- first register a mode(string). "insert" & "search" have already been used by default.
local mode = "xxx"
require("imas").register(mode)

-- then use the following two function to switch im as you need
require("imas").im_enter(mode) -- restore im if your are in default im
require("imas").im_leave(mode) -- go back to default im
```
