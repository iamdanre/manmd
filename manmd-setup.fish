#!/usr/bin/env fish
# manmd-setup.fish - load manmd plugin for fish shell ( ´ ▽ ` )ﾉ
# 
# usage: source manmd-setup.fish
# add to ~/.config/fish/config.fish

# find the directory containing this script
# we need to handle both direct sourcing and being sourced after cd
set -gx _MANMD_SCRIPT_FILE (status current-filename)

if test -n "$_MANMD_SCRIPT_FILE" && test "$_MANMD_SCRIPT_FILE" != "."
    # we got the actual filename
    set -gx _MANMD_SETUP_DIR (dirname "$_MANMD_SCRIPT_FILE")
else
    # status current-filename didn't work (e.g., in a nested source)
    # fall back to looking for manmd.plugin.fish in common locations
    
    # try current directory first
    if test -f "./manmd.plugin.fish"
        set -gx _MANMD_SETUP_DIR "."
    # try parent directory
    else if test -f "../manmd.plugin.fish"
        set -gx _MANMD_SETUP_DIR ".."
    # try ~/.config/fish/plugins/manmd
    else if test -f "$HOME/.config/fish/plugins/manmd/manmd.plugin.fish"
        set -gx _MANMD_SETUP_DIR "$HOME/.config/fish/plugins/manmd"
    # last resort: search in /opt, /usr/local, etc  ¯\_(ツ)_/¯
    else
        # try to find manmd directory
        for dir in /opt/manmd /usr/local/opt/manmd /usr/share/manmd "$HOME/.local/opt/manmd" "$HOME/.opt/manmd"
            if test -f "$dir/manmd.plugin.fish"
                set -gx _MANMD_SETUP_DIR "$dir"
                break
            end
        end
    end
end

if test -f "$_MANMD_SETUP_DIR/manmd.plugin.fish"
  source "$_MANMD_SETUP_DIR/manmd.plugin.fish"
else
  echo "Warning: manmd.plugin.fish not found at $_MANMD_SETUP_DIR" >&2  # (ᗕ_ᗕ)
end
