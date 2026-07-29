# Emacs configuration review — conversation log

**Date:** 2026-07-29
**Emacs:** GNU Emacs 30.2
**Branch:** `test` → review, `test_fix` → fixes applied
**Participants:** Dmitry Kvasnikov, Claude (Claude Code)

---

## Message 1 — User

> read init.el and files from src/. convention that variables, global keybindings,
> functions goes to their files in src folder. what recommendations you can give me
> about my configuration? main goal is coding with programming languages (you can
> define them from config), for which of them i need lsp, error / syntax highlight,
> compilation, code navigation

---

## Message 2 — Claude: configuration review

I read `init.el`, `early-init.el`, all four `src/` files, and verified the findings by
actually loading the config in batch and opening real files.

### A. Real bugs (verified, not speculation)

#### 1. Typo silently disables all tree-sitter grammar installation

`init.el:314`

```elisp
(treesit-language-soource-alist dk/treesit-languages)   ; ← "soource"
```

Verified: after loading the config, `treesit-language-source-alist` is **`nil`**. The
carefully-built `dk/treesit-languages` in `vars.el:16` never reaches treesit.
Consequence: `dk/treesit-install-missing` (`functions.el:98`) loops over an empty list
and prints nothing — it looks like it succeeded.

#### 2. Go is broken right now — no highlighting, no indentation, no navigation

Direct consequence of #1. Grammar directory:

```
bash cmake cpp c json python rust toml yaml   ← present
go gomod                                       ← MISSING
```

Opening a real `.go` file with this config:

```
major-mode = go-ts-mode
treesit-ready go: nil
Warning (treesit): Cannot activate tree-sitter, because language grammar for go is unavailable
```

`major-mode-remap-alist` (`init.el:326`) forces `go-mode → go-ts-mode` unconditionally,
so `.go` files land in a **parser-less `go-ts-mode`**: no font-lock, no indent, no imenu,
no structural motion. Ironically the `go-mode` package installed at `init.el:518` *would*
work fine — the remap is what breaks it.

**Fix:** guard the remap on grammar availability so a missing grammar degrades to the
classic mode instead of a dead one. Also register `go.mod`:

```elisp
(add-to-list 'auto-mode-alist '("/go\\.mod\\'" . go-mod-ts-mode))
```

#### 3. `corfu-history` is saved but never populated

`init.el:75` puts `corfu-history` in `savehist-additional-variables`, but
`corfu-history-mode` is never enabled (`init.el:450-452` enables `global-corfu-mode` and
`corfu-popupinfo-mode` only). Verified `corfu-history-mode = nil`. Zero frequency-based
candidate sorting.

#### 4. Elisp error checking is off (Emacs 30 `trusted-content`)

Daemon log: `Disabling elisp-flymake-byte-compile in *scratch* (untrusted content)`.
Emacs 30 gates the byte-compile flymake backend behind `trusted-content`, which is `nil`.
With 14 `.el` files, the config is being edited with no error checking.

### B. Per-language matrix

Languages detected from config + `~/code` (51 `.hs`, 14 `.el`, 9 `.go`, 1 `.cpp`, 1 `.py`):

| Language | LSP | Syntax (TS) | Errors | Format | Compile | Navigation |
|---|---|---|---|---|---|---|
| **Haskell** *(primary)* | ✅ HLS | ⚠️ font-lock only | ✅ eglot | ✅ fourmolu | ⚠️ repl only | ✅ |
| **Go** | ✅ gopls | ❌ **broken** | ✅ gopls | ⚠️ gofmt | ✅ | ❌ blocked |
| **Rust** | ✅ ra+clippy | ✅ | ✅ | ✅ rustfmt | ✅ | ✅ |
| **C / C++** | ✅ clangd+tidy | ✅ | ✅ | ✅ gated | ✅ | ✅ |
| **Python** | ⚠️ pylsp | ✅ | ✅ | ✅ black | n/a | ✅ |
| **Emacs Lisp** | n/a | n/a | ❌ see #4 | ✅ | n/a | ✅ |
| **Bash** | not needed | ✅ | ✅ shellcheck | ❌ no shfmt | n/a | ✅ |
| **YAML/JSON/TOML/CMake** | ❌ none | ✅ | ❌ | ❌ | n/a | — |

