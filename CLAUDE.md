# CLAUDE.md

## Project Overview

Chicle is a pure bash TUI library for creating interactive shell scripts. Zero external dependencies - just bash and standard Unix tools (tput, stty). A PowerShell port (`chicle.psm1`) provides the same functions for Windows/PowerShell 7+.

## Architecture

### Bash
Single file library (`chicle.sh`) that scripts can source. All functions are prefixed with `chicle_`.

### PowerShell
Module file (`chicle.psm1`) loaded via `Import-Module`. Functions use Verb-Noun naming (`Invoke-ChicleStyle`, etc.).

### Functions

| Bash | PowerShell | Purpose |
|------|-----------|---------|
| `chicle_style` | `Invoke-ChicleStyle` | Format text with colors and bold/dim |
| `chicle_input` | (planned) | Prompt for text input |
| `chicle_confirm` | (planned) | Yes/no confirmation prompt |
| `chicle_choose` | (planned) | Interactive arrow-key menu picker |
| `chicle_spin` | (planned) | Spinner animation while command runs |
| `chicle_rule` | `Invoke-ChicleRule` | Print horizontal line |
| `chicle_log` | `Invoke-ChicleLog` | Styled log output with icons |
| `chicle_steps` | `Invoke-ChicleSteps` | Step indicator for multi-step processes |
| `chicle_progress` | `Invoke-ChicleProgress` | Progress bar with in-place updating |

### Terminal Control

- Uses ANSI escape codes for colors (both bash and PowerShell)
- Bash: `tput` for cursor control, `stty` for raw mode
- PowerShell: `[Console]` class for cursor control and key reading

## Testing

### Run tests

```bash
# Bash tests (requires expect for interactive tests)
bash tests/test.sh

# PowerShell tests
pwsh tests/test.ps1
```

### Golden file testing

Non-interactive tests compare output against golden files in `tests/golden/`. These files are plain text (ANSI codes stripped) and serve as the cross-platform contract between bash and PowerShell.

```bash
# Update golden files after intentional output changes
bash tests/test.sh --update
# or
UPDATE_GOLDENS=1 bash tests/test.sh
```

### Test structure

```
tests/
  helpers.sh          # Bash test utilities (strip_ansi, check_golden, pass, fail)
  test.sh             # Bash test runner
  test.ps1            # PowerShell test runner
  golden/             # Golden files (one per test case, organized by function)
```

## Compatibility

- Bash: bash 3.2+ (stock macOS compatible). Relies on `tput` (ncurses) and `stty` (coreutils).
- PowerShell: PowerShell 7+ (cross-platform). Uses `[char]27` for ANSI codes.
