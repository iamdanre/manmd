# manmd.plugin.fish ＼（＾▽＾）／
# convert man pages to markdown with basic section parsing (fish shell).
# this plugin sources the shared library layer for multi-shell support.
#
# commands:
#   manmd <command> [output.md]
#   manmd <command> -c
#   manmd <command> --copy
#   manmd <section> <command> [output.md]
#   manmd <section> <command> -c
#   manmd <section> <command> --copy
#   manclip <command>
#   manclip <section> <command>
#
# examples:
#   manmd ls
#   manmd ls ls_manual.md
#   manmd caffeinate -c
#   manmd caffeinate --copy
#   manmd 5 crontab
#   manclip caffeinate
#
# install:
#   1. save this file to your fish config directory or plugins:
#        ~/.config/fish/conf.d/manmd.fish  (for auto-loading)
#        or ~/.config/fish/plugins/manmd/manmd.plugin.fish
#   2. it will be automatically sourced, or source manually:
#        source ~/.config/fish/plugins/manmd/manmd.plugin.fish
#
# notes:
# - parsing of man pages is heuristic because output format varies by platform.
# - clipboard support order:
#     macOS: pbcopy
#     wayland: wl-copy
#     x11: xclip, xsel
#     wsl: clip.exe

# find the library directory relative to this script
# the setup script sets _MANMD_SETUP_DIR, use it if available
set -gx _manmd_script_dir
if set -q _MANMD_SETUP_DIR
    set -gx _manmd_script_dir "$_MANMD_SETUP_DIR"
else
    set -gx _manmd_script_dir (dirname (status current-filename))
end
set -gx _manmd_lib_dir "$_manmd_script_dir/lib"

# verify shared core library exists
if not test -f "$_manmd_lib_dir/manmd-core.sh"
    echo "manmd: failed to source core library at $_manmd_lib_dir/manmd-core.sh" >&2  # (╥_╥)
    exit 1
end

# wrapper for _manmd_usage - call via bash
function _manmd_usage -d "Print manmd usage information"
    bash -c "
        . '$_manmd_lib_dir/manmd-core.sh'
        _manmd_usage
    "
end

# fish-specific wrapper for copying to clipboard
function _manmd_copy_fish -d "Copy data to clipboard using Fish syntax"
    set -l data "$argv"
    
    if command -v pbcopy >/dev/null 2>&1
        printf '%s' "$data" | pbcopy
        return $status
    end
    
    if command -v wl-copy >/dev/null 2>&1
        printf '%s' "$data" | wl-copy
        return $status
    end
    
    if command -v xclip >/dev/null 2>&1
        printf '%s' "$data" | xclip -selection clipboard
        return $status
    end
    
    if command -v xsel >/dev/null 2>&1
        printf '%s' "$data" | xsel --clipboard --input
        return $status
    end

    if command -v clip.exe >/dev/null 2>&1
        printf '%s' "$data" | clip.exe
        return $status
    end

    echo "manmd: no clipboard tool found (tried pbcopy, wl-copy, xclip, xsel, clip.exe)" >&2  # (╥_╥)
    return 1
end

# helper to extract a section from rendered man page
function _extract_section -d "Extract section from man page"
    set -l section "$argv[1]"
    bash -c "
        . '$_manmd_lib_dir/manmd-core.sh'
        _manmd_extract_section '$section' 2>/dev/null
    "
end

# helper to trim whitespace
function _trim_text -d "Trim leading/trailing whitespace"
    bash -c "
        . '$_manmd_lib_dir/manmd-core.sh'
        _manmd_trim
    "
end

# helper to escape code fences
function _escape_fences -d "Escape markdown code fences"
    bash -c "
        . '$_manmd_lib_dir/manmd-core.sh'
        _manmd_escape_code_fence
    "
end

# fish-specific wrapper for rendering markdown
function _manmd_render_markdown_fish -d "Render markdown from man page"
    set -l title "$argv[1]"
    set -l invocation "$argv[2]"
    set -l rendered "$argv[3]"
    
    set -l date_str (date +%F)
    
    # extract sections from rendered man page
    set -l name (printf '%s' "$rendered" | _extract_section 'NAME' | _trim_text)
    set -l synopsis (printf '%s' "$rendered" | _extract_section 'SYNOPSIS')
    set -l description (printf '%s' "$rendered" | _extract_section 'DESCRIPTION')
    
    # build markdown header
    set -l markdown "# \`$title\`