**Haskell** — weakest area relative to usage. LSP/format/errors are solid (confirmed
`fourmolu` is in `apheleia-mode-alist` for `haskell-mode`, binary on `PATH` via
`~/.ghcup/bin`, which *is* in `exec-path`). Missing:
- **No `cabal build` compilation.** Only `cabal-repl` via `haskell-interactive`.
  `haskell-mode` ships `haskell-compile` with proper GHC error regexes — unbound.
- Optional: `haskell-ts-mode` (nongnu ELPA) + the `haskell` grammar.
- `electric-pair-mode` is global — fights primed names (`foo'`).

**Go** — everything configured correctly, blocked only by the missing grammar. After
fixing: `goimports`/`gofumpt` are **not installed** (only plain `gofmt`, so imports aren't
auto-managed), and gopls' `staticcheck` is off by default.

**Rust** — complete, nothing to do. `rustic` and `rust-mode` are installed as orphans.

**C/C++** — complete. The `dk/apheleia-inhibit-unconfigured-c` gate is a nice touch.
clangd only gets real diagnostics with `compile_commands.json`.

**Python** — `pylsp` installed but weak. `basedpyright` + `ruff` would be a step up.
At one `.py` file, not worth it.

**YAML/JSON/TOML** — no LSP, probably not needed.

### C. Gaps for a coding-focused config

Ordered by value:

1. **No `compile` / `recompile` binding.** Verified: `compile` unbound; only
   `project-compile` on `C-x p c`. The 90% case is *re*-compiling.
2. **`consult-eglot`** — workspace-wide symbol search. Biggest navigation win available
   for a 51-file Haskell project.
3. **`dape`** — zero debugging currently. Needs `dlv` for Go (not installed),
   `codelldb` for Rust/C++.
4. **`eglot-booster`** — 2–5× LSP throughput. Most noticeable on HLS.
5. **`breadcrumb`** — header-line context from imenu or LSP.
6. **Code folding** — nothing configured. `treesit-fold` / `outline-minor-mode`.
7. **`avy`** — complements `consult-line`, doesn't duplicate it.
8. **A terminal** (`eat` or `vterm`) for interactive sessions.

Minor: `hl-todo`, `eldoc-box`, `envrc`.

### D. Housekeeping & convention

**Convention violations:**
- `init.el:36` — `(setq auto-save-dir dk/auto-save-dir)` invents an undeclared global.
  A variable defined in `init.el`, which the convention forbids.
- `init.el:509-512` — inline `lambda` disabling `haskell-doc-mode`, while
  `dk/haskell-setup` in `functions.el:89` does the identical thing and is dead (hook
  commented out at `init.el:500`).
- `functions.el:56` — `dk/clang-fos` is dead code for the commented-out `clang-format`
  package; apheleia superseded it.

**Package hygiene:** `custom.el` has `(package-selected-packages nil)` — `package-autoremove`
would offer to delete *everything*, and the package set can't be rebuilt on a new machine.

Confirmed orphans in `elpa/` from commented-out blocks — 13 packages:

```
projectile  consult-projectile  rustic  rust-mode  clang-format
all-the-icons  all-the-icons-dired  corfu-terminal  popon
kind-icon  xterm-color  alabaster-themes  modus-themes
```

`rust-mode` and `rustic` still autoload `.rs` into `auto-mode-alist` — harmless today
because `rust-ts-mode`'s `:mode` wins, but latent conflict.

