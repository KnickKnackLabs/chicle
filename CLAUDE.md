# CLAUDE.md

## Project Overview

Chicle is a pure bash TUI library for creating interactive shell scripts. Zero external dependencies - just bash and standard Unix tools (tput, stty).

## Architecture

Single file library (`chicle.sh`) that scripts can source. All functions are prefixed with `chicle_`.

### Functions

| Function | Purpose |
|----------|---------|
| `chicle_style` | Format text with colors and bold/dim |
| `chicle_input` | Prompt for text input |
| `chicle_confirm` | Yes/no confirmation prompt |
| `chicle_choose` | Interactive arrow-key menu picker |
| `chicle_spin` | Spinner animation while command runs |
| `chicle_rule` | Print horizontal line |

### Terminal Control

- Uses ANSI escape codes for colors
- Uses `tput` for cursor control (hide/show, save/restore position)
- Uses `stty` for raw mode (capturing arrow keys without Enter)

## Testing

Manual testing - source the library and try each function:

```bash
source chicle.sh
chicle_style --bold --cyan "Test"
chicle_confirm "Works?"
chicle_choose "A" "B" "C"
```

## Compatibility

Targets bash 4+ on macOS and Linux. Relies on:
- `tput` (ncurses)
- `stty` (coreutils)