> Generated from \`$invocation\` on $date_str.
"
    
    # add NAME section if found
    if test -n "$name"
        set markdown "$markdown

## NAME

$name
"
    end
    
    # add SYNOPSIS section if found
    if test -n "$synopsis"
        set -l escaped_synopsis (printf '%s' "$synopsis" | _escape_fences)
        set markdown "$markdown

## SYNOPSIS

\`\`\`text
$escaped_synopsis
\`\`\`
"
    end
    
    # add DESCRIPTION section if found
    if test -n "$description"
        set markdown "$markdown

## DESCRIPTION

$description
"
    end
    
    # add full man page in collapsible section
    set -l escaped_rendered (printf '%s' "$rendered" | _escape_fences)
    set markdown "$markdown

## Full man page

<details>
<summary>Show raw rendered man page</summary>

\`\`\`text
$escaped_rendered
\`\`\`

</details>
"
    
    printf '%s' "$markdown"
    return 0
end

# main manmd function for fish
function manmd -d "Convert man pages to Markdown"
    set -l section ""
    set -l cmd ""
    set -l out ""
    set -l mode "file"
    set -l rendered ""
    set -l markdown ""
    set -l title ""
    set -l invocation ""
    
    # handle no arguments or help
    if test (count $argv) -eq 0
        or test "$argv[1]" = "-h"
        or test "$argv[1]" = "--help"
        _manmd_usage
        return 0
    end
    
    # check if first argument is a section number (digit or special section)
    if string match -rq '^[0-9nplp]$' "$argv[1]"
        set section "$argv[1]"
        set -e argv[1]
    end
    
    # check if we still have arguments
    if test (count $argv) -eq 0
        echo "manmd: missing command" >&2
        _manmd_usage >&2
        return 1
    end
    
    # get command name
    set cmd "$argv[1]"
    set -e argv[1]
    
    # check for too many arguments
    if test (count $argv) -gt 1
        echo "manmd: too many arguments" >&2
        _manmd_usage >&2
        return 1
    end
    
    # parse output mode and filename
    if test (count $argv) -eq 1
        switch "$argv[1]"
            case -c --copy
                set mode "copy"
            case '*'
                set out "$argv[1]"
        end
    end
    
    # set default output filename if not specified
    if test "$mode" = "file" -a -z "$out"
        set -l clean_cmd (string replace -ra '[^[:alnum:]_-]' '_' "$cmd")
        if test -n "$section"
            set out "$clean_cmd"_"$section"_manual.md
        else
            set out "$clean_cmd"_manual.md
        end
    end
    
    # check for required tools
    if not command -v man >/dev/null 2>&1
        echo "manmd: man not found" >&2
        return 1
    end
    
    if not command -v col >/dev/null 2>&1
        echo "manmd: col not found" >&2
        return 1
    end
    
    # render man page
    if test -n "$section"
        set rendered (env MANWIDTH=80 man "$section" "$cmd" 2>/dev/null | col -bx)
        set invocation "man $section $cmd"
        set title "$cmd($section)"
    else
        set rendered (env MANWIDTH=80 man "$cmd" 2>/dev/null | col -bx)
        set invocation "man $cmd"
        set title "$cmd"
    end
    
    # check if rendering succeeded
    if test -z "$rendered"
        echo "manmd: failed to render man page for '$title'" >&2  # (╥ᴥ╥)
        return 1
    end
    
    # generate markdown
    set markdown (_manmd_render_markdown_fish "$title" "$invocation" "$rendered")
    if test $status -ne 0
        echo "manmd: failed to render markdown for '$title'" >&2  # (T_T)
        return 1
    end
    
    # output or copy
    if test "$mode" = "copy"
        _manmd_copy_fish "$markdown"
        if test $status -ne 0
            return 1
        end
        echo "Copied Markdown man page for '$title' to clipboard"
    else
        printf '%s' "$markdown" > "$out"
        echo "Wrote Markdown man page for '$title' to $out"
    end
end

# wrapper function for manclip
function manclip -d "Copy man page as Markdown to clipboard"
    if test (count $argv) -eq 0
        _manmd_usage >&2
        return 1
    end
    
    # check if first argument is a section number
    if string match -rq '^[0-9nplp]$' "$argv[1]"
        if test (count $argv) -eq 2
            manmd "$argv[1]" "$argv[2]" -c
        else
            _manmd_usage >&2
            return 1
        end
    else
        if test (count $argv) -eq 1
            manmd "$argv[1]" -c
        else
            _manmd_usage >&2
            return 1
        end
    end
end
