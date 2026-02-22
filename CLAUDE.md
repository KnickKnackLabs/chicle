# CLAUDE.md

## Project Overview

Chicle is a TUI library for creating interactive shell scripts, with implementations in both Bash and PowerShell. Both produce identical ANSI output for the same inputs.

- **Bash** (`chicle.sh`): Zero external dependencies — just bash 4+ and standard Unix tools (tput, stty)
- **PowerShell** (`chicle.psm1`): PowerShell 7+ module using .NET Console APIs

## Architecture

### Bash (`chicle.sh`)

Single file library that scripts can source. All functions are prefixed with `chicle_`.

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

### PowerShell (`chicle.psm1`)

PowerShell module using Verb-Noun naming. Import with `Import-Module ./chicle.psm1`.

| Function | Purpose |
|----------|---------|
| `Chicle-Style` | Format text with colors and bold/dim |
| `Chicle-Input` | Prompt for text input |
| `Chicle-Confirm` | Yes/no confirmation prompt |
| `Chicle-Choose` | Interactive arrow-key menu picker |
| `Chicle-Spin` | Spinner animation while command runs |
| `Chicle-Rule` | Print horizontal line |
| `Chicle-Log` | Styled log output with icons |
| `Chicle-Steps` | Step indicator for multi-step processes |
| `Chicle-Table` | Formatted table output |
| `Chicle-Progress` | Progress bar with in-place updating |

### Terminal Control

Both implementations use the same ANSI escape codes for colors and styling. Platform-specific differences:

- **Bash**: `tput` for cursor control, `stty` for raw mode
- **PowerShell**: `[Console]` .NET APIs for cursor control and key reading

## Testing

### Bash Tests (BATS)

```bash
bash test.sh
```

Requires [BATS](https://github.com/bats-core/bats-core) (`apt install bats` / `brew install bats-core`). Falls back to legacy test runner if BATS is not installed.

Tests require `TERM` to be set (CI uses `TERM=xterm`). Interactive tests require `expect` and `perl`. Zsh compatibility tests require `zsh`.

### PowerShell Tests (Pester)

```powershell
pwsh test.ps1
```

Requires [Pester](https://pester.dev/) 5+ (`Install-Module Pester -MinimumVersion 5.0 -Force`).

### Shared Golden Fixtures

Both test suites validate against shared golden fixture files in `test/fixtures/`. These contain the exact expected output (including ANSI codes) for deterministic functions: style, log, steps, progress, and table. This ensures both implementations produce identical output.

## Linting

ShellCheck is used for static analysis of bash code:

```bash
shellcheck chicle.sh
shellcheck -x test.sh
```

## Compatibility

- **Bash**: Targets bash 4+ on macOS and Linux. Relies on `tput` (ncurses) and `stty` (coreutils).
- **PowerShell**: Targets PowerShell 7+ on Windows, macOS, and Linux.
