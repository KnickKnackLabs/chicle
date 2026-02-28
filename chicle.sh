#!/usr/bin/env bash
# chicle - Pure bash TUI library for delightful shell scripts

export CHICLE_VERSION="dev"

# Colors
CHICLE_BOLD='\033[1m'
CHICLE_DIM='\033[2m'
CHICLE_RESET='\033[0m'
CHICLE_CYAN='\033[36m'
CHICLE_GREEN='\033[32m'
CHICLE_YELLOW='\033[33m'
CHICLE_RED='\033[31m'

# Read timeout for interruptible input (ctrl-c detection).
# Probe whether fractional timeouts are supported (bash 3.2 rejects them).
if [[ -z "$(read -r -t 0.01 </dev/null 2>&1)" ]]; then
  _chicle_read_timeout=0.05
else
  _chicle_read_timeout=1
fi

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
    read -rsk"$count" "${var?}"
  else
    read -rsn"$count" "${var?}"
  fi
}

# Repeat a character N times (multi-byte safe, unlike tr)
_chicle_repeat() {
  local i char="$1" count="$2"
  for ((i=0; i<count; i++)); do printf "%s" "$char"; done
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
      printf "%s%b%s%b" "$prompt" "$CHICLE_DIM" "$placeholder" "$CHICLE_RESET" >/dev/tty
      printf "\r\033[%dC" "${#prompt}" >/dev/tty  # Move cursor to after prompt
    else
      printf "%s" "$prompt" >/dev/tty
    fi

    while true; do
      _chicle_read_char char </dev/tty

      if [[ "$char" == $'\n' || "$char" == '' ]]; then
        break
      elif [[ "$char" == $'\x7f' || "$char" == $'\x08' ]]; then
        # Backspace
        if [[ -n "$value" ]]; then
          value="${value%?}"
          if [[ -n "$placeholder" && -z "$value" ]]; then
            # Show placeholder again when empty
            printf "\r\033[K%s%b%s%b" "$prompt" "$CHICLE_DIM" "$placeholder" "$CHICLE_RESET" >/dev/tty
            printf "\r\033[%dC" "${#prompt}" >/dev/tty
          elif [[ -n "$mask" ]]; then
            # Redraw masked value
            printf "\r\033[K%s%s" "$prompt" "$(_chicle_repeat "$mask" "${#value}")" >/dev/tty
          elif [[ -z "$password" ]]; then
            # Normal mode - redraw value
            printf "\r\033[K%s%s" "$prompt" "$value" >/dev/tty
          else
            # Password mode without mask - just move cursor back
            printf "\b \b" >/dev/tty
          fi
        fi
      else
        # First char clears placeholder
        if [[ -n "$placeholder" && -z "$value" ]]; then
          printf "\r\033[K%s" "$prompt" >/dev/tty
        fi
        value+="$char"
        if [[ -n "$mask" ]]; then
          printf "%s" "$mask" >/dev/tty
        elif [[ -z "$password" ]]; then
          printf "%s" "$char" >/dev/tty
        fi
        # Password without mask: print nothing
      fi
    done
    printf "\n" >/dev/tty
  else
    printf "%s" "$prompt" >/dev/tty
    IFS= read -r value </dev/tty
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

  printf "%b%s%b %s " "$CHICLE_BOLD" "$prompt" "$CHICLE_RESET" "$hint" >/dev/tty
  read -r reply </dev/tty

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
    local exit_code
    exit_code=$(cat "$tmpfile" 2>/dev/null || echo 1)
    rm -f "$tmpfile"
  fi

  if [[ $exit_code -eq 0 ]]; then
    printf "\r%b✓%b %s\n" "$CHICLE_GREEN" "$CHICLE_RESET" "$title"
  else
    printf "\r%b✗%b %s\n" "$CHICLE_RED" "$CHICLE_RESET" "$title"
  fi

  return "$exit_code"
}

# Interactive chooser with arrow keys
# Usage: chicle_choose [--header TEXT] [--multi] [--var VARNAME] OPTION1 OPTION2 ...
# --var writes the result to a variable instead of stdout, avoiding $(...) subshells
# where ctrl-c would kill the parent process.
chicle_choose() {
  local header="" multi="" _chicle_var="" options=()
  while [[ $# -gt 0 ]]; do
    case $1 in
      --header) header="$2"; shift 2 ;;
      --multi) multi=1; shift ;;
      --var) _chicle_var="$2"; shift 2 ;;
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

  # Terminal cleanup helper
  local _chicle_interrupted=""
  _chicle_choose_cleanup() {
    stty echo icanon </dev/tty 2>/dev/null
    tput cnorm >/dev/tty 2>/dev/null
  }
  # On signal: set flag only. Don't restore terminal mode here — changing
  # stty back to cooked mode while read -n1 is waiting causes it to need
  # Enter (line-buffered input) instead of returning on any keypress.
  # Terminal is restored after the loop exits.
  local _chicle_prev_int _chicle_prev_term
  _chicle_prev_int=$(trap -p INT)
  _chicle_prev_term=$(trap -p TERM)
  trap '_chicle_interrupted=1' INT TERM

  # Calculate total menu lines (for relative cursor movement)
  local menu_lines=$count
  [[ -n "$header" ]] && ((menu_lines++))

  # Hide cursor
  tput civis >/dev/tty

  # Enable raw mode
  stty -echo -icanon </dev/tty

  local _chicle_drawn=0

  _sel_idx() {
    # zsh arrays are 1-indexed, bash are 0-indexed
    if [[ -n "$ZSH_VERSION" ]]; then
      echo $(($1 + 1))
    else
      echo "$1"
    fi
  }

  _is_selected() {
    local idx
    idx=$(_sel_idx "$1")
    [[ -n "${selections[idx]}" ]]
  }

  _toggle_selection() {
    local idx
    idx=$(_sel_idx "$1")
    if [[ -n "${selections[idx]}" ]]; then
      selections[idx]=""
    else
      selections[idx]=1
    fi
  }

  draw_menu() {
    # Move cursor up to overwrite previous draw (skip on first draw)
    if [[ $_chicle_drawn -eq 1 ]]; then
      printf "\033[%dA" "$menu_lines" >/dev/tty
    fi
    _chicle_drawn=1

    [[ -n "$header" ]] && printf "%b%s%b\n" "$CHICLE_BOLD" "$header" "$CHICLE_RESET" >/dev/tty

    local i=0
    for opt in "${options[@]}"; do
      if [[ -n "$multi" ]]; then
        # Multi-select mode: show checkboxes
        local checkbox="[ ]"
        _is_selected $i && checkbox="[x]"
        if [[ $i -eq $cursor ]]; then
          printf "%b❯ %s %s%b\n" "$CHICLE_CYAN" "$checkbox" "$opt" "$CHICLE_RESET" >/dev/tty
        else
          printf "  %s %s\n" "$checkbox" "$opt" >/dev/tty
        fi
      else
        # Single-select mode
        if [[ $i -eq $cursor ]]; then
          printf "%b❯ %s%b\n" "$CHICLE_CYAN" "$opt" "$CHICLE_RESET" >/dev/tty
        else
          printf "  %s\n" "$opt" >/dev/tty
        fi
      fi
      ((i++))
    done
  }

  draw_menu

  local key=""
  while true; do
    # Read a keypress, with timeout so ctrl-c interrupt flag is checked.
    # Both bash and zsh restart read after signal traps (SA_RESTART), so
    # without a timeout, ctrl-c sets the flag but read blocks until the
    # next keypress. Polling with read -t lets us check the flag.
    key=""
    if [[ -n "$ZSH_VERSION" ]]; then
      while [[ -z "$_chicle_interrupted" ]]; do
        if read -rsk1 -t "$_chicle_read_timeout" key </dev/tty; then
          break  # zsh: 0 = got input, 1 = timeout
        fi
      done
    else
      while [[ -z "$_chicle_interrupted" ]]; do
        IFS= read -rsn1 -t "$_chicle_read_timeout" key </dev/tty
        [[ $? -le 128 ]] && break  # bash: 0 = got input, >128 = timeout
      done
    fi
    [[ -n "$_chicle_interrupted" ]] && break

    if [[ $key == $'\x1b' ]]; then
      _chicle_read_chars 2 key </dev/tty
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
      _chicle_choose_cleanup
      eval "${_chicle_prev_int:-trap - INT}"
      eval "${_chicle_prev_term:-trap - TERM}"
      return 1
    fi
  done

  # Restore terminal and previous signal handlers
  _chicle_choose_cleanup
  eval "${_chicle_prev_int:-trap - INT}"
  eval "${_chicle_prev_term:-trap - TERM}"

  # If interrupted by signal, return 130 (SIGINT convention)
  [[ -n "$_chicle_interrupted" ]] && return 130

  local _chicle_result=""
  if [[ -n "$multi" ]]; then
    # Output all selected items, newline-separated
    local i=0
    for opt in "${options[@]}"; do
      if _is_selected $i; then
        [[ -n "$_chicle_result" ]] && _chicle_result+=$'\n'
        _chicle_result+="$opt"
      fi
      ((i++))
    done
  else
    # Single select: output the one item at cursor
    # zsh arrays are 1-indexed, bash arrays are 0-indexed
    if [[ -n "$ZSH_VERSION" ]]; then
      _chicle_result="${options[$((cursor + 1))]}"
    else
      _chicle_result="${options[$cursor]}"
    fi
  fi

  if [[ -n "$_chicle_var" ]]; then
    printf -v "$_chicle_var" '%s' "$_chicle_result"
  else
    echo "$_chicle_result"
  fi
}

