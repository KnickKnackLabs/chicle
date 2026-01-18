#!/usr/bin/env bash
# chicle - Pure bash TUI library for delightful shell scripts

# Colors
CHICLE_BOLD='\033[1m'
CHICLE_DIM='\033[2m'
CHICLE_RESET='\033[0m'
CHICLE_CYAN='\033[36m'
CHICLE_GREEN='\033[32m'
CHICLE_YELLOW='\033[33m'
CHICLE_RED='\033[31m'

# Style text with formatting
# Usage: chicle_style [--bold] [--dim] [--color COLOR] TEXT
chicle_style() {
  local bold="" dim="" color="" text=""
  while [[ $# -gt 0 ]]; do
    case $1 in
      --bold) bold="$CHICLE_BOLD"; shift ;;
      --dim) dim="$CHICLE_DIM"; shift ;;
      --cyan) color="$CHICLE_CYAN"; shift ;;
      --green) color="$CHICLE_GREEN"; shift ;;
      --yellow) color="$CHICLE_YELLOW"; shift ;;
      --red) color="$CHICLE_RED"; shift ;;
      *) text="$1"; shift ;;
    esac
  done
  printf "%b%b%b%s%b" "$bold" "$dim" "$color" "$text" "$CHICLE_RESET"
}

# Prompt for text input
# Usage: chicle_input [--placeholder TEXT] [--prompt TEXT]
chicle_input() {
  local placeholder="" prompt="> "
  while [[ $# -gt 0 ]]; do
    case $1 in
      --placeholder) placeholder="$2"; shift 2 ;;
      --prompt) prompt="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  local value="" char=""

  # Helper to read one character (shell-agnostic)
  _read_char() {
    if [[ -n "$ZSH_VERSION" ]]; then
      read -rsk1 char
    else
      read -rsn1 char
    fi
  }

  if [[ -n "$placeholder" ]]; then
    printf "%s%b%s%b" "$prompt" "$CHICLE_DIM" "$placeholder" "$CHICLE_RESET"
    printf "\r\033[%dC" "${#prompt}"  # Move cursor to after prompt

    while true; do
      _read_char

      if [[ "$char" == $'\n' || "$char" == '' ]]; then
        break
      elif [[ "$char" == $'\x7f' || "$char" == $'\x08' ]]; then
        # Backspace
        if [[ -n "$value" ]]; then
          value="${value%?}"
          if [[ -z "$value" ]]; then
            # Show placeholder again when empty
            printf "\r\033[K%s%b%s%b" "$prompt" "$CHICLE_DIM" "$placeholder" "$CHICLE_RESET"
            printf "\r\033[%dC" "${#prompt}"
          else
            printf "\r\033[K%s%s" "$prompt" "$value"
          fi
        fi
      else
        # First char clears placeholder
        if [[ -z "$value" ]]; then
          printf "\r\033[K%s" "$prompt"
        fi
        value+="$char"
        printf "%s" "$char"
      fi
    done
    printf "\n"
  else
    printf "%s" "$prompt"
    IFS= read -r value
  fi

  echo "$value"
}

# Yes/no confirmation
# Usage: chicle_confirm [--default yes|no] PROMPT
chicle_confirm() {
  local default="no" prompt=""
  while [[ $# -gt 0 ]]; do
    case $1 in
      --default) default="$2"; shift 2 ;;
      *) prompt="$1"; shift ;;
    esac
  done

  local hint="[y/N]"
  [[ "$default" == "yes" ]] && hint="[Y/n]"

  printf "%b%s%b %s " "$CHICLE_BOLD" "$prompt" "$CHICLE_RESET" "$hint"
  read -r reply

  if [[ -z "$reply" ]]; then
    [[ "$default" == "yes" ]]
  else
    [[ $reply =~ ^[Yy] ]]
  fi
}

# Spinner while command runs
# Usage: chicle_spin [--title TEXT] -- COMMAND
chicle_spin() {
  local title=""
  while [[ $# -gt 0 ]]; do
    case $1 in
      --title) title="$2"; shift 2 ;;
      --) shift; break ;;
      *) shift ;;
    esac
  done

  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

  "$@" &
  local pid=$!

  local i=0
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r%b%s%b %s" "$CHICLE_CYAN" "${frames[$i]}" "$CHICLE_RESET" "$title"
    i=$(( (i + 1) % ${#frames[@]} ))
    sleep 0.1
  done

  wait "$pid"
  local exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    printf "\r%b✓%b %s\n" "$CHICLE_GREEN" "$CHICLE_RESET" "$title"
  else
    printf "\r%b✗%b %s\n" "$CHICLE_RED" "$CHICLE_RESET" "$title"
  fi

  return $exit_code
}

# Interactive chooser with arrow keys
# Usage: chicle_choose [--header TEXT] OPTION1 OPTION2 ...
chicle_choose() {
  local header="" options=()
  while [[ $# -gt 0 ]]; do
    case $1 in
      --header) header="$2"; shift 2 ;;
      *) options+=("$1"); shift ;;
    esac
  done

  local selected=0
  local count=${#options[@]}

  [[ $count -eq 0 ]] && return 1

  # Save cursor position and hide cursor
  tput sc
  tput civis

  # Enable raw mode
  stty -echo -icanon

  draw_menu() {
    tput rc  # Restore cursor to saved position

    [[ -n "$header" ]] && printf "%b%s%b\n" "$CHICLE_BOLD" "$header" "$CHICLE_RESET"

    for i in "${!options[@]}"; do
      if [[ $i -eq $selected ]]; then
        printf "%b❯ %s%b\n" "$CHICLE_CYAN" "${options[$i]}" "$CHICLE_RESET"
      else
        printf "  %s\n" "${options[$i]}"
      fi
    done
  }

  draw_menu

  while true; do
    read -rsn1 key

    if [[ $key == $'\x1b' ]]; then
      read -rsn2 key
      case $key in
        '[A') ((selected > 0)) && ((selected--)) ;;           # Up
        '[B') ((selected < count - 1)) && ((selected++)) ;;   # Down
      esac
      draw_menu
    elif [[ $key == '' ]]; then  # Enter
      break
    elif [[ $key == 'q' ]]; then  # Quit
      stty echo icanon
      tput cnorm
      return 1
    fi
  done

  # Restore terminal
  stty echo icanon
  tput cnorm

  echo "${options[$selected]}"
}

# Print a horizontal rule
# Usage: chicle_rule [--char CHAR]
chicle_rule() {
  local char="─"
  [[ "$1" == "--char" ]] && char="$2"
  local cols
  cols=$(tput cols)
  printf '%*s\n' "$cols" '' | tr ' ' "$char"
}
