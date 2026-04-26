# completions/manmd.fish ( ´ ▽ ` )ﾉ
# fish shell completion for manmd command
#
# installation:
#   copy this file to ~/.config/fish/completions/manmd.fish
#   or if using a plugin manager, place in the plugin's completions directory
#
# this completion provides context-aware suggestions for manmd and manclip commands.

# helper functions for conditions

# check if we've seen a section number yet
function __manmd_no_section --description "Check if no section number has been entered yet"
    set -l tokens (commandline -poc)
    # skip the command name itself
    test (count $tokens) -lt 2
end

# check if we've seen a section number
function __manmd_has_section --description "Check if a section number has been entered"
    set -l tokens (commandline -poc)
    # tokens[1] is the command (manmd or manclip)
    test (count $tokens) -ge 2
    and string match -qr '^[0-9nlp]$' $tokens[2]
end

# check if we're in the position to accept a command name (after optional section)
function __manmd_needs_command --description "Check if we need a command name next"
    set -l tokens (commandline -poc)
    
    # if only command name is entered
    if test (count $tokens) -eq 1
        return 0
    end
    
    # if section number entered, need command next
    if test (count $tokens) -eq 2
        and string match -qr '^[0-9nlp]$' $tokens[2]
        return 0
    end
    
    return 1
end

# check if we're in a position to accept output filename or copy flag
function __manmd_needs_output --description "Check if we need output file or --copy flag"
    set -l tokens (commandline -poc)
    
    # we need at least command or section+command
    if test (count $tokens) -lt 2
        return 1
    end
    
    # if we have section number at position 2 and command at position 3
    if string match -qr '^[0-9nlp]$' $tokens[2]
        and test (count $tokens) -eq 3
        return 0
    end
    
    # if we have command at position 2 (no section)
    if not string match -qr '^[0-9nlp]$' $tokens[2]
        and test (count $tokens) -eq 2
        return 0
    end
    
    return 1
end

# helper to get list of man sections
function __manmd_get_sections --description "Get list of man page sections"
    echo -e "1\n2\n3\n4\n5\n6\n7\n8"
end

# helper to get common man page commands
function __manmd_get_commands --description "Get list of common man page commands"
    # try to get commands from system if man -k is available
    if command -v man >/dev/null 2>&1
        man -k . 2>/dev/null | awk '{print $1}' | sort -u
        return 0
    end
    
    # fallback list of common commands  ¯\_(ツ)_/¯
    echo -e "ls\ncat\ngrep\nsed\nawk\nman\nbash\nzsh\nsh\nfish\nvim\nemacs\nfind\nxargs\ntar\ngzip\ncurl\nwget\ngit\nmake\ngcc\npython\nnode\nnpm"
end

# completions for manmd command

# complete section numbers when no arguments provided
complete -c manmd -n "__manmd_no_section" -a "(__manmd_get_sections)" -d "Man page section"

# complete command names when section provided or as first argument
complete -c manmd -n "__manmd_needs_command" -f -a "(__manmd_get_commands)" -d "Command/man page"

# complete output filename or copy flag after command
complete -c manmd -n "__manmd_needs_output" -f -a "-c" -d "Copy to clipboard instead of file"
complete -c manmd -n "__manmd_needs_output" -f -a "--copy" -d "Copy to clipboard instead of file"
complete -c manmd -n "__manmd_needs_output" -f -d "Output filename"

# help flag
complete -c manmd -s h -l help -d "Show help information"

# completions for manclip command
# manclip has the same argument structure as manmd --copy

# complete section numbers when no arguments provided
complete -c manclip -n "__manmd_no_section" -a "(__manmd_get_sections)" -d "Man page section"

# complete command names when section provided or as first argument
complete -c manclip -n "__manmd_needs_command" -f -a "(__manmd_get_commands)" -d "Command/man page"
