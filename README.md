# sql-ghosty.nvim

`sql-ghosty.nvim` adds ghost text inlay hints to your SQL insert statements. 

## Example

![image](https://github.com/user-attachments/assets/b826a9df-1a4b-406e-a9c0-9abec91aa93f)

## Description

It tries to solve the problem where you have an sql insert with many columns, and it is very hard to know to which column a value correspond. 
It inserts hints with the column name on each value.

Another approach I sometimes use, is to align the statement with a plugin like [mini.align](https://github.com/echasnovski/mini.align) and edit it in visual-block mode. 
These two approaches are not mutually exclusive, I find them both useful, and choose which one to use depending on the situation.

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
}
```

## User commands

- `:SqlInlayHintsToggle` - toggle hint display
