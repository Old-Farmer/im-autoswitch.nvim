# Examples

## Basic examples

### For windows

```lua
{
  "Old-Farmer/im-autoswitch.nvim",
  event = "BufEnter",
  opts = {
    cmd = {
      default_im = "2052",
      get_im_cmd = "im-select",
      switch_im_cmd = "im-select {}",
    },
  },
}
```

### For MacOS

...

## Advanced examples

### Just keep the default im in normal mode

```lua
{
  "Old-Farmer/im-autoswitch.nvim",
  event = "BufEnter",
  opts = {
    -- ..
    mode = {
      insert = { "leave_default" },
      search = { "leave_default" },
      cmdline = { "leave_default" },
      terminal = { "leave_default" },
    },
  },
}
```

