# Chicle

```
                                 ╭──────╮
                                ╱        ╲
                     ╭─────────╱    ╭╮    ╲─────────╮
                    ╱   ╭─────╱     ││     ╲─────╮   ╲
                   ╱   ╱     ╱   ╭──╯╰──╮   ╲     ╲   ╲
                  ╱   ╱     ╱   ╱        ╲   ╲     ╲   ╲
                 ╱   ╱     ╱   ╱    ╭╮    ╲   ╲     ╲   ╲
                ╱   ╱     ╱   ╱     ╰╯     ╲   ╲     ╲   ╲
               ╱   ╱     ╱   ╱              ╲   ╲     ╲   ╲
              ╱   ╱     ╱   ╱                ╲   ╲     ╲   ╲
              ╲   ╲     ╲   ╲    S A P O     ╱   ╱     ╱   ╱
               ╲   ╲     ╲   ╲   D I L L A  ╱   ╱     ╱   ╱
                ╲   ╲     ╲   ╲            ╱   ╱     ╱   ╱
                 ╲   ╲     ╲   ╰──────────╯   ╱     ╱   ╱
                  ╲   ╰─────╲               ╱─────╯   ╱
                   ╲         ╲     ║║     ╱         ╱
                    ╰─────────╲    ║║    ╱─────────╯
                               ╲   ║║   ╱
                                ╲  ║║  ╱
                                 ╲ ║║ ╱
                                  ╲║║╱
                                   ║║
                                   ║║
                                ╭──╨╨──╮
                                │  me  │
                                ╰──────╯
                                   ◦◦
                                  ◦◦◦◦
                                   ◦◦
```

Pure bash TUI library for delightful shell scripts. Zero dependencies.

## Install

### Bash

```bash
# From latest release
curl -fsSL https://github.com/KnickKnackLabs/chicle/releases/latest/download/chicle.sh -o chicle.sh
source chicle.sh
```

### PowerShell

```powershell
# From latest release
Invoke-WebRequest https://github.com/KnickKnackLabs/chicle/releases/latest/download/chicle.psm1 -OutFile chicle.psm1
Import-Module ./chicle.psm1
```

Or just copy `chicle.sh` / `chicle.psm1` into your project.

## Usage

### Style

```bash
chicle_style --bold "Important!"
chicle_style --cyan "Info"
chicle_style --bold --green "Success"
```

### Input

```bash
name=$(chicle_input --placeholder "Enter your name")
echo "Hello, $name"
```

### Confirm

```bash
if chicle_confirm "Continue?"; then
  echo "Continuing..."
fi

# With default yes
if chicle_confirm --default yes "Are you sure?"; then
  echo "Confirmed"
fi
```

### Choose

```bash
color=$(chicle_choose --header "Pick a color" "Red" "Green" "Blue")
echo "You chose: $color"
```

Arrow keys to navigate, Enter to select, q to quit.

### Spin

```bash
chicle_spin --title "Installing dependencies" -- npm install
chicle_spin --title "Building project" -- make build
```

### Rule

```bash
chicle_rule
chicle_rule --char "="
```

## Example

```bash
#!/usr/bin/env bash
source chicle.sh

chicle_style --bold "Welcome to the installer"
chicle_rule

name=$(chicle_input --placeholder "Project name")
template=$(chicle_choose --header "Select template" "basic" "advanced" "minimal")

if chicle_confirm "Create project '$name' with $template template?"; then
  chicle_spin --title "Creating project" -- sleep 2
  chicle_style --green "Done!"
fi
```

## License

MIT
