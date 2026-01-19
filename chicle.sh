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

# Shell-agnostic character reading helpers
_chicle_read_char() {
  if [[ -n "$ZSH_VERSION" ]]; then
    read -rsk1 "$1"
  else
    IFS= read -rsn1 "$1"
  fi
}

_chicle_read_chars() {
  local count="$1" var="$2"
  if [[ -n "$ZSH_VERSION" ]]; then
    read -rsk"$count" "$var"
  else
    read -rsn"$count" "$var"
  fi
}

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
# Usage: chicle_input [--placeholder TEXT] [--prompt TEXT] [--password] [--mask [CHAR]]
chicle_input() {
  local placeholder="" prompt="> " password="" mask=""
  while [[ $# -gt 0 ]]; do
    case $1 in
      --placeholder) placeholder="$2"; shift 2 ;;
      --prompt) prompt="$2"; shift 2 ;;
      --password) password=1; shift ;;
      --mask)
        password=1
        if [[ -n "$2" && "$2" != --* ]]; then
          mask="$2"; shift 2
        else
          mask="•"; shift
        fi
        ;;
      *) shift ;;
    esac
  done

  local value="" char=""

  # Password mode or placeholder mode both need character-by-character reading
  if [[ -n "$password" || -n "$placeholder" ]]; then
    if [[ -n "$placeholder" ]]; then
      printf "%s%b%s%b" "$prompt" "$CHICLE_DIM" "$placeholder" "$CHICLE_RESET"
      printf "\r\033[%dC" "${#prompt}"  # Move cursor to after prompt
    else
      printf "%s" "$prompt"
    fi

    while true; do
      _chicle_read_char char

      if [[ "$char" == $'\n' || "$char" == '' ]]; then
        break
      elif [[ "$char" == $'\x7f' || "$char" == $'\x08' ]]; then
        # Backspace
        if [[ -n "$value" ]]; then
          value="${value%?}"
          if [[ -n "$placeholder" && -z "$value" ]]; then
            # Show placeholder again when empty
            printf "\r\033[K%s%b%s%b" "$prompt" "$CHICLE_DIM" "$placeholder" "$CHICLE_RESET"
            printf "\r\033[%dC" "${#prompt}"
          elif [[ -n "$mask" ]]; then
            # Redraw masked value
            printf "\r\033[K%s%s" "$prompt" "$(printf '%*s' "${#value}" '' | tr ' ' "$mask")"
          elif [[ -z "$password" ]]; then
            # Normal mode - redraw value
            printf "\r\033[K%s%s" "$prompt" "$value"
          else
            # Password mode without mask - just move cursor back
            printf "\b \b"
          fi
        fi
      else
        # First char clears placeholder
        if [[ -n "$placeholder" && -z "$value" ]]; then
          printf "\r\033[K%s" "$prompt"
        fi
        value+="$char"
        if [[ -n "$mask" ]]; then
          printf "%s" "$mask"
        elif [[ -z "$password" ]]; then
          printf "%s" "$char"
        fi
        # Password without mask: print nothing
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

  if [[ -n "$ZSH_VERSION" ]]; then
    # zsh: disable monitor option
    setopt LOCAL_OPTIONS NO_MONITOR
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
  else
    # bash: use disown + temp file for exit code, suppress job messages
    local tmpfile="${TMPDIR:-/tmp}/chicle_spin.$$"
    { ( "$@"; echo $? > "$tmpfile" ) & } 2>/dev/null
    local pid=$!
    disown "$pid" 2>/dev/null

    local i=0
    while kill -0 "$pid" 2>/dev/null; do
      printf "\r%b%s%b %s" "$CHICLE_CYAN" "${frames[$i]}" "$CHICLE_RESET" "$title"
      i=$(( (i + 1) % ${#frames[@]} ))
      sleep 0.1
    done

    # Small delay to ensure exit code is written
    sleep 0.05
    local exit_code=$(cat "$tmpfile" 2>/dev/null || echo 1)
    rm -f "$tmpfile"
  fi

  if [[ $exit_code -eq 0 ]]; then
    printf "\r%b✓%b %s\n" "$CHICLE_GREEN" "$CHICLE_RESET" "$title"
  else
    printf "\r%b✗%b %s\n" "$CHICLE_RED" "$CHICLE_RESET" "$title"
  fi

  return $exit_code
}

# Interactive chooser with arrow keys
# Usage: chicle_choose [--header TEXT] [--multi] OPTION1 OPTION2 ...
chicle_choose() {
  local header="" multi="" options=()
  while [[ $# -gt 0 ]]; do
    case $1 in
      --header) header="$2"; shift 2 ;;
      --multi) multi=1; shift ;;
      *) options+=("$1"); shift ;;
    esac
  done

  local cursor=0
  local count=${#options[@]}
  local selections=()  # Track selected indices in multi mode

  [[ $count -eq 0 ]] && return 1

  # Initialize selections array (all unselected)
  for ((i=0; i<count; i++)); do
    selections+=("")
  done

  # Save cursor position and hide cursor
  tput sc
  tput civis

  # Enable raw mode
  stty -echo -icanon

  _sel_idx() {
    # zsh arrays are 1-indexed, bash are 0-indexed
    if [[ -n "$ZSH_VERSION" ]]; then
      echo $(($1 + 1))
    else
      echo $1
    fi
  }

  _is_selected() {
    local idx=$(_sel_idx $1)
    [[ -n "${selections[$idx]}" ]]
  }

  _toggle_selection() {
    local idx=$(_sel_idx $1)
    if [[ -n "${selections[$idx]}" ]]; then
      selections[$idx]=""
    else
      selections[$idx]=1
    fi
  }

  draw_menu() {
    tput rc  # Restore cursor to saved position

    [[ -n "$header" ]] && printf "%b%s%b\n" "$CHICLE_BOLD" "$header" "$CHICLE_RESET"

    local i=0
    for opt in "${options[@]}"; do
      if [[ -n "$multi" ]]; then
        # Multi-select mode: show checkboxes
        local checkbox="[ ]"
        _is_selected $i && checkbox="[x]"
        if [[ $i -eq $cursor ]]; then
          printf "%b❯ %s %s%b\n" "$CHICLE_CYAN" "$checkbox" "$opt" "$CHICLE_RESET"
        else
          printf "  %s %s\n" "$checkbox" "$opt"
        fi
      else
        # Single-select mode
        if [[ $i -eq $cursor ]]; then
          printf "%b❯ %s%b\n" "$CHICLE_CYAN" "$opt" "$CHICLE_RESET"
        else
          printf "  %s\n" "$opt"
        fi
      fi
      ((i++))
    done
  }

  draw_menu

  while true; do
    _chicle_read_char key

    if [[ $key == $'\x1b' ]]; then
      _chicle_read_chars 2 key
      case $key in
        '[A') ((cursor > 0)) && ((cursor--)) ;;           # Up
        '[B') ((cursor < count - 1)) && ((cursor++)) ;;   # Down
      esac
      draw_menu
    elif [[ $key == ' ' && -n "$multi" ]]; then  # Space toggles in multi mode
      _toggle_selection $cursor
      draw_menu
    elif [[ $key == '' || $key == $'\n' ]]; then  # Enter
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

  if [[ -n "$multi" ]]; then
    # Output all selected items, newline-separated
    local i=0
    for opt in "${options[@]}"; do
      if _is_selected $i; then
        echo "$opt"
      fi
      ((i++))
    done
  else
    # Single select: output the one item at cursor
    # zsh arrays are 1-indexed, bash arrays are 0-indexed
    if [[ -n "$ZSH_VERSION" ]]; then
      echo "${options[$((cursor + 1))]}"
    else
      echo "${options[$cursor]}"
    fi
  fi
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

# Styled log output with icons
# Usage: chicle_log --info|--success|--warn|--error|--debug|--step MESSAGE
chicle_log() {
  local level="" message=""
  while [[ $# -gt 0 ]]; do
    case $1 in
      --info|--success|--warn|--error|--debug|--step)
        level="${1#--}"; shift ;;
      *)
        message="$1"; shift ;;
    esac
  done

  case $level in
    info)    printf "%b%s%b %s\n" "$CHICLE_CYAN"   "ℹ" "$CHICLE_RESET" "$message" ;;
    success) printf "%b%s%b %s\n" "$CHICLE_GREEN"  "✓" "$CHICLE_RESET" "$message" ;;
    warn)    printf "%b%s%b %s\n" "$CHICLE_YELLOW" "⚠" "$CHICLE_RESET" "$message" ;;
    error)   printf "%b%s%b %s\n" "$CHICLE_RED"    "✗" "$CHICLE_RESET" "$message" ;;
    debug)   printf "%b%s %s%b\n" "$CHICLE_DIM"    "·" "$message" "$CHICLE_RESET" ;;
    step)    printf "%b%s %s%b\n" "$CHICLE_BOLD"   "→" "$message" "$CHICLE_RESET" ;;
    *)       printf "%s\n" "$message" ;;
  esac
}

