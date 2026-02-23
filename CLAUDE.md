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

## Development

All tasks are managed through mise. Run `mise tasks` to see available commands.

```bash
mise install          # Install tool dependencies
mise run setup        # Install PowerShell modules (Pester, PSScriptAnalyzer)
mise run test         # Run all tests (bash + powershell)
mise run test:bash    # Run BATS tests only
mise run test:pwsh    # Run Pester tests only
mise run lint         # Run all linters (shellcheck + psscriptanalyzer)
mise run lint:sh      # ShellCheck only
mise run lint:pwsh    # PSScriptAnalyzer only
```

Bash tests require `TERM` to be set (CI uses `TERM=xterm`). Interactive tests require `expect` and `perl`. Zsh compatibility tests require `zsh`.

### Shared Golden Fixtures

Both test suites validate against shared golden fixture files in `test/fixtures/`. These contain the exact expected output (including ANSI codes) for deterministic functions: style, log, steps, progress, and table. This ensures both implementations produce identical output.

## Releases

Releases are automated via `.github/workflows/release.yml`. To cut a new release:

1. Push a semver tag: `git tag -s v1.2.3 -m "v1.2.3" && git push origin v1.2.3`
2. CI validates the tag format, injects the version into `chicle.sh` and `chicle.psm1` (replacing `"dev"`), generates SHA256 checksums, and creates a GitHub release with all three files as assets.

Source files always have `CHICLE_VERSION="dev"` — the real version only exists in release artifacts.

## Compatibility

- **Bash**: Targets bash 4+ on macOS and Linux. Relies on `tput` (ncurses) and `stty` (coreutils).
- **PowerShell**: Targets PowerShell 7+ on Windows, macOS, and Linux.
