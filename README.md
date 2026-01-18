# Chicle

```
   _____ _     _      _
  / ____| |   (_)    | |
 | |    | |__  _  ___| | ___
 | |    | '_ \| |/ __| |/ _ \
 | |____| | | | | (__| |  __/
  \_____|_| |_|_|\___|_|\___|
```

Pure bash TUI library for delightful shell scripts. Zero dependencies.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/KnickKnackLabs/chicle/main/chicle.sh -o chicle.sh
source chicle.sh
```

Or just copy `chicle.sh` into your project.

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