**Two things checked that are fine** (so they aren't chased): the unusual `:bind`
indentation in the `consult` block works — all 9 bindings verified to resolve correctly;
and `recentf`/`display-line-numbers`/`which-key` under `use-package-always-ensure t`
don't attempt downloads, because Emacs 30 registers them as built-in packages.

**Non-bug, worth a decision:** `C-s` → `consult-line` means isearch is given up entirely,
making `isearch-allow-scroll`, `isearch-lazy-count`, `isearch-wrap-pause` and
`isearch-repeat-on-direction-change` (`init.el:57-60`) dead settings.

Startup is 0.59s with 60 packages — no performance problem to solve.

---

## Message 3 — User

> give me proposition how to fix on each point you have mentioned

---

## Message 4 — Claude: fix propositions

All propositions verified against the actual setup — package availability checked in the
configured archives, function signatures checked in Emacs 30.2, and the `setq`-before-load
idiom confirmed to survive `defcustom`.

### A. Bug fixes

#### A1 + A2 — tree-sitter typo and broken Go

One fix. Data in `vars.el`, logic in `functions.el`, wiring in `init.el`.

**`src/vars.el`** — add the two missing grammars, plus a remap table with the language
each mode needs:

```elisp
(defvar dk/treesit-languages
  '((bash    "https://github.com/tree-sitter/tree-sitter-bash")
    (c       "https://github.com/tree-sitter/tree-sitter-c")
    (cpp     "https://github.com/tree-sitter/tree-sitter-cpp")
    (cmake   "https://github.com/uyha/tree-sitter-cmake")
    (go      "https://github.com/tree-sitter/tree-sitter-go")
    (gomod   "https://github.com/camdencheek/tree-sitter-go-mod")
    (haskell "https://github.com/tree-sitter/tree-sitter-haskell")
    (json    "https://github.com/tree-sitter/tree-sitter-json")
    (python  "https://github.com/tree-sitter/tree-sitter-python")
    (rust    "https://github.com/tree-sitter/tree-sitter-rust")
    (toml    "https://github.com/tree-sitter/tree-sitter-toml")
    (yaml    "https://github.com/ikatyang/tree-sitter-yaml"))
  "Grammars installed by `dk/treesit-install-missing'.")

(defvar dk/treesit-remaps
  '((c-mode         c-ts-mode         c)
    (c++-mode       c++-ts-mode       cpp)
    (c-or-c++-mode  c-or-c++-ts-mode  c)
    (python-mode    python-ts-mode    python)
    (sh-mode        bash-ts-mode      bash)
    (js-json-mode   json-ts-mode      json)
    (conf-toml-mode toml-ts-mode      toml)
    (rust-mode      rust-ts-mode      rust)
    (go-mode        go-ts-mode        go))
  "(CLASSIC-MODE TS-MODE LANGUAGE) triples.")
