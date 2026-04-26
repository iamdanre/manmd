#!/bin/bash
# manmd-setup.sh - auto-detect shell and source appropriate plugin
#
# usage: source manmd-setup.sh
# add to your shell rc file (~/.zshrc, ~/.bashrc, or ~/.config/fish/config.fish)
#
# for fish shell, use: source manmd-setup.fish
# this script automatically detects and loads the correct shell plugin.

# skip if already loaded
if [ -n "$_MANMD_LOADED" ]; then
	return 0 2>/dev/null || exit 0
fi

# for bash/zsh, proceed with detection
if [ -z "$FISH_VERSION" ]; then

	detect_shell() {
		# try ps first to get the actual running shell
		current_shell=$(ps -o comm= -p $$ 2>/dev/null | xargs basename 2>/dev/null)

		if [ -n "$current_shell" ] && [ "$current_shell" != "ps" ]; then
			echo "$current_shell"
			return 0
		fi

		# fallback to SHELL environment variable
		if [ -n "$SHELL" ]; then
			basename "$SHELL"
			return 0
		fi

		# last resort: assume bash  ¯\_(ツ)_/¯
		echo "bash"
	}

	# determine MANMD_DIR - handles both sourcing and execution
	if [ -n "${BASH_SOURCE[0]}" ] && [ "${BASH_SOURCE[0]}" != "${0}" ]; then
		# bash: use BASH_SOURCE when sourced
		MANMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	elif [ -n "${ZSH_SCRIPT}" ]; then
		# zsh: use ZSH_SCRIPT
		MANMD_DIR="$(cd "$(dirname "${ZSH_SCRIPT}")" && pwd)"
	elif [ -n "$0" ] && [ "$0" != "-bash" ] && [ "$0" != "-zsh" ]; then
		# fallback for other cases
		MANMD_DIR="$(cd "$(dirname "$0")" && pwd)"
	else
		# last resort: use current directory  ¯\_(ツ)_/¯
		MANMD_DIR="$(pwd)"
	fi

	_MANMD_LOADED=1
	SHELL_NAME=$(detect_shell)

	case "$SHELL_NAME" in
	zsh)
		if [ -f "$MANMD_DIR/manmd.plugin.zsh" ]; then
			source "$MANMD_DIR/manmd.plugin.zsh"
		else
			echo "Warning: manmd.plugin.zsh not found at $MANMD_DIR" >&2
		fi
		;;
	bash)
		if [ -f "$MANMD_DIR/manmd.plugin.bash" ]; then
			source "$MANMD_DIR/manmd.plugin.bash"
		else
			echo "Warning: manmd.plugin.bash not found at $MANMD_DIR" >&2
		fi
		;;
	*)
		echo "Warning: Unknown shell '$SHELL_NAME'. Supported shells: zsh, bash, fish" >&2 # (ᗕ_ᗕ)
		echo "For fish shell, please use: source manmd-setup.fish" >&2
		;;
	esac
fi
