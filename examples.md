# Examples

## Basic examples

### For windows

```lua
{
  "Old-Farmer/im-autoswitch.nvim",
  event = "BufEnter",
  opts = {
    cmd = {
      default_im = "2052", -- 1033 is also possible, based on your settings
      get_im_cmd = "im-select.exe",
      switch_im_cmd = "im-select.exe {}",
    },
  },
}
```

### For MacOS

```lua
{
  "Old-Farmer/im-autoswitch.nvim",
  event = "BufEnter",
  opts = {
    cmd = {
      default_im = "com.apple.keylayout.ABC",
      get_im_cmd = "im-select",
      switch_im_cmd = "im-select {}",
    },
  },
}
```

### Mine

```lua
{
  "Old-Farmer/im-autoswitch.nvim",
  event = "BufEnter",
  opts = {
    cmd_os = {
      linux = {
        default_im = "keyboard-us",
        get_im_cmd = "fcitx5-remote -n",
        switch_im_cmd = "fcitx5-remote -s {}",
      },
      macos = {
        default_im = "com.apple.keylayout.ABC",
        get_im_cmd = "im-select",
        switch_im_cmd = "im-select {}",
      },
      windows = {
        default_im = "1033", -- 2052
        get_im_cmd = "im-select.exe",
        switch_im_cmd = "im-select.exe {}",
      },
    },
    mode = {
      terminal = false,
    },
    check_wsl = true,
  },
}
```

## Advanced examples

### Just keep the default im in normal mode

```lua
{
  "Old-Farmer/im-autoswitch.nvim",
  event = "BufEnter",
  opts = {
    -- ..
    mode = {
      insert = "leave_default",
      search = "leave_default",
      cmdline = "leave_default",
      terminal = "leave_default",
    },
  },
}
```

