# manmd

convert man pages to markdown files or copy them to the clipboard.

## features

- convert any man page to markdown
- copy markdown to clipboard (macos, linux, wayland)
- optional man section numbers
- tab completions in all supported shells
- auto-detection setup for multiple shells
- support for bash, fish, and zsh

## supported shells

| shell    | minimum version | platforms               |
| -------- | --------------- | ----------------------- |
| **zsh**  | 5.0+            | macos, linux, unix-like |
| **bash** | 3.2+            | macos, linux, unix-like |
| **fish** | 2.3+            | macos, linux, unix-like |

## installation

### method 1: automatic setup (recommended)

uses shell auto-detection—add one line to your shell rc file:

**for zsh (`~/.zshrc`):**

```zsh
source ~/path/to/manmd/manmd-setup.sh
```

**for bash (`~/.bashrc`):**

```bash
source ~/path/to/manmd/manmd-setup.sh
```

**for fish (`~/.config/fish/config.fish`):**

```fish
source ~/path/to/manmd/manmd-setup.fish
```

### method 2: shell-specific setup

clone or download this repository:

```bash
git clone https://github.com/iamdanre/manmd ~/.local/share/manmd
```

then source the appropriate plugin file from your shell rc:

**for zsh (`~/.zshrc`):**

```zsh
source ~/.local/share/manmd/manmd.plugin.zsh
```

**for bash (`~/.bashrc`):**

```bash
source ~/.local/share/manmd/manmd.plugin.bash
```

**for fish (`~/.config/fish/config.fish`):**

```fish
source ~/.local/share/manmd/manmd.plugin.fish
```

## usage

```
manmd <command> [output.md]
manmd <command> -c
manmd <command> --copy
manmd <section> <command> [output.md]
manmd <section> <command> -c
manmd <section> <command> --copy
manclip <command>
manclip <section> <command>
```

## examples

```bash
# write ls man page to ls_manual.md
manmd ls

# write to a custom file
manmd ls ls_manual.md
manmd caffeinate caffeinate_manual.md

# copy markdown to clipboard
manmd caffeinate -c
manmd caffeinate --copy
manclip caffeinate

# include a manual section number
manmd 5 crontab
manclip 2 open
```

## tab completions

all supported shells include context-aware tab-completion for faster command usage:

**complete commands and sections:**

```bash
manmd <TAB>  # shows available commands and sections
```

**complete within a section:**

```bash
manmd 1 <TAB>  # shows commands available in section 1
```

**complete output options:**

```bash
manmd ls <TAB>  # shows available output options (--copy, etc.)
```

completions are automatically installed when you source the plugin or setup script. if completions aren't working, ensure the completion files are loaded:

- **zsh:** `_manmd.zsh` (in the plugin directory)
- **bash:** `manmd-completion.bash` (in the completions directory)
- **fish:** `manmd.fish` (in the completions directory)

## output format

each generated markdown file includes:

- a top-level heading with the command name
- a `NAME` section (parsed from the man page)
- a `SYNOPSIS` section in a fenced code block
- a `DESCRIPTION` section
- a collapsible `Full man page` section with the raw rendered output

## notes

- section numbers are optional. when provided, they must come first: `manmd 2 open`
- output filename defaults to `<command>_manual.md` or `<command>_<section>_manual.md` (if section is provided)
- clipboard support: macos (`pbcopy`), wayland (`wl-copy`), x11 (`xclip` or `xsel`), windows/wsl (`clip.exe`)
- copy-to-clipboard flag: `-c` or `--copy`
- man page section parsing is heuristic; format varies across platforms

## troubleshooting

**tab completions not working?**

- ensure the completion files are in the `completions/` directory
- try reloading your shell: `exec $SHELL`
- for zsh, verify `_manmd.zsh` is in your `fpath`

**shell not detected by setup script?**

- manually source the plugin file for your shell (see method 2 above)
- verify your shell executable name (zsh, bash, or fish)
