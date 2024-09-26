# tmux-files

## Requirements

- **Neovim** >= 0.9.4

## Installation

Install the plugin with your package manager:

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "cgimenes/tmux-files.nvim",
  dependencies = {
    'ibhagwan/fzf-lua',
  },
  keys = {
    {
      "<leader>sx",
      function()
        require("tmux-files").select()
      end,
      desc = "Edit file from Tmux panes",
    },
  },
}
```

## Alternative and related projects

- https://github.com/shivamashtikar/tmuxjump.vim
- https://github.com/trevarj/telescope-tmux.nvim
