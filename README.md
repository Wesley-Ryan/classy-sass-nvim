# Classy SASS Neovim

![Neovim](https://img.shields.io/badge/Neovim-%3E=0.8-green)
![License](https://img.shields.io/badge/License-MIT-blue)

### Better comments for your SASS
A Neovim plugin that automatically adds helpful selector path comments to your SCSS/SASS/CSS files, making it easier to understand nested selector hierarchies. Particularly useful for BEM (Block Element Modifier) methodology, helping you visualize complete selector paths.

## Features

Perfect for BEM methodology: visualize complete selector paths with nested blocks and elements
Automatically adds selector path comments before opening braces
Supports SCSS, SASS, and CSS files
Handles nested selectors with parent references (&)
Safe error handling with optional silent mode
Configurable indentation width
Optional automatic file saving after adding comments

## Defaults

| Option       | Default  | Description                           |
|--------------|----------|---------------------------------------|
| indent_width | 2        | Width of indentation                 |
| silent       | false    | Suppress error messages              |
| auto_write   | true     | Auto-save after adding comments      |


## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "Wesley-Ryan/classy-sass-nvim",
    config = function()
        require("classy_sass").setup({
            indent_width = 2  -- optional: defaults to 2
        })
    end
}
```

## Configuration

```lua
require("classy_sass").setup({
    indent_width = 2,       -- Width of indentation (default: 2)
    silent = false,         -- Suppress error messages (default: false)
    auto_write = true      -- Auto-save file after adding comments (default: true)
})
```

## Usage

The plugin provides two ways to add SCSS comments:

1. Use the command `:AddSCSSComments`
2. Use the default keybinding `<leader>ac` (or your custom keybinding)

### Example

Input SCSS:
```scss
.parent {

  &__child {
    color: #dc8a78;

    &.is-active {
      color: #8839ef;
    }

    &--modifier {
      color: #e64553;

      .something-else {
        color: #df8e1d;
      }
    }
  }

  // .parent__other-child
  &__other-child {
    color: green;
  }
}
```

Output SCSS with comments:
```scss
.parent {
  // .parent__child
  &__child {
    color: #dc8a78;

    // .parent__child.is-active
    &.is-active {
      color: #8839ef;
    }

    // .parent__child--modifier
    &--modifier {
      color: #e64553;

      // .parent__child--modifier .something-else
      .something-else {
        color: #df8e1d;
      }
    }
  }

  // .parent__other-child
  &__other-child {
    color: #40a02b;
  }
}
```

## Credits
This plugin is a Neovim implementation inspired by the [SCSS-Comments VSCode extension](https://github.com/stabee/SCSS-Comments) created by stabee. The core concept of automatically generating selector path comments has been adapted for the Neovim ecosystem.

## License

MIT
