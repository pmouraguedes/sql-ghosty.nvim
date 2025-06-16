# sql-ghosty.nvim

`sql-ghosty.nvim` adds ghost text inlay hints to your SQL insert statements.

## Example

![image](https://github.com/user-attachments/assets/b826a9df-1a4b-406e-a9c0-9abec91aa93f)

## Description

Addresses the challenge of managing SQL inserts with numerous columns, where it’s difficult to map values to their corresponding columns.
It embeds hints with the column name alongside each value.

Another approach I sometimes use, is to align the statement with a plugin like mini.align and edit it in visual-block mode.
These approaches are complementary, each valuable in different scenarios, allowing me to choose the best method based on the context.

## Features

- robust SQL parsing by leveraging tree-sitter
- ability to toggle hints with the `:SqlInlayHintsToggle` command

## Requirements

- nvim-treesitter with SQL parser installed

## Instalation
```lua
{
  "pmouraguedes/sql-ghosty.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {},
}
```

## Configuration

### Default settings

```lua
{
    -- if set to false the user needs to enable hints manually with :SqlInlayHintsToggle
    show_hints_by_default = true,
    highlight_group = "DiagnosticHint",
}
```

## User commands

- `:SqlInlayHintsToggle` - toggle hint display
