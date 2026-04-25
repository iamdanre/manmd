# manmd.plugin.zsh
# Convert man pages to Markdown with basic section parsing.
#
# Commands:
#   manmd <command> [output.md]
#   manmd <command> --copy
#   manmd <section> <command> [output.md]
#   manmd <section> <command> --copy
#   manclip <command>
#   manclip <section> <command>
#
# Examples:
#   manmd ls
#   manmd ls ls_manual.md
#   manmd caffeinate --copy
#   manmd 5 crontab
#   manclip caffeinate
#
# Install:
#   1. Save this file somewhere on your fpath/plugin path, e.g.:
#        ~/.zsh/plugins/manmd/manmd.plugin.zsh
#   2. Source it from ~/.zshrc:
#        source ~/.zsh/plugins/manmd/manmd.plugin.zsh
#
# Notes:
# - Parsing of man pages is heuristic because output format varies by platform.
# - Clipboard support order:
#     macOS: pbcopy
#     Wayland: wl-copy
#     X11: xclip

_manmd_usage() {
  cat <<'EOF'
Usage:
  manmd <command> [output.md]
  manmd <command> --copy
  manmd <section> <command> [output.md]
  manmd <section> <command> --copy
  manclip <command>
  manclip <section> <command>

Examples:
  manmd ls
  manmd ls ls_manual.md
  manmd caffeinate --copy
  manmd 5 crontab
  manclip caffeinate
  manclip 2 open
EOF
}

_manmd_copy() {
  emulate -L zsh
  local data="$1"

  if command -v pbcopy >/dev/null 2>&1; then
    print -r -- "$data" | pbcopy
    return $?
  fi

  if command -v wl-copy >/dev/null 2>&1; then
    print -r -- "$data" | wl-copy
    return $?
  fi

  if command -v xclip >/dev/null 2>&1; then
    print -r -- "$data" | xclip -selection clipboard
    return $?
  fi

  echo "manmd: no clipboard tool found (tried pbcopy, wl-copy, xclip)" >&2
  return 1
}

_manmd_trim() {
  sed \
    -e 's/^[[:space:]]*//' \
    -e 's/[[:space:]]*$//'
}

_manmd_extract_section() {
  # Extract text after a heading until the next all-caps heading.
  # Input is passed via stdin.
  # Usage: print -r -- "$text" | _manmd_extract_section "NAME"
  emulate -L zsh
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

_manmd_escape_code_fence() {
  sed 's/^```/``\\`/'
}

_manmd_render_markdown() {
  emulate -L zsh
  setopt pipefail

  local title="$1"
  local invocation="$2"
  local rendered="$3"
  local date_str name synopsis description markdown
  date_str="$(date +%F)"

  name="$(print -r -- "$rendered" | _manmd_extract_section "NAME" 2>/dev/null | _manmd_trim)"
  synopsis="$(print -r -- "$rendered" | _manmd_extract_section "SYNOPSIS" 2>/dev/null)"
  description="$(print -r -- "$rendered" | _manmd_extract_section "DESCRIPTION" 2>/dev/null)"

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
$(print -r -- "$synopsis" | _manmd_escape_code_fence)
\`\`\`
"
  fi

  if [[ -n "$description" ]]; then
    markdown+="

## DESCRIPTION

$(print -r -- "$description")
"
  fi

  markdown+="

## Full man page

<details>
<summary>Show raw rendered man page</summary>

\`\`\`text
$(print -r -- "$rendered" | _manmd_escape_code_fence)
\`\`\`

</details>
"

  print -r -- "$markdown"
}

manmd() {
  emulate -L zsh
  setopt pipefail no_unset

  local section="" cmd="" out="" mode="file"
  local rendered markdown title invocation

  if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
    _manmd_usage
    return 0
  fi

  if [[ "$1" == <-> ]]; then
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
      --copy) mode="copy" ;;
      *) out="$1" ;;
    esac
  fi

  if [[ "$mode" == "file" && -z "$out" ]]; then
    out="${cmd//[^[:alnum:]_-]/_}_manual.md"
  fi

  command -v man >/dev/null 2>&1 || { echo "manmd: man not found" >&2; return 1; }
  command -v col >/dev/null 2>&1 || { echo "manmd: col not found" >&2; return 1; }

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
    echo "manmd: failed to render man page for '$title'" >&2
    return 1
  fi

  markdown="$(_manmd_render_markdown "$title" "$invocation" "$rendered")" || {
    echo "manmd: failed to render markdown for '$title'" >&2
    return 1
  }

  if [[ "$mode" == "copy" ]]; then
    _manmd_copy "$markdown" || return 1
    echo "Copied Markdown man page for '$title' to clipboard"
  else
    print -r -- "$markdown" > "$out"
    echo "Wrote Markdown man page for '$title' to $out"
  fi
}

manclip() {
  emulate -L zsh

  if [[ $# -eq 0 ]]; then
    _manmd_usage >&2
    return 1
  fi

  if [[ "$1" == <-> ]]; then
    [[ $# -eq 2 ]] || { _manmd_usage >&2; return 1; }
    manmd "$1" "$2" --copy
  else
    [[ $# -eq 1 ]] || { _manmd_usage >&2; return 1; }
    manmd "$1" --copy
  fi
}
