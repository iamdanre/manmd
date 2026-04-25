# manmd

Convert man pages to Markdown files or copy them to the clipboard.

## Installation

1. Clone or download this repository:

   ```zsh
   git clone https://github.com/iamdanre/manmd ~/.zsh/plugins/manmd
   ```

2. Source the plugin from your `~/.zshrc`:

   ```zsh
   source ~/.zsh/plugins/manmd/manmd.plugin.zsh
   ```

## Usage

```
manmd <command> [output.md]
manmd <command> --copy
manmd <section> <command> [output.md]
manmd <section> <command> --copy
manclip <command>
manclip <section> <command>
```

## Examples

```zsh
# Write ls man page to ls_manual.md
manmd ls

# Write to a custom file
manmd ls ls_manual.md
manmd caffeinate caffeinate_manual.md

# Copy Markdown to clipboard
manmd caffeinate --copy
manclip caffeinate

# Include a manual section number
manmd 5 crontab
manclip 2 open
```

## Output format

Each generated Markdown file includes:

- A top-level heading with the command name
- A `NAME` section (parsed from the man page)
- A `SYNOPSIS` section in a fenced code block
- A `DESCRIPTION` section
- A collapsible `Full man page` section with the raw rendered output

## Notes

- Section numbers are optional. When provided, they must come first: `manmd 2 open`
- Output filename defaults to `<command>_manual.md`
- Clipboard support: macOS (`pbcopy`), Wayland (`wl-copy`), X11 (`xclip`)
- Man page section parsing is heuristic; format varies across platforms