# Step indicator for multi-step processes
# Usage: chicle_steps --current N --total M [--title TEXT] [--style numeric|dots|progress]
chicle_steps() {
  local current=0 total=0 title="" style="numeric"
  while [[ $# -gt 0 ]]; do
    case $1 in
      --current) current="$2"; shift 2 ;;
      --total) total="$2"; shift 2 ;;
      --title) title="$2"; shift 2 ;;
      --style) style="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  [[ $total -eq 0 ]] && return 1

  case $style in
    numeric)
      printf "%b[%d/%d]%b %s\n" "$CHICLE_BOLD" "$current" "$total" "$CHICLE_RESET" "$title"
      ;;
    dots)
      local dots=""
      for ((i=1; i<=total; i++)); do
        if [[ $i -le $current ]]; then
          dots+="●"
        else
          dots+="○"
        fi
        [[ $i -lt $total ]] && dots+=" "
      done
      printf "%b%s%b  %s\n" "$CHICLE_CYAN" "$dots" "$CHICLE_RESET" "$title"
      ;;
    progress)
      local filled=$((current * 5 / total))
      local empty=$((5 - filled))
      local bar=""
      for ((i=0; i<filled; i++)); do bar+="█"; done
      for ((i=0; i<empty; i++)); do bar+="░"; done
      printf "%b[%s]%b %s\n" "$CHICLE_CYAN" "$bar" "$CHICLE_RESET" "$title"
      ;;
    *)
      printf "[%d/%d] %s\n" "$current" "$total" "$title"
      ;;
  esac
}