```

**`src/functions.el`**:

```elisp
(defun dk/treesit-apply-remaps ()
  "Remap classic major modes to tree-sitter ones where the grammar exists."
  (pcase-dolist (`(,classic ,ts ,lang) dk/treesit-remaps)
    (when (treesit-language-available-p lang)
      (add-to-list 'major-mode-remap-alist (cons classic ts)))))

(defun dk/treesit-install-missing ()
  "Compile and install any tree-sitter grammar that is missing."
  (interactive)
  (dolist (lang (mapcar #'car dk/treesit-languages))
    (if (treesit-language-available-p lang)
        (message "tree-sitter grammar present: %s" lang)
      (message "Installing tree-sitter grammar: %s" lang)
      (treesit-install-language-grammar lang))))
```

It now iterates `dk/treesit-languages` directly, so it can't silently no-op again.

**`init.el`**:

```elisp
;; Plain setq, not use-package :custom: this must land before treesit loads.
;; `defcustom' only sets a default when the symbol is unbound, so this survives.
(setq treesit-language-source-alist dk/treesit-languages)
(setq treesit-font-lock-level 4)

(dk/treesit-apply-remaps)

(add-to-list 'auto-mode-alist '("\\(?:CMakeLists\\.txt\\|\\.cmake\\)\\'" . cmake-ts-mode))
(add-to-list 'auto-mode-alist '("\\.ya?ml\\'" . yaml-ts-mode))
(add-to-list 'auto-mode-alist '("/go\\.mod\\'" . go-mod-ts-mode))
```

`treesit-language-available-p` is a C primitive — no `require 'treesit` needed, so this
costs nothing at startup. The `use-package treesit` block goes away.

Then run once: `M-x dk/treesit-install-missing`, restart Emacs.

#### A3 — corfu history

```elisp
  :init
  (global-corfu-mode 1)
  (corfu-popupinfo-mode 1)
  (corfu-history-mode 1))          ; ← makes savehist's corfu-history entry real
```

#### A4 — elisp flymake / `trusted-content`

**`src/vars.el`**:

```elisp
(defvar dk/trusted-dirs
  (list (expand-file-name user-emacs-directory)
        (expand-file-name "~/code/"))
  "Directories whose Elisp is trusted (enables `elisp-flymake-byte-compile').")
```

**`init.el`**: `(setq trusted-content dk/trusted-dirs)`. Trailing slashes matter.

### B. Per-language fixes

#### B1 — Haskell: add real compilation

`haskell-compile` is present in the installed `haskell-mode`,
`haskell-compile-cabal-build-command` is already `cabal build --ghc-option=-ferror-spans`,
and `C-c C-c` is **unbound** in `haskell-mode-map` (verified).

```elisp
  :bind
  (:map haskell-mode-map
        ("C-c C-l" . haskell-process-load-file)
        ("C-c C-z" . haskell-interactive-switch)
        ("C-c C-t" . haskell-mode-show-type-at)
        ("C-c C-c" . haskell-compile)          ; ← whole-project build + next-error
        ("C-c C-k" . haskell-interactive-mode-clear))
```

#### B2 — Haskell: electric-pair vs primed names

```elisp
(defun dk/haskell-setup ()
  "Haskell buffer tweaks: no `haskell-doc-mode' (Eldoc/Eglot own that),
and never auto-pair the apostrophe used in primed names like `foo''."
  (haskell-doc-mode -1)
  (setq-local electric-pair-inhibit-predicate
              (lambda (c) (or (char-equal c ?\')
                              (electric-pair-default-inhibit c)))))
```

#### B3 — Haskell: optional tree-sitter mode

`haskell-ts-mode` is on nongnu ELPA. Only worth it after the `haskell` grammar is
installed. Recommendation was to hold off — `haskell-mode`'s indentation is more mature.

#### B4 — Go: gopls settings + import management

```elisp
  (setq-default eglot-workspace-configuration
                '(:haskell (:formattingProvider "fourmolu")
                  :gopls   (:staticcheck t
                            :usePlaceholders t
                            :analyses (:unusedparams t :nilness t :shadow t))))
```

For imports: `go install golang.org/x/tools/cmd/goimports@latest`, then point apheleia at it.

#### B5 — Go: drop the redundant `go-mode` package

```elisp
(use-package go-ts-mode
  :ensure nil
  :mode ("\\.go\\'" . go-ts-mode)
  :hook (go-ts-mode . eglot-ensure)
  :custom (go-ts-mode-indent-offset 4))
```

#### B6 — C/C++: nothing to change

Only per-project action: generate `compile_commands.json`.

#### B7 — Python: only if more Python gets written

`basedpyright` + `ruff`. At one `.py` file, skip.

#### B8 — Bash: `pacman -S shfmt`, apheleia picks it up automatically. No config needed.

#### B9 — YAML/JSON/TOML: skip unless CI configs appear.

### C. Missing capabilities

#### C1 — compile bindings

**`src/keymap.el`**:

```elisp
(global-set-key (kbd "C-c c") #'recompile)
(global-set-key (kbd "C-c C") #'project-compile)
```

**`init.el`**:

```elisp
(setq compilation-ask-about-save nil)      ; default is t — saves without prompting
(setq compilation-max-output-line-length nil)
(setq next-error-message-highlight t)
```

#### C2 — `consult-eglot` (highest-value addition)

```elisp
(use-package consult-eglot
  :after (consult eglot)
  :bind (:map eglot-mode-map
              ("M-g s" . consult-eglot-symbols)))
```

#### C3 — `dape` (debugging)

```elisp
(use-package dape
  :custom
  (dape-buffer-window-arrangement 'right)
  (dape-inlay-hints t)
  :config
  (dape-breakpoint-global-mode 1)
  (add-hook 'dape-compile-hook #'kill-buffer))
```

Adapters: `dlv` for Go, `codelldb` for Rust/C++. Haskell DAP is immature.

#### C4 — `eglot-booster`

**Not in any configured archive** — `(package-vc-install "https://github.com/jdtsmith/eglot-booster")`,
plus the `emacs-lsp-booster` binary (AUR).

#### C5 — `breadcrumb`

```elisp
(use-package breadcrumb
  :hook (prog-mode . breadcrumb-local-mode))
```

#### C6 — code folding

```elisp
(use-package treesit-fold
  :hook (prog-mode . treesit-fold-mode)
  :bind (("C-c f" . treesit-fold-toggle)
         ("C-c F" . treesit-fold-close-all)))
```

#### C7 — `avy`

```elisp
(use-package avy
  :bind (("M-j"   . avy-goto-char-timer)
         ("M-g w" . avy-goto-word-1)))
```

#### C8 — terminal

```elisp
(use-package eat
  :bind ("C-c s" . eat-project)
  :custom (eat-kill-buffer-on-exit t))
```

Lower priority: `hl-todo`, `eldoc-box`, `envrc`.

### D. Housekeeping

#### D1 — `auto-save-dir`

```elisp
(make-directory dk/auto-save-dir t)
(setq auto-save-file-name-transforms `((".*" ,dk/auto-save-dir t)))
```

#### D2 — duplicated haskell-doc disabling

Delete the inline lambda, uncomment the hook:

```elisp
  :hook ((haskell-mode . haskell-indentation-mode)
         (haskell-mode . dk/haskell-setup))
```

#### D3 — dead code and orphan packages

Delete `dk/clang-fos`. Delete the commented-out `use-package` blocks. Uninstall the 13
orphans explicitly (since `package-selected-packages` is `nil`, `package-autoremove` is
unsafe).

#### D4 — `package-selected-packages`

Declare the set in `src/vars.el` as `dk/packages`, then
`(setq package-selected-packages dk/packages)` in `init.el`. Makes
`package-autoremove` safe and a fresh machine one command away.

#### D5 — isearch vs `consult-line`

Either delete the four dead isearch settings, or move consult to `M-s l` and restore
`C-s`. Recommendation was the latter, but it's muscle memory — user's call.

### Suggested order

1. **A1+A2** — unbreaks Go. Nothing else depends on it.
2. **A3, A4, D1, D2, D3** — small, independent, no new packages.
3. **B1, B4, C1** — compilation across the three main languages.
4. **C2, C5** — navigation.
5. **D4** — once the package set has settled.
6. **C3, C6, C7, C8, B3** — as wanted.

---

## Message 5 — User

> switch to test_fix branch. save all conversation to notes.md. apply steps 1-3 and then
> ask me through the rest of steps (give me options to choose for each step)

---

## Message 6 — Claude: steps 1–3 applied

Branch `test_fix` created off `test`. This log written to `notes.md`.

Applied: **A1+A2, A3, A4, D1, D2, D3 (code only), B1, B4, C1**.
Held for confirmation: the `package-delete` half of D3 (destructive, `elpa/` is gitignored).
Remaining steps 4–6 presented as choices.

### A5 — NEW BUG found while verifying (missed in the original review)

`src/keymap.el` **had never loaded — not once.** Emacs preloads its own
`lisp/keymap.el` (the `keymap-set` / `keymap-global-set` API), so `keymap` is already
in `features` before `init.el` runs:

```
keymap  preloaded=t  builtin-file="/usr/share/emacs/30.2/lisp/keymap.elc"
```

`(require 'keymap)` at `init.el:13` therefore returned immediately without loading
anything. Every global binding in that file was dead. Verified before the fix:

```
M-o       => nil            (expected other-window)
<escape>  => nil            (expected dk/escape-dwim)
C-x C-b   => list-buffers   (expected ibuffer)
M-x       => execute-extended-command  (expected dk/M-x-dwim)
```

Checked the other three: `vars`, `functions` and `bootstrap` do **not** collide — this
was specific to `keymap`.

**Fix:** `git mv src/keymap.el src/keys.el`, `(provide 'keys)`, `(require 'keys)`.
Renaming the *file* is required, not just the feature symbol — `require` consults
`features` before it ever touches `load-path`, so shadowing via load-path order cannot
help. A warning comment now sits at the top of `src/keys.el`.

After the fix all 17 bindings resolve, including `C-c c` → `recompile` and
`C-c C` → `project-compile` added in C1.

### Verification results

```
grammars:     go=t gomod=t haskell=t rust=t c=t     (3 newly compiled)
t.go:         mode=go-ts-mode  parser=t  imenu=("Function")
go.mod:       mode=go-mod-ts-mode  parser=t
remaps:       9 entries, all grammar-guarded
trusted-content: ("~/.config/emacs/" "~/code/")
corfu-history-mode: t
gopls cfg:    (:staticcheck t :usePlaceholders t :analyses (...))
startup:      0.58s
```

Pre-existing minor warning left alone: `functions.el:16` binds `bg` in
`dk/sync-orderless` but never uses it (the function sets `:background 'unspecified`).

---

## Message 7 — User

> is this step mosly about debugging?  /  skip dape, ask me the rest one at a time
> /  explain me difference between consult-line and isearch
> /  let's leave as is with consult-line, apply everything we agreed on

---

## Message 8 — Claude: steps 4–6 applied

### Decisions

| Step | Chosen | Declined |
|---|---|---|
| 4 — navigation | consult-eglot, breadcrumb, treesit-fold | avy |
| 6 — tooling | haskell-ts-mode | dape, eat, eglot-booster |
| 5 — packages | both: declare `dk/packages` + delete orphans | — |
| D5 — search | keep `C-s` as `consult-line` | — |

### Two corrections to the original review

**1. `modus-themes` is NOT an orphan.** It is a hard dependency of `ef-themes`, which is
in active use. Listing it for deletion was wrong — removing it would have broken
`ef-themes`. Emacs' own `package--removable-packages` caught this. The authoritative set
was 14, not 13: it drops `modus-themes` and adds `svg-lib` (← kind-icon) and `spinner`
(← rustic), which become orphans once their parents go.

**2. The four isearch settings at `init.el:57-60` were not dead**, only partly idle.
They apply to every isearch session, and `C-M-s`, `C-M-r`, `M-s .`, `M-s w`, `M-s _` all
still reach isearch. They were kept, not deleted.

### A6 — `C-r` was globally bound to a command that cannot work there

`consult-history` only functions in the minibuffer and in comint buffers — both of which
were already bound correctly at `init.el:284-285`. The *global* binding at `init.el:274`
just errored in ordinary buffers, and cost `isearch-backward`. Removed; `C-r` is
`isearch-backward` again.

### A7 — `custom.el` was silently overwriting `package-selected-packages`

`custom.el` loads at the end of `init.el` and contained `'(package-selected-packages nil)`.
Setting the variable from `dk/packages` earlier in `init.el` had no effect — verified:
`(equal package-selected-packages dk/packages)` was `nil` until the stale entry was
removed from `custom.el`. This is why the original `nil` value was so dangerous: it was
authoritative, not vestigial.

### Haskell restructure

`haskell-ts-mode` now owns `.hs`. `haskell-mode` is kept but deferred, because it supplies
`haskell-compile` and the interactive cabal-repl session that the ts-mode has no
equivalent for. The `C-c C-c` / `C-c C-l` / `C-c C-z` bindings moved to
`haskell-ts-mode-map`, and `dk/haskell-setup` is now guarded with `bound-and-true-p` so it
no-ops in ts-mode buffers instead of autoloading haskell-doc for nothing.
`apheleia-mode-alist` gained a `haskell-ts-mode → fourmolu` entry (apheleia ships one for
`haskell-mode` only).

### Final verification

```
T.hs:      mode=haskell-ts-mode parser=t
           C-c C-c=haskell-compile  C-c C-l=haskell-process-load-file
           apheleia=fourmolu  treesit-fold=t  breadcrumb=t
t.go:      mode=go-ts-mode parser=t fold=t
keys:      C-c f=treesit-fold-toggle  C-c F=treesit-fold-close-all
           C-c c=recompile  C-c C=project-compile
           C-r=isearch-backward  C-s=consult-line
packages:  selected=36  removable=nil  installed=49  ef-themes intact
elpa:      30M -> 24M
startup:   0.59s -> 0.51s
```

### Not done (never agreed, listed for later)

B2 (electric-pair vs Haskell primed names), B5 (drop the `go-mode` package),
B7 (basedpyright/ruff), B8 (`shfmt`), C4 (eglot-booster), goimports for Go import
management, dape, eat, avy.
