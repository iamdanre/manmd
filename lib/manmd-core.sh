# lib/manmd-core.sh (=^･ω･^=)
# shell-agnostic utility functions for manmd
# this library provides core functionality that works across all shells
# (zsh, bash, fish, etc.) by using posix-compatible shell syntax.
#
# to use this library, source it in your shell script:
#   . lib/manmd-core.sh
#
# all functions are prefixed with _manmd_ to avoid namespace pollution.

# _manmd_usage - print usage information
_manmd_usage() {
	cat <<'EOF'
Usage:
  manmd <command> [output.md]
  manmd <command> -c
  manmd <command> --copy
  manmd <section> <command> [output.md]
  manmd <section> <command> -c
  manmd <section> <command> --copy
  manclip <command>
  manclip <section> <command>

Examples:
  manmd ls
  manmd ls ls_manual.md
  manmd caffeinate -c
  manmd caffeinate --copy
  manmd 5 crontab
  manclip caffeinate
  manclip 2 open
EOF
}

# _manmd_copy - copy data to clipboard
# supports pbcopy (macos), wl-copy (wayland), xclip/xsel (x11), and clip.exe (wsl)
_manmd_copy() {
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

	printf '%s\n' "manmd: no clipboard tool found (tried pbcopy, wl-copy, xclip, xsel, clip.exe)" >&2 # (╥_╥)
	return 1
}

# _manmd_trim - remove leading and trailing whitespace from stdin
_manmd_trim() {
	sed \
		-e 's/^[[:space:]]*//' \
		-e 's/[[:space:]]*$//'
}

# _manmd_extract_section - extract text after a heading until the next all-caps heading 「(°ヘ°)
# input is passed via stdin.
# usage: printf '%s' "$text" | _manmd_extract_section "NAME"
# returns 1 if the heading was not found, 0 on success
_manmd_extract_section() {
	local heading="$1"

	awk -v target="$heading" '
    function is_heading(line) {
      return line ~ /^[A-Z][A-Z0-9[:space:]_-]*$/
    }
    {
      sub(/\r$/, "", $0)
      lines[NR] = $0
    }
    END {
      capture = 0
      started = 0
      for (i = 1; i <= NR; i++) {
        line = lines[i]
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)

        if (line == target) {
          capture = 1
          started = 1
          continue
        }

        if (capture && is_heading(line)) {
          break
        }

        if (capture) {
          print lines[i]
        }
      }
      if (!started) exit 1
    }
  '
}

# _manmd_escape_code_fence - escape markdown code fences (```) in input
# prevents markdown parsing issues when embedding code blocks
_manmd_escape_code_fence() {
	sed 's/^```/``\\`/'
}

# _manmd_render_markdown - render markdown from man page data
# arguments:
#   $1 - title (e.g., "ls" or "ls(1)")
#   $2 - invocation (e.g., "man ls" or "man 1 ls")
#   $3 - rendered man page content
# outputs the generated markdown to stdout
# returns 0 on success, 1 on failure
_manmd_render_markdown() {
	local title="$1"
	local invocation="$2"
	local rendered="$3"
	local date_str name synopsis description markdown

	# get current date in YYYY-MM-DD format
	date_str="$(date +%F)" || date_str="unknown"

	# extract sections from rendered man page
	name="$(printf '%s' "$rendered" | _manmd_extract_section "NAME" 2>/dev/null | _manmd_trim)"
	synopsis="$(printf '%s' "$rendered" | _manmd_extract_section "SYNOPSIS" 2>/dev/null)"
	description="$(printf '%s' "$rendered" | _manmd_extract_section "DESCRIPTION" 2>/dev/null)"

	# build markdown header
	markdown="# \`$title\`

> Generated from \`$invocation\` on $date_str.
"

	# add NAME section if found
	if [ -n "$name" ]; then
		markdown="${markdown}

## NAME

$name
"
	fi

	# add SYNOPSIS section if found
	if [ -n "$synopsis" ]; then
		markdown="${markdown}

## SYNOPSIS

\`\`\`text
$(printf '%s' "$synopsis" | _manmd_escape_code_fence)
\`\`\`
"
	fi

	# add DESCRIPTION section if found
	if [ -n "$description" ]; then
		markdown="${markdown}

## DESCRIPTION

$(printf '%s' "$description")
"
	fi

	# add full man page in collapsible section
	markdown="${markdown}

## Full man page

<details>
<summary>Show raw rendered man page</summary>

\`\`\`text
$(printf '%s' "$rendered" | _manmd_escape_code_fence)
\`\`\`

</details>
"

	printf '%s' "$markdown"
	return 0
}