# Progress bar with in-place updating
# Usage: chicle_progress --percent N [--title TEXT] [--width W]
#    or: chicle_progress --current N --total M [--title TEXT] [--width W]
chicle_progress() {
  local percent="" current="" total="" title="" width=""
  while [[ $# -gt 0 ]]; do
    case $1 in
      --percent) percent="$2"; shift 2 ;;
      --current) current="$2"; shift 2 ;;
      --total) total="$2"; shift 2 ;;
      --title) title="$2"; shift 2 ;;
      --width) width="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  # Calculate percent from current/total if not given directly
  if [[ -z "$percent" && -n "$current" && -n "$total" && "$total" -gt 0 ]]; then
    percent=$((current * 100 / total))
  fi

  [[ -z "$percent" ]] && percent=0
  [[ $percent -gt 100 ]] && percent=100
  [[ $percent -lt 0 ]] && percent=0

  # Auto-calculate bar width: terminal width minus title, percentage, brackets, spaces
  if [[ -z "$width" ]]; then
    local cols
    cols=$(tput cols 2>/dev/null || echo 80)
    # Reserve space for: title + space + [ + ] + space + 100% (4 chars)
    local reserved=$(( ${#title} + 8 ))
    width=$((cols - reserved))
    [[ $width -lt 10 ]] && width=10
    [[ $width -gt 50 ]] && width=50
  fi

  local filled=$((percent * width / 100))
  local empty=$((width - filled))

  local bar=""
  for ((i=0; i<filled; i++)); do bar+="█"; done
  for ((i=0; i<empty; i++)); do bar+="░"; done

  local color="$CHICLE_CYAN"
  [[ $percent -eq 100 ]] && color="$CHICLE_GREEN"

  # Print with \r to update in place (no newline)
  printf "\r%s %b[%s]%b %3d%%" "$title" "$color" "$bar" "$CHICLE_RESET" "$percent"
}
