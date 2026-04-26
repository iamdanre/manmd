# completions/manmd-completion.bash ( ´ ▽ ` )ﾉ
# bash completion for manmd and manclip commands
#
# installation:
#   copy this file to /etc/bash_completion.d/ or ~/.bash_completion.d/
#   or source it manually:
#     source manmd-completion.bash
#
# this completion script provides context-aware tab completions for:
# - manmd: convert man pages to markdown
# - manclip: copy man pages as markdown to clipboard
#
# completion scenarios:
#   manmd <TAB>           → suggest sections or commands
#   manmd 1 <TAB>         → after section, suggest commands
#   manmd ls <TAB>        → after command, suggest -c/--copy or filenames
#   manmd ls test<TAB>    → complete filenames
#   manclip <TAB>         → suggest sections or commands
#   manclip 2 <TAB>       → after section, suggest commands

# find the library directory relative to this script or installed location
_manmd_find_lib_dir() {
	local lib_dir

	# try relative to this script location (if sourced)
	if [[ -n "${BASH_SOURCE[0]}" ]]; then
		lib_dir="$(dirname "${BASH_SOURCE[0]}")/../lib"
		if [[ -f "$lib_dir/manmd-completions.sh" ]]; then
			echo "$lib_dir"
			return 0
		fi
	fi

	# try common installation paths
	for path in /etc/manmd/lib ~/.local/share/manmd/lib ~/.bash/plugins/manmd/lib; do
		if [[ -f "$path/manmd-completions.sh" ]]; then
			echo "$path"
			return 0
		fi
	done

	return 1
}

# source the completion helper library
_manmd_lib_dir="$(_manmd_find_lib_dir)"
if [[ -n "$_manmd_lib_dir" && -f "$_manmd_lib_dir/manmd-completions.sh" ]]; then
	source "$_manmd_lib_dir/manmd-completions.sh"
fi

# check if first argument is a section number (1-8)
_manmd_is_section_num() {
	local arg="$1"
	[[ "$arg" =~ ^[1-8]$ ]]
}

# get list of sections for completion
_manmd_sections() {
	if command -v _manmd_get_sections >/dev/null 2>&1; then
		_manmd_get_sections
	else
		echo -e "1\n2\n3\n4\n5\n6\n7\n8"
	fi
}

# get list of commands for completion
_manmd_commands() {
	if command -v _manmd_get_commands >/dev/null 2>&1; then
		_manmd_get_commands
	else
		# fallback list of common commands  ¯\_(ツ)_/¯
		cat <<'EOF'
ls
cat
grep
sed
awk
man
bash
zsh
sh
fish
vim
emacs
find
xargs
tar
gzip
curl
wget
git
make
gcc
python
node
npm
EOF
	fi
}

# get list of filenames that match current partial
_manmd_get_filenames() {
	local cur="$1"
	# use compgen to generate filename completions
	compgen -f -- "$cur"
}

# main completion function for manmd
_manmd_complete() {
	local cur prev prevprev words cword
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD - 1]}"
	words=("${COMP_WORDS[@]}")
	cword=$COMP_CWORD

	COMPREPLY=()

	# count arguments (number of words after the command name)
	local arg_count=$((cword))

	# first argument: could be section or command
	if [[ $arg_count -eq 1 ]]; then
		# suggest both sections and commands
		local candidates
		candidates=$(
			(
				_manmd_sections
				_manmd_commands
			) | sort -u
		)
		COMPREPLY=($(compgen -W "$candidates" -- "$cur"))
		return 0
	fi

	# check if first real argument (after command name) is a section
	local first_arg="${COMP_WORDS[1]}"

	# second argument case
	if [[ $arg_count -eq 2 ]]; then
		if _manmd_is_section_num "$first_arg"; then
			# first arg was section, second arg must be command
			local commands
			commands=$(_manmd_commands)
			COMPREPLY=($(compgen -W "$commands" -- "$cur"))
		else
			# first arg was command, second arg could be -c, --copy, or filename
			local suggestions="-c --copy"
			# add filenames (from compgen -f)
			local files
			files=$(_manmd_get_filenames "$cur")
			if [[ -n "$files" ]]; then
				suggestions="$suggestions $(echo "$files")"
			fi
			COMPREPLY=($(compgen -W "$suggestions" -- "$cur"))
		fi
		return 0
	fi

	# third argument case (after section and command)
	if [[ $arg_count -eq 3 ]]; then
		if _manmd_is_section_num "$first_arg"; then
			# pattern: manmd <section> <command> [-c|--copy|filename]
			local suggestions="-c --copy"
			# add filenames
			local files
			files=$(_manmd_get_filenames "$cur")
			if [[ -n "$files" ]]; then
				suggestions="$suggestions $(echo "$files")"
			fi
			COMPREPLY=($(compgen -W "$suggestions" -- "$cur"))
		fi
		return 0
	fi
}

# main completion function for manclip
_manclip_complete() {
	local cur prev prevprev words cword
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD - 1]}"
	words=("${COMP_WORDS[@]}")
	cword=$COMP_CWORD

	COMPREPLY=()

	# count arguments (number of words after the command name)
	local arg_count=$((cword))

	# first argument: could be section or command
	if [[ $arg_count -eq 1 ]]; then
		local candidates
		candidates=$(
			(
				_manmd_sections
				_manmd_commands
			) | sort -u
		)
		COMPREPLY=($(compgen -W "$candidates" -- "$cur"))
		return 0
	fi

	# check if first real argument is a section
	local first_arg="${COMP_WORDS[1]}"

	# second argument case
	if [[ $arg_count -eq 2 ]]; then
		if _manmd_is_section_num "$first_arg"; then
			# first arg was section, second arg must be command
			local commands
			commands=$(_manmd_commands)
			COMPREPLY=($(compgen -W "$commands" -- "$cur"))
		fi
		return 0
	fi
}

# register completion functions
complete -o bashdefault -o default -o nospace -F _manmd_complete manmd
complete -o bashdefault -o default -o nospace -F _manclip_complete manclip
