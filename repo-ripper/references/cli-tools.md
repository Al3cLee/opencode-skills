# CLI Tools Reference

Use these tools for repository-scale search and path transformation.

## ripgrep (`rg`)

GitHub: https://github.com/BurntSushi/ripgrep

Use `rg` for fast recursive regex and literal search while respecting ignore files.

Installation:

```bash
# macOS Homebrew
brew install ripgrep

# Linux (Debian/Ubuntu)
apt-get install ripgrep

# Fedora
dnf install ripgrep

# Arch Linux
pacman -S ripgrep

# From binaries
# https://github.com/BurntSushi/ripgrep/releases

# From source (requires Rust)
cargo install ripgrep
```

## fd

GitHub: https://github.com/sharkdp/fd

Use `fd` for fast file discovery with simple defaults.

Installation:

```bash
# macOS Homebrew
brew install fd

# Ubuntu/Debian
apt install fd-find  # binary may be named fdfind

# Fedora
dnf install fd-find

# Arch Linux
pacman -S fd

# From binaries
# https://github.com/sharkdp/fd/releases

# From source (requires Rust)
cargo install fd-find
```

## sd

GitHub: https://github.com/chmln/sd

Use `sd` for readable regex find/replace in command pipelines.

Installation:

```bash
# From source (requires Rust)
cargo install sd

# From binaries
# https://github.com/chmln/sd/releases
```

Why `sd` over `sed` for simple replacement pipelines:

```bash
# Replace all occurrences
sd before after file.txt

# Comparable sed form
sed -i -e 's/before/after/g' file.txt
```
