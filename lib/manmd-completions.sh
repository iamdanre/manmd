# lib/manmd-completions.sh ( ´ ▽ ` )ﾉ
# shell-agnostic helper functions for manmd completions
# this library provides utilities for shell-specific completion implementations.
#
# to use this library, source it in your completion script:
#   . lib/manmd-completions.sh
#
# all functions output data as newline-separated lists for easy parsing by
# shell-specific completion handlers.

# _manmd_is_section - check if a string is a valid man section number
# valid sections are 1-8 (sometimes 9, 0, n, etc., but core sections are 1-8)
# usage: _manmd_is_section "1" && echo "valid"
_manmd_is_section() {
	local section="$1"
	case "$section" in
	[1-9] | 0 | n | l | p)
		return 0
		;;
	*)
		return 1
		;;
	esac
}

# _manmd_get_sections - list available man page sections
# outputs one section number per line, in order (1-8)
_manmd_get_sections() {
	cat <<'EOF'
1
2
3
4
5
6
7
8
EOF
}

# _manmd_get_commands - list available man commands/pages
# this function attempts to discover man pages available on the system.
# on systems with comprehensive man-db, this can enumerate all available pages.
# falls back to a curated list of common commands if enumeration isn't available.
# outputs one command name per line, one per line
_manmd_get_commands() {
	# try to get all available man pages via man -k if available
	if command -v man >/dev/null 2>&1; then
		# use man -k to search all manual pages (available command list)
		# this lists all man pages but may produce verbose output with descriptions
		# we extract just the command name (first word before space or dash)
		man -k . 2>/dev/null | awk '{print $1}' | sort -u
		return 0
	fi

	# fallback: output common man page commands if man -k isn't available  ¯\_(ツ)_/¯
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
}