# Print a horizontal rule
# Usage: chicle_rule [--char CHAR]
chicle_rule() {
  local char="─"
  [[ "$1" == "--char" ]] && char="$2"
  local cols
  cols=$(tput cols)
  _chicle_repeat "$char" "$cols"
  printf '\n'
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
      local bar
      bar="$(_chicle_repeat "█" "$filled")$(_chicle_repeat "░" "$empty")"
      printf "%b[%s]%b %s\n" "$CHICLE_CYAN" "$bar" "$CHICLE_RESET" "$title"
      ;;
    *)
      printf "[%d/%d] %s\n" "$current" "$total" "$title"
      ;;
  esac
}

# Formatted table output
# Usage: chicle_table [--header FIELDS] [--sep CHAR] [--style box|simple] ROW1 ROW2 ...
#    or: ... | chicle_table [--header FIELDS] [--sep CHAR] [--style box|simple]
chicle_table() {
  local header="" sep="," style="box" rows=()
  while [[ $# -gt 0 ]]; do
    case $1 in
      --header) header="$2"; shift 2 ;;
      --sep) sep="$2"; shift 2 ;;
      --style) style="$2"; shift 2 ;;
      *) rows+=("$1"); shift ;;
    esac
  done

  # Read from stdin if no rows provided and stdin is not a terminal
  if [[ ${#rows[@]} -eq 0 ]] && [[ ! -t 0 ]]; then
    while IFS= read -r line; do
      [[ -n "$line" ]] && rows+=("$line")
    done
  fi

  [[ ${#rows[@]} -eq 0 && -z "$header" ]] && return 1

  local _fields

  # Split a delimited string into the _fields array
  _chicle_split() {
    _fields=()
    local str="$1" s="$2" tmp=""
    while [[ "$str" == *"$s"* ]]; do
      tmp="${str%%"$s"*}"
      _fields+=("$tmp")
      str="${str#*"$s"}"
    done
    _fields+=("$str")
  }

  # Build all data rows as arrays and calculate column widths
  local -a widths=()
  local -a all_rows=()
  local ncols=0

  # Process header first to establish column count
  if [[ -n "$header" ]]; then
    _chicle_split "$header" "$sep"
    ncols=${#_fields[@]}
    for ((c=0; c<ncols; c++)); do
      widths[c]=${#_fields[c]}
    done
    all_rows+=("H:$header")
  fi

  # Process data rows
  for row in "${rows[@]}"; do
    _chicle_split "$row" "$sep"
    local rc=${#_fields[@]}
    if [[ $rc -gt $ncols ]]; then
      ncols=$rc
      # Extend widths array
      for ((c=${#widths[@]}; c<ncols; c++)); do
        widths[c]=0
      done
    fi
    for ((c=0; c<rc; c++)); do
      local len=${#_fields[c]}
      [[ $len -gt ${widths[c]:-0} ]] && widths[c]=$len
    done
    all_rows+=("D:$row")
  done

  [[ $ncols -eq 0 ]] && return 1

  # Render functions
  _chicle_box_line() {
    local left="$1" mid="$2" right="$3" fill="$4"
    printf "%s" "$left"
    for ((c=0; c<ncols; c++)); do
      _chicle_repeat "$fill" $((widths[c] + 2))
      [[ $c -lt $((ncols - 1)) ]] && printf "%s" "$mid"
    done
    printf "%s\n" "$right"
  }

  _chicle_box_row() {
    local row_str="$1" is_header="$2"
    _chicle_split "$row_str" "$sep"
    printf "│"
    for ((c=0; c<ncols; c++)); do
      local val="${_fields[$c]:-}"
      local w=${widths[$c]}
      if [[ -n "$is_header" ]]; then
        printf " %b%-*s%b │" "$CHICLE_BOLD" "$w" "$val" "$CHICLE_RESET"
      else
        printf " %-*s │" "$w" "$val"
      fi
    done
    printf "\n"
  }

  _chicle_simple_row() {
    local row_str="$1" is_header="$2"
    _chicle_split "$row_str" "$sep"
    for ((c=0; c<ncols; c++)); do
      local val="${_fields[$c]:-}"
      local w=${widths[$c]}
      if [[ -n "$is_header" ]]; then
        printf "%b%-*s%b" "$CHICLE_BOLD" "$w" "$val" "$CHICLE_RESET"
      else
        printf "%-*s" "$w" "$val"
      fi
      [[ $c -lt $((ncols - 1)) ]] && printf "  "
    done
    printf "\n"
  }

  _chicle_simple_separator() {
    for ((c=0; c<ncols; c++)); do
      _chicle_repeat "─" "${widths[$c]}"
      [[ $c -lt $((ncols - 1)) ]] && printf "  "
    done
    printf "\n"
  }

  # Render table
  if [[ "$style" == "box" ]]; then
    _chicle_box_line "┌" "┬" "┐" "─"
    for entry in "${all_rows[@]}"; do
      local type="${entry%%:*}"
      local data="${entry#*:}"
      if [[ "$type" == "H" ]]; then
        _chicle_box_row "$data" 1
        _chicle_box_line "├" "┼" "┤" "─"
      else
        _chicle_box_row "$data" ""
      fi
    done
    _chicle_box_line "└" "┴" "┘" "─"
  else
    # Simple style
    for entry in "${all_rows[@]}"; do
      local type="${entry%%:*}"
      local data="${entry#*:}"
      if [[ "$type" == "H" ]]; then
        _chicle_simple_row "$data" 1
        _chicle_simple_separator
      else
        _chicle_simple_row "$data" ""
      fi
    done
  fi
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
  local bar
  bar="$(_chicle_repeat "█" "$filled")$(_chicle_repeat "░" "$empty")"

  local color="$CHICLE_CYAN"
  [[ $percent -eq 100 ]] && color="$CHICLE_GREEN"

  # Print with \r to update in place (no newline)
  printf "\r%s %b[%s]%b %3d%%" "$title" "$color" "$bar" "$CHICLE_RESET" "$percent"
}
