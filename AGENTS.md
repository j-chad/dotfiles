# AGENTS.md

## Repository Overview

This is a **chezmoi dotfiles repository**, not a software project. It manages personal
machine configuration (shell, git, editor, macOS defaults) using [chezmoi](https://www.chezmoi.io/).

**Target machines:**
- **macOS laptop** (darwin) -- primary development machine
- **Ubuntu desktop** (linux) -- secondary machine

There is no build system, test suite, linter, or CI/CD pipeline.

---

## Commands

There are no build, lint, or test commands. All operations use `chezmoi`:

```sh
chezmoi diff              # Preview what chezmoi would change on the home directory
chezmoi apply             # Apply changes to the home directory
chezmoi apply -n          # Dry-run apply (show what would happen without writing)
chezmoi add ~/.example    # Add a new file to chezmoi management
chezmoi edit ~/.example   # Edit a managed file in the source directory
chezmoi data              # Show template data (useful for debugging)
chezmoi execute-template  # Test template rendering from stdin
chezmoi doctor            # Diagnose chezmoi setup issues
```

**Verifying changes:** There are no tests. Always use `chezmoi diff` to preview changes
before applying. Use `chezmoi execute-template` to test template logic interactively:

```sh
echo '{{ if eq .chezmoi.os "darwin" }}mac{{ else }}linux{{ end }}' | chezmoi execute-template
```

---

## File Naming Conventions

Chezmoi uses filename prefixes to control how source files map to targets:

| Prefix/Suffix | Meaning | Example |
|---|---|---|
| `dot_` | Replaced with `.` in target | `dot_zshrc` -> `~/.zshrc` |
| `.tmpl` | File is a Go template, rendered before writing | `dot_gitconfig.tmpl` -> `~/.gitconfig` |
| `run_once_` | Script that runs once (tracked by checksum) | `run_once_macos_setup.sh.tmpl` |
| `run_onchange_` | Script that re-runs when its content changes | |
| `private_` | Target file permissions set to `0600` | |
| `exact_` | Directory contents are managed exactly (extra files removed) | |
| `dot_config/` | Maps to `~/.config/` | `dot_config/git/` -> `~/.config/git/` |

Prefixes stack: `private_dot_ssh` -> `~/.ssh` with `0700` permissions.

---

## Code Style

### EditorConfig (applies to all files)

- **Charset:** UTF-8
- **Indentation:** Tabs (not spaces)
- **Line endings:** LF (Unix-style)
- **Final newline:** Always insert
- **Trailing whitespace:** Always trim

### General

- Match the indentation style of surrounding code in existing files.
  Some gitconfig files have mixed tabs/4-space indentation -- match the
  immediate context when editing.
- Keep files short and well-commented. Group related settings with
  section comments (e.g., `# ---- Section Name ----`).

---

## Go Template Guidelines

Templates use Go's `text/template` syntax. Follow these conventions:

### Whitespace Control

Use `{{-` and `-}}` to trim adjacent whitespace. This is especially important
at the top of files where template variables are declared:

```
{{- $isWork := promptBoolOnce . "data.is_work" "Are you configuring this for work?" false -}}
```

### Available Template Data

Defined in `.chezmoi.toml.tmpl`:
- `.chezmoi.os` -- `"darwin"` (macOS) or `"linux"` (Ubuntu)
- `.chezmoi.arch` -- machine architecture
- `.is_work` -- boolean, whether this is a work machine
- `.git_name` -- git user.name
- `.git_email` -- personal git email
- `.git_email_work` -- work git email

### OS-Specific Logic

Use `.chezmoi.os` to branch for the two target machines:

```
{{ if eq .chezmoi.os "darwin" -}}
# macOS-specific config
{{- else if eq .chezmoi.os "linux" -}}
# Ubuntu-specific config
{{- end }}
```

For scripts that should only run on one OS, wrap the entire file content
(including the shebang) inside an OS conditional.

### Variable Declarations

Declare template variables at the **top** of the file, before any output.
Use whitespace-trimming dashes to avoid blank lines in rendered output.

### Prompt Functions

Use `promptStringOnce` and `promptBoolOnce` for interactive data collection.
These are only used in `.chezmoi.toml.tmpl` -- config files should reference
the resulting data variables (e.g., `.git_name`), not prompt directly.

---

## Shell Script Conventions

- Use `#!/bin/sh` (POSIX shell), not `#!/bin/bash`, for portability across macOS and Ubuntu.
- Echo progress messages so the user knows what is happening:
  `echo "Running macOS setup script..."`
- Request `sudo -v` upfront when admin privileges are needed.
- Comment each logical group of commands with a short description.
- Guard OS-specific scripts with a chezmoi template conditional wrapping
  the entire file (shebang included).

---

## Git Configuration Style

- **Identity switching:** Uses `includeIf` with `gitdir:` to select
  work vs personal identity based on the repository's directory path.
- **Aliases:** Use short names (`s`, `d`, `p`, `c`, `lg`). Add a comment
  above each alias explaining what it does.
- **Complex aliases:** Use quoted shell functions:
  `go = "!f() { git switch \"$1\" 2>/dev/null || git switch -c \"$1\"; }; f"`
- **Simple aliases:** Use direct git commands: `p = push`

---

## Chezmoi Documentation Reference

When unsure about chezmoi behavior, **always consult the official docs** rather
than guessing. Chezmoi has many special behaviors around file naming, template
functions, and state management that are easy to get wrong.

- **Primary docs:** https://www.chezmoi.io/
- **Command reference:** https://www.chezmoi.io/reference/commands/
- **Template functions:** https://www.chezmoi.io/reference/templates/functions/
- **Template variables:** https://www.chezmoi.io/reference/templates/variables/
- **Managing different OSes:** https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/
- **Special files and dirs:** https://www.chezmoi.io/reference/special-files-and-directories/
- **Source file attributes:** https://www.chezmoi.io/reference/source-state-attributes/

Use `chezmoi execute-template` to experiment with template syntax locally
before committing changes. Use `chezmoi diff` to verify rendered output
matches expectations on the current machine.
