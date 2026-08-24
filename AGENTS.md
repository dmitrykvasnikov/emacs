# Repository Guidelines

## Project Structure & Module Organization

`early-init.el` contains pre-startup settings. `init.el` adds load paths and loads modules in dependency order. Most code lives in `src/`, with one feature per `dk-*.el` file; shared values and helpers belong in `dk-vars.el` and `dk-functions.el`. Bundled themes live in `themes/`. `install.md` documents runtime and tooling requirements. `notes/` contains maintenance notes.

Keep generated packages, grammars, native-comp output, backups, autosaves, and `custom.el` out of source control; these paths are covered by `.gitignore`.

## Build, Test, and Development Commands

This repository has no Makefile or separate build step. Use Emacs 30.1 or newer.

```bash
emacs --batch --init-directory="$PWD" --load early-init.el \
  --eval '(package-activate-all)' --load init.el \
  --eval '(message "startup OK")'
```

This is the primary smoke test: it loads `early-init.el`, `init.el`, and every configured module, failing on load errors. A first run may install packages.

```bash
emacs --batch --init-directory="$PWD" \
  --load src/dk-packages.el --eval '(dk/install-packages t)'
```

Use this to provision all declared packages. Inside Emacs, run `M-x dk/recompile-config` to byte-compile `src/`, and `M-x dk/treesit-install-all` to build pinned grammars. The latter requires network access and a compiler toolchain.

## Coding Style & Naming Conventions

Follow standard Emacs Lisp indentation and enable lexical binding. Prefix repository functions, variables, and commands with `dk/`; name modules `dk-<area>.el` and end them with matching `provide` forms. Put all non-package-specific function definitions in `src/dk-functions.el`, all configuration variable definitions in `src/dk-vars.el`, and all non-package-specific keybindings in `src/dk-keymap.el`. Keep package-specific bindings in the relevant module's `use-package` declaration. Prefer named hook helpers so modules can be reloaded without accumulating callbacks. Document public definitions and non-obvious ordering constraints.

## Testing Guidelines

There is currently no ERT suite or coverage target. For every change, run the batch startup smoke test and inspect warnings. Test affected commands interactively; UI, keymap, completion, theme, and language-mode changes require a GUI or terminal session matching their target. When adding testable logic, place ERT tests under a new `test/` directory and name files `<module>-test.el`.

## Commit & Pull Request Guidelines

Recent commits use short, imperative subjects such as `Fix package bootstrap on clean install` and `Restore default quit behavior`. Keep commits focused and explain behavior changes in the body when the reason is not obvious. Pull requests should summarize the user-visible effect, list verification performed, and call out new packages or external tools. Include screenshots only for visual theme or UI changes, and update `install.md` when dependencies change.
