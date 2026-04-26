# completions/_manmd.zsh ( ´ ▽ ` )ﾉ
# zsh completion for manmd and manclip commands
#
# installation:
#   copy this file to a directory in your fpath, e.g.:
#     ~/.zsh/completions/_manmd
#
# this completion provides context-aware suggestions for:
#   - section numbers (1-8, 0, n, l, p)
#   - command names (from man pages)
#   - output filenames
#   - special flags like -c and --copy

#compdef manmd manclip

# source helper functions from lib directory
_manmd_completion_init() {
	local plugin_dir lib_dir

	# try to find the library relative to this completion file
	plugin_dir="${ZDOTDIR:-$HOME}/.zsh/plugins/manmd"
	lib_dir="$plugin_dir/lib"

	# if not found, try common plugin manager locations
	if [[ ! -f "$lib_dir/manmd-completions.sh" ]]; then
		for base_dir in "$fpath[@]" /usr/local/share/zsh/site-functions ~/.zsh/plugins manmd; do
			if [[ -f "$base_dir/../lib/manmd-completions.sh" ]]; then
				lib_dir="$base_dir/../lib"
				break
			elif [[ -f "$base_dir/manmd-completions.sh" ]]; then
				lib_dir="$base_dir"
				break
			fi
		done
	fi

	# source the completion helpers
	if [[ -f "$lib_dir/manmd-completions.sh" ]]; then
		source "$lib_dir/manmd-completions.sh"
		return 0
	fi

	# if helpers not found, define fallback functions  ¯\_(ツ)_/¯
	_manmd_is_section() {
		case "$1" in
		[1-8] | 0 | n | l | p) return 0 ;;
		*) return 1 ;;
		esac
	}

	_manmd_get_sections() {
		printf '%s\n' {1..8}
	}

	_manmd_get_commands() {
		if command -v man >/dev/null 2>&1; then
			man -k . 2>/dev/null | awk '{print $1}' | sort -u
		else
			printf '%s\n' ls cat grep sed awk man bash zsh sh fish vim emacs find xargs tar gzip curl wget git make gcc python node npm
		fi
	}
}

_manmd_completion_init

# complete section numbers
_manmd_complete_sections() {
	local sections
	sections=($(_manmd_get_sections))
	_describe 'manual section' sections
}

# complete command names
_manmd_complete_commands() {
	local commands
	commands=($(_manmd_get_commands))
	_describe 'command' commands
}

# complete output filename or copy flag
_manmd_complete_output() {
	local cmd="$1"
	local section="$2"
	local files flags

	if [[ -n "$section" ]]; then
		files=("${cmd//[^[:alnum:]_-]/_}_${section}_manual.md")
	else
		files=("${cmd//[^[:alnum:]_-]/_}_manual.md")
	fi

	flags=("-c:Copy to clipboard" "--copy:Copy to clipboard")

	_describe -o nosort -t flags 'options' flags
	_describe -t files 'output file' files
}

# main completion function for manmd/manclip
_manmd_main() {
	local cmd="$words[1]"
	local is_manclip=0
	local is_numeric=0

	[[ "$cmd" == "manclip" ]] && is_manclip=1

	# parse arguments to understand context
	# words[1] = manmd/manclip
	# words[2] = first argument (section or command)
	# words[3] = second argument (command, if first was section)
	# words[4] = third argument (output file or -c/--copy)

	case $CURRENT in
	2)
		# first argument: could be section number or command name
		# offer both with section numbers as primary completion
		local -a sections commands
		sections=($(_manmd_get_sections))
		commands=($(_manmd_get_commands))

		# create combined list with sections first, then commands
		local -a completions
		for s in $sections; do
			completions+=("$s:manual section $s")
		done

		_describe -o nosort -t sections 'sections' "$(printf '%s\n' {1..8} | sed 's/\(.*\)/\1:section \1/')"
		_describe -o nosort -t commands 'commands' commands
		;;
	3)
		# second argument: could be command (if first arg was section) or output file
		local first_arg="${words[2]}"

		if _manmd_is_section "$first_arg"; then
			# first arg was section, so complete command names
			_manmd_complete_commands
		else
			# first arg was command, so complete output file or copy flag
			_manmd_complete_output "$first_arg" ""
		fi
		;;
	4)
		# third argument: must be output file or copy flag
		local first_arg="${words[2]}"
		local second_arg="${words[3]}"

		if _manmd_is_section "$first_arg"; then
			# second arg is the command, pass the section forward
			_manmd_complete_output "$second_arg" "$first_arg"
		fi
		;;
	esac
}

# dispatch based on command
_manmd() {
	if [[ "$words[1]" == "manmd" ]]; then
		_manmd_main
	elif [[ "$words[1]" == "manclip" ]]; then
		_manmd_main
	fi
}

_manmd "$@"
