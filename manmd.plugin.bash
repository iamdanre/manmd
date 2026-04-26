# manmd.plugin.bash ＼（＾▽＾）／
# convert man pages to markdown with basic section parsing.
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
#   1. save this file somewhere on your bash plugins directory, e.g.:
#        ~/.bash/plugins/manmd/manmd.plugin.bash
#   2. source it from ~/.bashrc:
#        source ~/.bash/plugins/manmd/manmd.plugin.bash
#
# notes:
# - parsing of man pages is heuristic because output format varies by platform.
# - clipboard support order:
#     macOS: pbcopy
#     wayland: wl-copy
#     x11: xclip, xsel
#     wsl: clip.exe

# find the library directory relative to this script
_manmd_lib_dir="$(dirname "${BASH_SOURCE[0]}")/lib"

# source shared core library
if [[ -f "$_manmd_lib_dir/manmd-core.sh" ]]; then
	source "$_manmd_lib_dir/manmd-core.sh"
else
	echo "manmd: failed to source core library at $_manmd_lib_dir/manmd-core.sh" >&2 # (╥_╥)
	return 1
fi

# bash-specific wrappers for functions that need special handling

# override _manmd_copy to use bash-compatible printf
_manmd_copy_bash() {
	local data="$1"

	if command -v pbcopy >/dev/null 2>&1; then
		printf '%s' "$data" | pbcopy
		return $?
	fi

	if command -v wl-copy >/dev/null 2>&1; then
		printf '%s' "$data" | wl-copy
		return $?
	fi

	if command -v xclip >/dev/null 2>&1; then
		printf '%s' "$data" | xclip -selection clipboard
		return $?
	fi

	if command -v xsel >/dev/null 2>&1; then
		printf '%s' "$data" | xsel --clipboard --input
		return $?
	fi

	if command -v clip.exe >/dev/null 2>&1; then
		printf '%s' "$data" | clip.exe
		return $?
	fi

	echo "manmd: no clipboard tool found (tried pbcopy, wl-copy, xclip, xsel, clip.exe)" >&2 # (╥_╥)
	return 1
}

# override _manmd_render_markdown with bash-specific version
_manmd_render_markdown_bash() {
	set -o pipefail

	local title="$1"
	local invocation="$2"
	local rendered="$3"
	local date_str name synopsis description markdown

	date_str="$(date +%F)"

	name="$(printf '%s' "$rendered" | _manmd_extract_section "NAME" 2>/dev/null | _manmd_trim)"
	synopsis="$(printf '%s' "$rendered" | _manmd_extract_section "SYNOPSIS" 2>/dev/null)"
	description="$(printf '%s' "$rendered" | _manmd_extract_section "DESCRIPTION" 2>/dev/null)"

	markdown="# \`$title\`

> Generated from \`$invocation\` on $date_str.
"

	if [[ -n "$name" ]]; then
		markdown+="

## NAME

$name
"
	fi

	if [[ -n "$synopsis" ]]; then
		markdown+="

## SYNOPSIS

\`\`\`text
$(printf '%s' "$synopsis" | _manmd_escape_code_fence)
\`\`\`
"
	fi

	if [[ -n "$description" ]]; then
		markdown+="

## DESCRIPTION

$(printf '%s' "$description")
"
	fi

	markdown+="

## Full man page

<details>
<summary>Show raw rendered man page</summary>

\`\`\`text
$(printf '%s' "$rendered" | _manmd_escape_code_fence)
\`\`\`

</details>
"

	printf '%s' "$markdown"
}

# use bash-specific versions by reassigning functions
_manmd_copy() { _manmd_copy_bash "$@"; }
_manmd_render_markdown() { _manmd_render_markdown_bash "$@"; }

# check if string is a valid man section number
_manmd_is_section() {
	local section="$1"
	[[ "$section" =~ ^[0-9]$ ]]
}

manmd() {
	set -o pipefail

	local section="" cmd="" out="" mode="file"
	local rendered markdown title invocation

	if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
		_manmd_usage
		return 0
	fi

	# check if first argument is a section number
	if _manmd_is_section "$1"; then
		section="$1"
		shift
	fi

	if [[ $# -lt 1 ]]; then
		echo "manmd: missing command" >&2
		_manmd_usage >&2
		return 1
	fi

	cmd="$1"
	shift

	if [[ $# -gt 1 ]]; then
		echo "manmd: too many arguments" >&2
		_manmd_usage >&2
		return 1
	fi

	if [[ $# -eq 1 ]]; then
		case "$1" in
		-c | --copy) mode="copy" ;;
		*) out="$1" ;;
		esac
	fi

	if [[ "$mode" == "file" && -z "$out" ]]; then
		if [[ -n "$section" ]]; then
			out="${cmd//[^[:alnum:]_-]/_}_${section}_manual.md"
		else
			out="${cmd//[^[:alnum:]_-]/_}_manual.md"
		fi
	fi

	command -v man >/dev/null 2>&1 || {
		echo "manmd: man not found" >&2
		return 1
	}
	command -v col >/dev/null 2>&1 || {
		echo "manmd: col not found" >&2
		return 1
	}

	if [[ -n "$section" ]]; then
		rendered="$(MANWIDTH=80 man "$section" "$cmd" 2>/dev/null | col -bx)"
		invocation="man $section $cmd"
		title="$cmd($section)"
	else
		rendered="$(MANWIDTH=80 man "$cmd" 2>/dev/null | col -bx)"
		invocation="man $cmd"
		title="$cmd"
	fi

	if [[ -z "$rendered" ]]; then
		echo "manmd: failed to render man page for '$title'" >&2 # (╥ᴥ╥)
		return 1
	fi

	markdown="$(_manmd_render_markdown "$title" "$invocation" "$rendered")" || {
		echo "manmd: failed to render markdown for '$title'" >&2 # (T_T)
		return 1
	}

	if [[ "$mode" == "copy" ]]; then
		_manmd_copy "$markdown" || return 1
		echo "Copied Markdown man page for '$title' to clipboard"
	else
		printf '%s' "$markdown" >"$out"
		echo "Wrote Markdown man page for '$title' to $out"
	fi
}

manclip() {
	if [[ $# -eq 0 ]]; then
		_manmd_usage >&2
		return 1
	fi

	if _manmd_is_section "$1"; then
		[[ $# -eq 2 ]] || {
			_manmd_usage >&2
			return 1
		}
		manmd "$1" "$2" -c
	else
		[[ $# -eq 1 ]] || {
			_manmd_usage >&2
			return 1
		}
		manmd "$1" -c
	fi
}
