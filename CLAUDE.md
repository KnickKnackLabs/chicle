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
| `chicle_log` | Styled log output with icons |
| `chicle_steps` | Step indicator for multi-step processes |
| `chicle_table` | Formatted table output |
| `chicle_progress` | Progress bar with in-place updating |

### Terminal Control

- Uses ANSI escape codes for colors
- Uses `tput` for cursor control (hide/show, save/restore position)
- Uses `stty` for raw mode (capturing arrow keys without Enter)

## Testing

Run the automated test suite:

```bash
bash test.sh
```

Tests require `TERM` to be set (CI uses `TERM=xterm`). Interactive tests (chicle_choose, chicle_confirm, chicle_input) require `expect` and `perl`. Zsh compatibility tests additionally require `zsh`.

## Linting

ShellCheck is used for static analysis:

```bash
shellcheck chicle.sh
shellcheck -x test.sh
```

## Compatibility

Targets bash 4+ on macOS and Linux. Relies on:
- `tput` (ncurses)
- `stty` (coreutils)
