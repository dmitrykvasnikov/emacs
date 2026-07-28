# Emacs config review — proposals

Reviewed: `early-init.el`, `init.el`, `src/functions.el`, `src/keymap.el`, `src/vars.el`, `custom.el`
Environment verified: **GNU Emacs 30.2**, Arch Linux, 60 packages in `elpa/`
Date: 2026-07-28

Nothing in the config was modified. Everything below is a proposal.

Findings marked **[verified]** were reproduced by actually running Emacs against the
config; the rest are judgement calls about community practice, take or leave them.

**Every observation in this document ends in a concrete "Fix:" or "Proposal:" block.**
Where a finding is a genuine judgement call, the proposal states a decision rule and a
default recommendation rather than pretending there's one right answer.

---

## 0. Overall verdict

This is a good, modern config. The completion stack (vertico / orderless / marginalia /
consult / embark / corfu / cape) is exactly what the community converged on, you're on
built-in `eglot` + `treesit` + `flymake` rather than the heavier `lsp-mode` stack, and the
comments explaining *why* (the vertico-directory `DEL` note, the `add-to-list` note in the
eglot block) are better than what most configs have.

The problems are not architectural. They are:

1. **Six concrete bugs / dead settings** that silently do nothing (§1).
2. **Four overlapping auto-format mechanisms** doing the same job (§3).
3. **Startup work that is paid for and thrown away** — roughly 40% of load time (§4).
4. **The `src/` convention is stated but not actually followed** (§2).

Priority order is in §12.

---

## 1. Confirmed bugs and dead code

### 1.1 `global-auto-revert-mode` is never enabled **[verified]**

`init.el:50`

```elisp
(setq global-auto-revert-mode 1)     ; ← sets the variable, does not enable the mode
```

Assigning a minor-mode variable with `setq` bypasses the mode function, so no hooks are
installed and buffers never revert. Every other mode nearby is called correctly
(`delete-selection-mode`, `savehist-mode`, …) — this one line is the odd one out.

**Fix:**

```elisp
(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers t)  ; also revert Dired / Ibuffer
(setq auto-revert-verbose nil)
```

### 1.2 Auto-save files land in the config root, not `autosave/` **[verified]**

`init.el:39`

`auto-save-dir` has no trailing slash, so it is concatenated directly onto the mangled
filename. Reproduced both branches:

```
without slash  ->  /home/dmitry/.config/emacs/#!home!dmitry!code!go!tradebot!docs!x.md#
with slash     ->  /home/dmitry/.config/emacs/autosave/#!home!dmitry!code!go!tradebot!docs!x.md#
```

This is not theoretical — `autosave/` is **empty**, and two stray files are sitting in the
config root right now:

```
#!home!dmitry!code!go!tradebot!docs!2026-07-25-01.md#
#!home!dmitry!Downloads!test.md#
```

They're caught by the `\#*` rule in `.gitignore`, which is why they never showed up in
`git status`.

**Fix** (the variable itself belongs in `src/vars.el` — see §2):

```elisp
(setq auto-save-dir (expand-file-name "autosave/" user-emacs-directory))
```

**Cleanup of the two strays** — check them first in case either holds unsaved work:

```bash
cd ~/.config/emacs
ls -la '#!'*'#'                 # inspect before removing
rm -- '#!home!dmitry!code!go!tradebot!docs!2026-07-25-01.md#' \
      '#!home!dmitry!Downloads!test.md#'
```

### 1.3 `eglot-put-doc-in-buffer` does not exist **[verified]**

`init.el:308`

```elisp
(setq eglot-put-doc-in-buffer t) ; Keeps the heavy markdown out of the tiny echo area
```

There is no such variable in Emacs 30.2's eglot (`apropos-internal "eglot.*doc"` returns
only internal symbols). The old name was `eglot-put-doc-in-help-buffer` and it was removed
when eglot moved to the `eldoc-display-functions` mechanism. This line does nothing.

**Fix** — delete that line, and use the modern equivalent, which does deliver what your
comment asks for:

```elisp
;; one line in the echo area, full docs in a dedicated buffer on demand
(setq eldoc-echo-area-use-multiline-p 1)
(setq eldoc-echo-area-prefer-doc-buffer t)
(setq eldoc-documentation-strategy #'eldoc-documentation-compose-eagerly)
```

Optionally add `eldoc-box` for a hover child-frame instead of the echo area (§9).

### 1.4 The custom flymake fringe bitmaps are defined but never used **[verified]**

`init.el:361-366` defines `flymake-error-indicator`, `flymake-warning-indicator`,
`flymake-note-indicator` — and then never assigns them. Verified that
`flymake-error-bitmap` is still at its default `(flymake-double-exclamation-mark
compilation-error)`, so you're looking at stock `!!` markers, not your thin bars.

**Fix** — add directly after the `define-fringe-bitmap` calls:

```elisp
(setq flymake-error-bitmap   '(flymake-error-indicator   compilation-error)
      flymake-warning-bitmap '(flymake-warning-indicator compilation-warning)
      flymake-note-bitmap    '(flymake-note-indicator    compilation-info))
```

### 1.5 `C-x C-p` is bound to a command that doesn't exist **[verified]**

`init.el:215`

```elisp
("C-x C-p" . consult-project-find)   ;; Find file in project (IF you use project.el)
```

`consult-project-find` is not in consult (grepped the installed source). Pressing the key
gives *"command not found"*. You already have the working equivalent at `C-c p f`.

**Fix** — repoint it, or delete the line if `C-c p f` is enough:

```elisp
("C-x C-p" . consult-projectile-find-file)
```

### 1.6 `C-r` globally shadows `isearch-backward` with a minibuffer-only command **[verified]**

`init.el:220`

```elisp
("C-r" . consult-history)            ;; Minibuffer history
```

Per its own docstring, `consult-history` inserts from *the current buffer's* history
(minibuffer / comint / eshell). In a normal file buffer there is no history and it errors
— so you've traded away backward incremental search for a command that can't run there.

**Fix** — remove `("C-r" . consult-history)` from the global `:bind` list and scope it:

```elisp
:bind (:map minibuffer-local-map ("C-r" . consult-history)
       :map comint-mode-map      ("C-r" . consult-history))
```

Global `C-r` then falls back to `isearch-backward`, which is what you want.

---

## 2. The `src/` convention isn't actually being followed

Your stated rule: *all custom functions, global keybindings and variables live in `src/`.*
In practice:

| Thing | Where it is | Where the rule says it goes | Fix below |
|---|---|---|---|
| `dk/add-to-confdir`, `dk/add-paths-to-list` | `early-init.el:7,12` | `src/functions.el` | §2.1 |
| `my-eglot-clean-haskell-markdown` | `init.el:311` | `src/functions.el` (a `dk/` copy already exists there!) | §2.2 |
| `auto-save-dir` | `init.el:39` | `src/vars.el` | §2.3 |
| anonymous `haskell-doc-mode` lambda | `init.el:457` | `src/functions.el` | §2.4 |
| anonymous theme-hook lambda | `init.el:570` | `src/functions.el` | §2.4 |
| anonymous kill-buffer lambda | `src/keymap.el:18` | should be a named fn (or a built-in) | §2.4 |
| `S-<return>` keyboard macro | `src/keymap.el:11` | should be a named fn | §2.4 |
| `src/vars.el` | — | **completely empty** | §2.3 |

### 2.1 `early-init.el` bootstrapping

`dk/add-to-confdir` / `dk/add-paths-to-list` genuinely must exist before `init.el:9`, which
is why they ended up in `early-init.el`. The way to keep the convention is a bootstrap
module.

**Fix** — create `src/bootstrap.el`:

```elisp
;;; src/bootstrap.el --- functions needed before init.el  -*- lexical-binding: t; -*-

(defun dk/add-to-confdir (relative-path)
  "Expand RELATIVE-PATH against `user-emacs-directory'."
  (expand-file-name relative-path user-emacs-directory))

(defun dk/add-paths-to-list (list-var paths &optional expand-p)
  "Add each of PATHS to LIST-VAR, expanding against the config dir when EXPAND-P."
  (let ((expander (if expand-p #'dk/add-to-confdir #'identity)))
    (dolist (path paths)
      (add-to-list list-var (funcall expander path)))))

(provide 'bootstrap)
;;; bootstrap.el ends here
```

and in `early-init.el`, replace the two `defun`s with:

```elisp
(load (expand-file-name "src/bootstrap.el" user-emacs-directory) nil t)
```

### 2.2 Duplicated haskell-markdown function

`dk/eglot-clean-haskell-markdown` in `src/functions.el:62` and
`my-eglot-clean-haskell-markdown` in `init.el:311` are the same code. The `init.el` one is
what's actually advised; the `src/` one is dead.

**Fix** — delete the entire `defun my-eglot-clean-haskell-markdown` from `init.el` and
advise the `dk/` one (folded into the merged eglot block from §3.4):

```elisp
(with-eval-after-load 'eglot
  (advice-add 'eglot--format-markup :filter-args #'dk/eglot-clean-haskell-markdown))
```

### 2.3 Populate `src/vars.el`

It's currently a stub with nothing but `(provide 'vars)`. Everything user-tunable that
`init.el` currently hard-codes belongs here, so there is one place to look.

**Fix** — a starting `src/vars.el`:

```elisp
;;; src/vars.el --- user variables  -*- lexical-binding: t; -*-

(defvar dk/font-family "Aporetic Sans Mono"
  "Default monospace family; ignored gracefully when not installed.")
(defvar dk/font-height 115
  "Default face height, in 1/10 pt.")
(defvar dk/minibuffer-font-height 100
  "Face height for the minibuffer prompt.")

(defvar dk/auto-save-dir (expand-file-name "autosave/" user-emacs-directory)
  "Directory for auto-save files.  Trailing slash is required.")

(defvar dk/prose-line-spacing 0.15
  "Extra line spacing in prose buffers (Markdown, Org).")

(defvar dk/treesit-languages
  '((bash   "https://github.com/tree-sitter/tree-sitter-bash")
    (c      "https://github.com/tree-sitter/tree-sitter-c")
    (cpp    "https://github.com/tree-sitter/tree-sitter-cpp")
    (cmake  "https://github.com/uyha/tree-sitter-cmake")
    (go     "https://github.com/tree-sitter/tree-sitter-go")
    (gomod  "https://github.com/camdencheek/tree-sitter-go-mod")
    (json   "https://github.com/tree-sitter/tree-sitter-json")
    (python "https://github.com/tree-sitter/tree-sitter-python")
    (rust   "https://github.com/tree-sitter/tree-sitter-rust")
    (toml   "https://github.com/tree-sitter/tree-sitter-toml")
    (yaml   "https://github.com/ikatyang/tree-sitter-yaml"))
  "Grammars installed by `dk/treesit-install-missing'.")

(provide 'vars)
;;; vars.el ends here
```

Note this requires loading `vars.el` **before** the code that reads those variables.
Currently `init.el:11-13` loads `functions.el`, `keymap.el`, `vars.el` in that order —
`vars.el` should come **first**, since functions and keymaps may reference the variables
but not vice versa.

**Fix** — reorder `init.el:11-13`:

```elisp
(load "vars.el" nil t)
(load "functions.el" nil t)
(load "keymap.el" nil t)
```

### 2.4 Named replacements for the four anonymous forms

**Fix** — add to `src/functions.el`:

```elisp
(defun dk/newline-below ()
  "Open a new line below point, regardless of column."
  (interactive)
  (end-of-line)
  (newline-and-indent))

(defun dk/theme-hook (theme)
  "Re-sync derived faces after THEME is enabled."
  (message "Theme enabled: %s" theme)
  (dk/sync-orderless))

(defun dk/haskell-setup ()
  "Stop `haskell-doc-mode' from fighting Eldoc/Eglot."
  (haskell-doc-mode -1))
```

Then at the call sites:

```elisp
;; src/keymap.el — replaces the (kbd "C-e C-m") keyboard macro
(global-set-key (kbd "S-<return>") #'dk/newline-below)

;; src/keymap.el — replaces the anonymous kill-buffer lambda; this is a built-in
(global-set-key (kbd "C-c k") #'kill-current-buffer)

;; init.el — replaces the anonymous theme lambda
(add-hook 'enable-theme-functions #'dk/theme-hook)

;; init.el — replaces the anonymous haskell lambda, and folds into the use-package block
(use-package haskell-mode
  :hook ((haskell-mode . haskell-indentation-mode)
         (haskell-mode . dk/haskell-setup))
  ...)
```

Why the keyboard macro is worth replacing: `(kbd "C-e C-m")` breaks under `repeat`, shows
nothing useful in `C-h k`, and bypasses electric-indent. Why the two lambdas are worth
replacing: an anonymous function added to a hook **cannot be removed** with `remove-hook`,
so re-evaluating `init.el` stacks up duplicate copies.

### 2.5 Two identical prose functions

`dk/markdown-prose` (`functions.el:75`) and `dk/org-prose` (`functions.el:81`) are
byte-identical.

**Fix** — collapse to one:

```elisp
(defun dk/prose-setup ()
  "Prose-friendly display for Markdown and Org buffers."
  (visual-line-mode 1)
  (setq-local line-spacing dk/prose-line-spacing))
```

and use `:hook (markdown-mode . dk/prose-setup)` / `:hook (org-mode . dk/prose-setup)`.

---

## 3. Redundancy — things to remove

### 3.1 Four formatting mechanisms, overlapping

| Mechanism | Line | Covers |
|---|---|---|
| `apheleia-global-mode` | 429 | rustfmt, gofmt, clang-format, fourmolu, … (async, preserves point) |
| `gofmt-before-save` | 471 | Go (sync, blocking) |
| `dk/clang-fos` → `clang-format-buffer` | 483 | C/C++ (sync, blocking) |
| `rustic-format-on-save t` | 480 | Rust (sync, blocking) |

**[verified]** apheleia's default `apheleia-mode-alist` already maps every one of your
languages: `c-mode`/`c-ts-mode`/`c++-mode`/`c++-ts-mode` → `clang-format`,
`go-mode`/`go-ts-mode` → `gofmt`, `rust-mode`/`rust-ts-mode`/`rustic-mode` → `rustfmt`, and
`haskell-mode`/`haskell-ts-mode` → `fourmolu` (which matches the `formattingProvider` you
already set for HLS). The other three mechanisms are strictly worse duplicates — synchronous,
they clobber point and scroll position, and they run *in addition* to apheleia on every save.

**Fix** — delete all three:

```elisp
;; init.el:470-472 — DELETE
(add-hook 'go-mode-hook
          (lambda() (add-hook 'before-save-hook #'gofmt-before-save nil t)))

;; init.el:480 — DELETE from the rustic block
(setq rustic-format-on-save t)

;; init.el:482-483 — DELETE the hook (keep the clang-format package only if you
;; still want M-x clang-format-region available on demand)
(use-package clang-format
  :hook ((c-ts-mode c-mode c++-ts-mode c++-mode) . dk/clang-fos))
```

**Preserving the `dk/clang-fos` guard.** Your "only format when a `.clang-format` exists"
rule is a genuinely good idea and is worth porting rather than losing. **[verified]**
apheleia checks `apheleia-inhibit-functions` (a hook run with
`run-hook-with-args-until-success` — non-nil inhibits) plus the buffer-local
`apheleia-inhibit`:

```elisp
;; src/functions.el
(defun dk/apheleia-inhibit-unconfigured-c ()
  "Inhibit apheleia in C/C++ buffers with no .clang-format in scope."
  (and (derived-mode-p 'c-mode 'c-ts-mode 'c++-mode 'c++-ts-mode)
       (not (locate-dominating-file default-directory ".clang-format"))))

;; init.el
(use-package apheleia
  :init (apheleia-global-mode +1)
  :config (add-hook 'apheleia-inhibit-functions #'dk/apheleia-inhibit-unconfigured-c))
```

`dk/clang-fos` can then be deleted from `src/functions.el`.

### 3.2 `rust-mode` + `rustic` + duplicated eglot hooks

`rustic` already depends on `rust-mode` (both are in `elpa/`), so `(use-package rust-mode)`
at line 464 adds only an eager `require`. Meanwhile eglot is hooked onto `rust-mode`,
`rust-ts-mode` *and* `rustic-mode` — three entry points for the same server.

**Decision rule:** rustic's remaining value over `rust-ts-mode` is its `cargo` command
wrappers (`rustic-cargo-test`, `rustic-cargo-add`, …) and its test-result buffer. If you
don't use those, rustic is pure overhead — `compile` + `rust-ts-mode` covers the rest, and
`rust-ts-mode` gives you the tree-sitter grammar you already install but never use.

**Proposal (recommended) — drop rustic and rust-mode entirely:**

```elisp
;; DELETE (use-package rust-mode) and the whole (use-package rustic ...) block.
;; rust-ts-mode is built into Emacs 30; add the remap (§5.3) and one eglot hook:
(use-package rust-ts-mode
  :ensure nil
  :mode "\\.rs\\'"
  :hook (rust-ts-mode . eglot-ensure))
```

Then remove `rust-mode`, `rust-ts-mode` and `rustic-mode` from eglot's `:hook` list, since
the hook now lives with the mode.

**Fallback — if you want to keep rustic's cargo commands**, at minimum delete the
standalone `(use-package rust-mode)` and drop `rust-mode`/`rust-ts-mode` from eglot's
`:hook`, leaving `rustic-mode . eglot-ensure` as the single entry point.

### 3.3 `all-the-icons` vs `nerd-icons`

`elpa/` contains **both** `all-the-icons` and `nerd-icons`, plus `nerd-icons-corfu` and
`nerd-icons-dired` which are **not referenced anywhere in the config** — leftovers.

The community has moved to `nerd-icons`: it needs one font (`ttf-nerd-fonts-symbols`,
which your `install.notes` already installs), works in the terminal, and **[verified]**
doom-modeline's source references `nerd-icons` 6 times and `all-the-icons` zero times — so
`all-the-icons` is currently doing nothing for your modeline.

**Fix** — replace the icon packages:

```elisp
(use-package nerd-icons)

(use-package nerd-icons-dired
  :hook (dired-mode . nerd-icons-dired-mode))

(use-package nerd-icons-corfu
  :after corfu
  :config (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))
```

and delete `(use-package all-the-icons)`, `(use-package all-the-icons-dired ...)`, and
`(use-package kind-icon ...)`. (`kind-icon` renders SVGs via `svg-lib` and is noticeably
slower than `nerd-icons-corfu`; it also needs `(setq kind-icon-default-face 'corfu-default)`
to not look wrong on a dark theme, which your config is missing anyway.)

**Removing the orphans.** `alabaster-themes`, `modus-themes` and `xterm-color` appear
nowhere in the config either. `package-autoremove` is unsafe here until §10.4 is fixed, so
remove them explicitly:

```
M-x package-delete RET all-the-icons RET
M-x package-delete RET all-the-icons-dired RET
M-x package-delete RET kind-icon RET
M-x package-delete RET alabaster-themes RET
M-x package-delete RET modus-themes RET
M-x package-delete RET xterm-color RET
```

`svg-lib` becomes an orphan once `kind-icon` is gone; `popon` is still needed by
`corfu-terminal`, so leave it.

### 3.4 Duplicate `with-eval-after-load 'eglot` blocks

Three separate blocks at lines 289, 310 (+ the stray `setq` at 308).

**Fix** — one block, with §1.3 and §2.2 folded in:

```elisp
(with-eval-after-load 'eglot
  ;; One `add-to-list' per server: the value is an alist of (MODES . CONTACT), so a
  ;; single call must not wrap them in an extra list.  `add-to-list' prepends and
  ;; eglot takes the first match, so these win over eglot's built-in defaults.
  (add-to-list 'eglot-server-programs
               '((haskell-mode haskell-ts-mode)
                 . ("haskell-language-server-wrapper" "--lsp")))
  (add-to-list 'eglot-server-programs
               '((rust-ts-mode rust-mode)
                 . ("rust-analyzer" :initializationOptions
                    (:check (:command "clippy")))))
  ;; Separate entries: the std fallback flag differs between C and C++
  ;; (used only when there is no compile_commands.json / .clangd)
  (add-to-list 'eglot-server-programs
               '((c-ts-mode c-mode)
                 . ("clangd" "--clang-tidy"
                    :initializationOptions (:fallbackFlags ["-std=c23"]))))
  (add-to-list 'eglot-server-programs
               '((c++-ts-mode c++-mode)
                 . ("clangd" "--clang-tidy"
                    :initializationOptions (:fallbackFlags ["-std=c++23"]))))
  (advice-add 'eglot--format-markup :filter-args #'dk/eglot-clean-haskell-markdown))
```

### 3.5 `tab-always-indent` set twice, to conflicting values

```elisp
init.el:76   (setq tab-always-indent t)          ; "Common settings"
init.el:339  (setq tab-always-indent 'complete)  ; inside embark's :init
```

The second wins. Beyond the conflict, `tab-always-indent` and `completion-cycle-threshold`
are **corfu** settings, not embark settings — they're in the wrong `use-package` block,
which is why the duplicate went unnoticed.

**Fix** — delete `init.el:76`, strip embark's `:init` down to nothing, and move both
settings to corfu:

```elisp
(use-package embark
  :bind (("C-."   . embark-act)
         ("C-;"   . embark-dwim)
         ("C-h B" . embark-bindings)))

(use-package corfu
  :custom
  (tab-always-indent 'complete)     ; TAB indents, then completes
  (completion-cycle-threshold 3)
  ... ; existing corfu settings
  )
```

### 3.6 Redundant `eldoc-mode` hook

`init.el:278` — `(add-hook 'prog-mode-hook 'eldoc-mode)`. `global-eldoc-mode` is enabled by
default in Emacs 30, and eglot turns eldoc on itself.

**Fix** — delete that line from eglot's `:config`.

---

## 4. Startup cost

Measured with `emacs --batch -l early-init.el -l init.el` (no GUI/font/theme rendering, so
this is a *floor*, not your real startup):

```
current config     ~690–745 ms
bare emacs --batch     ~76 ms
```

### 4.1 The explicit `(package-initialize)` defeats `package-quickstart` **[verified]**

You set `package-quickstart t` in `early-init.el:31` (good — the 344 KB
`package-quickstart.el` is being generated). But since Emacs 27, `package-activate-all`
already runs *before* `init.el` and it uses that quickstart file. Then `init.el:25` calls
`(package-initialize)`, which does the **full `elpa/` directory scan** the quickstart file
exists to avoid.

Measured cost of that scan alone: **190 ms** vs a 76 ms baseline → ~115 ms of pure waste
on every startup.

**Fix** — replace `init.el:20-27` with just the archive list:

```elisp
;; package.el is already loaded and all packages activated by `package-activate-all',
;; which startup.el runs before init.el.  Do not call `package-initialize' here --
;; it re-scans elpa/ from scratch and defeats `package-quickstart'.
(setq package-archives '(("melpa"  . "https://melpa.org/packages/")
                         ("org"    . "https://orgmode.org/elpa/")
                         ("elpa"   . "https://elpa.gnu.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/")))
```

**The network fetch.** `(unless package-archive-contents (package-refresh-contents))` blocks
startup on an HTTP round-trip whenever the archive cache is cold — including the first run
on a new machine, when it is slowest and least expected.

**Fix** — make it an explicit command instead of a startup step:

```elisp
;; src/functions.el
(defun dk/packages-bootstrap ()
  "Refresh archives and install everything `use-package' declared.
Run once on a new machine, or after adding packages."
  (interactive)
  (package-refresh-contents)
  (package-install-selected-packages t))
```

Also note **[verified]** that `use-package` is built-in in Emacs 30.2, so the
`(unless (package-installed-p 'use-package) (package-install 'use-package))` bootstrap at
`init.el:29-30` and the following `(require 'use-package)` are dead. Keep only:

```elisp
(setq use-package-always-ensure t)
```

### 4.2 Packages loaded eagerly for no reason

`use-package-always-ensure t` is set but there's no deferral discipline. These have no
`:defer`/`:bind`/`:hook`/`:mode`/`:commands`, so they get a full `require` at startup.

**Fix, per package:**

```elisp
;; Four theme packages, fully loaded purely so their themes are *available*.
;; Themes only need to be on `custom-theme-load-path', which package activation
;; already handles.  This is the single biggest easy win.
(use-package doom-themes     :defer t)
(use-package ef-themes       :defer t)
(use-package gruvbox-theme   :defer t)
(use-package spacemacs-theme :defer t)

;; Bound via global-set-key in keymap.el, which autoloads fine on first press.
;; The bare use-package form is what forces the eager load.
(use-package expand-region :defer t)

;; :init alone does not defer.  The capfs are autoloaded, so this is safe.
(use-package cape
  :defer t
  :custom (cape-dabbrev-min-length 3)
  :init
  (add-hook 'completion-at-point-functions #'cape-file 10)
  (add-hook 'completion-at-point-functions #'cape-dabbrev 20))
```

`all-the-icons` and `rust-mode` are also eager, but both are removed outright by §3.3 and
§3.2 respectively.

**To measure the result** rather than guess:

```elisp
(setq use-package-compute-statistics t)   ; then M-x use-package-report
```

### 4.3 `treesit` grammar check runs on every startup

`init.el:247-249` loops over 9 languages calling `treesit-language-available-p` at every
startup. The check itself is cheap-ish, but the `:config` block also forces `treesit` to
load eagerly, and on a *fresh* machine this silently triggers 9 git-clone-and-compile jobs
during init — blocking, with no feedback.

**Fix** — move the grammar list to `src/vars.el` (§2.3), make installation a command, and
let the `use-package` block become pure configuration:

```elisp
;; src/functions.el
(defun dk/treesit-install-missing ()
  "Compile and install any tree-sitter grammar that is missing.
Needs git and a C compiler.  Run once per machine."
  (interactive)
  (dolist (lang (mapcar #'car treesit-language-source-alist))
    (if (treesit-language-available-p lang)
        (message "tree-sitter grammar present: %s" lang)
      (message "Installing tree-sitter grammar: %s" lang)
      (treesit-install-language-grammar lang))))

;; init.el
(use-package treesit
  :ensure nil
  :defer t
  :custom
  (treesit-font-lock-level 4)           ; maximum highlighting detail
  (treesit-language-source-alist dk/treesit-languages))
```

---

## 5. Built-in settings worth adding

### 5.1 Needed by what you already run **[verified missing]**

**Fix** — add to the "Common settings" section:

```elisp
;; enable-recursive-minibuffers is nil by default — but dk/M-x-dwim and
;; embark-act-from-the-minibuffer both assume recursive minibuffers work.
(setq enable-recursive-minibuffers t)
(minibuffer-depth-indicate-mode 1)

;; default is 65536; eglot/LSP servers send far larger payloads.
;; This is the single highest-impact LSP responsiveness setting.
(setq read-process-output-max (* 4 1024 1024))
(setq process-adaptive-read-buffering nil)

;; Vertico's own README recommends this: hides commands irrelevant to the
;; current mode from M-x.  Default is nil.
(setq read-extended-command-predicate #'command-completion-default-include-p)

;; consult's xref integration — you have both packages but they aren't wired together
(setq xref-show-xrefs-function       #'consult-xref
      xref-show-definitions-function #'consult-xref)
```

### 5.2 General hygiene (all absent)

**Fix:**

```elisp
(setq-default indent-tabs-mode nil)
(setq-default fill-column 80)
(setq sentence-end-double-space nil)
(setq require-final-newline t)
(setq kill-do-not-save-duplicates t)
(setq mouse-yank-at-point t)
(setq confirm-kill-emacs #'yes-or-no-p)
(setq history-length 1000)
(setq savehist-additional-variables
      '(kill-ring register-alist search-ring regexp-search-ring corfu-history))
(setq recentf-exclude
      (list (regexp-quote (expand-file-name "elpa/" user-emacs-directory))
            "/tmp/" "/ssh:" "\\.gz\\'" "/COMMIT_EDITMSG\\'"))
(setq uniquify-buffer-name-style 'forward)
(setq bookmark-save-flag 1)
(setq switch-to-buffer-obey-display-actions t)
(setq compilation-scroll-output 'first-error)
(setq describe-bindings-outline t)
(pixel-scroll-precision-mode 1)
(context-menu-mode 1)
(add-hook 'compilation-filter-hook #'ansi-color-compilation-filter)
```

`corfu-history` in `savehist-additional-variables` needs the mode turned on — it lives in a
separate file, so require it:

```elisp
;; inside the corfu use-package :init
(require 'corfu-history)
(corfu-history-mode 1)          ; sorts candidates by how often you actually pick them
```

**About `indent-tabs-mode`:** setting it only affects *new* indentation; your existing
`init.el` has 55 tab-containing lines and `src/functions.el` has 2, which will stay mixed.
If you want them consistent, retab once:

```
C-x h                          ; mark whole buffer
M-x untabify RET
```

Do this as a standalone commit so it doesn't bury real changes in whitespace noise.

### 5.3 tree-sitter remaps you're missing

You install the `rust` grammar and use `go-mode`, but neither is remapped, and Emacs 30
ships `go-ts-mode` **[verified]**.

**Fix** — extend `major-mode-remap-alist`:

```elisp
(setq major-mode-remap-alist
      '((c-mode         . c-ts-mode)
        (c++-mode       . c++-ts-mode)
        (c-or-c++-mode  . c-or-c++-ts-mode)
        (python-mode    . python-ts-mode)
        (sh-mode        . bash-ts-mode)
        (js-json-mode   . json-ts-mode)
        (conf-toml-mode . toml-ts-mode)
        (rust-mode      . rust-ts-mode)      ; new
        (go-mode        . go-ts-mode)))      ; new
```

The `go` and `gomod` grammars are already added to `dk/treesit-languages` in §2.3.

**Consequence that must be fixed at the same time:** eglot's `:hook` list uses `haskell-mode`
and `go-mode`. After remapping, those hooks never fire and eglot silently won't start.

```elisp
(use-package eglot
  :ensure nil
  :hook ((haskell-mode    . eglot-ensure)
         (haskell-ts-mode . eglot-ensure)   ; new
         (c-ts-mode       . eglot-ensure)
         (c++-ts-mode     . eglot-ensure)
         (go-ts-mode      . eglot-ensure)   ; replaces go-mode
         (rust-ts-mode    . eglot-ensure)   ; replaces rust-mode/rustic
         (python-base-mode . eglot-ensure))
  :config
  (setq eglot-events-buffer-config '(:size 0))
  (setq eglot-extend-to-xref t)
  (setq eglot-autoshutdown t)               ; new: kill the server with the last buffer
  (setq eglot-sync-connect nil)             ; new: don't block on server startup
  (setq eglot-code-actions-indications '(eldoc-hint margin))
  (setq-default eglot-workspace-configuration
                '(:haskell (:formattingProvider "fourmolu"))))
```

The plain `c-mode`/`c++-mode` hooks can go, since `major-mode-remap-alist` guarantees you
land in the `-ts-` variants.

### 5.4 `xterm-mouse-mode` should be conditional

`init.el:70` runs it unconditionally. It's meaningful only in a TTY.

**Fix:**

```elisp
(unless (display-graphic-p) (xterm-mouse-mode 1))
```

### 5.5 Font setting is fragile

`init.el:83` calls `set-face-attribute` at load time with a hard-coded family. If
`ttf-aporetic` (AUR-only, per your own `install.notes`) isn't installed, or if you ever run
`emacs --daemon`, this misbehaves — `set-face-attribute` at init time applies to the
*current* frame, and under a daemon there isn't one yet.

**Fix** (uses the variables from §2.3):

```elisp
(when (find-font (font-spec :family dk/font-family))
  (add-to-list 'default-frame-alist
               (cons 'font (format "%s-%d" dk/font-family (/ dk/font-height 10))))
  (set-face-attribute 'minibuffer-prompt nil
                      :family dk/font-family :height dk/minibuffer-font-height))
```

`default-frame-alist` also applies to frames created later by `emacsclient`.

---

## 6. Completion stack refinements

You're 90% of the way to the canonical setup. Remaining gaps:

### 6.1 `consult-preview-key 'any` with zero delay is aggressive

It previews on *every* keystroke, including for `consult-buffer` (which visits buffers) and
remote/TRAMP files.

**Fix** — keep the eager default, but debounce the expensive sources:

```elisp
(consult-customize
 consult-ripgrep consult-git-grep consult-grep consult-recent-file
 consult--source-recent-file consult--source-project-recent-file
 consult--source-bookmark
 :preview-key '(:debounce 0.3 any))
```

### 6.2 Missing consult commands

You have the package but not the bindings that make it worth having. `consult-ripgrep` in
particular is the one most people use daily, and you already install `ripgrep` per
`install.notes`.

**Fix** — add to consult's `:bind`:

```elisp
("M-s r"   . consult-ripgrep)     ; project-wide search — the big one
("M-s g"   . consult-grep)
("M-g i"   . consult-imenu)       ; you set org-imenu-depth 4 but have no imenu binding
("M-g I"   . consult-imenu-multi)
("M-g g"   . consult-goto-line)
("M-g m"   . consult-mark)
("M-'"     . consult-register-store)
("C-x r b" . consult-bookmark)
```

### 6.3 `register-preview` isn't wired to consult

**Fix** — three lines, big usability gain:

```elisp
(setq register-preview-delay 0.5
      register-preview-function #'consult-register-format)
(advice-add #'register-preview :override #'consult-register-window)
```

### 6.4 `corfu`'s `RET` binding is a common regret

`("RET" . corfu-insert)` means you can't press Enter to dismiss the popup and start a
newline — a frequent annoyance when the popup appears unbidden with `corfu-auto t`.

**Fix** — leave `RET` to the buffer and complete with `TAB` only:

```elisp
:bind (:map corfu-map
            ("TAB" . corfu-insert)
            ("RET" . nil)                  ; newline stays a newline
            ("M-d" . corfu-popupinfo-toggle)
            ("C-g" . corfu-quit)
            ("M-l" . corfu-show-location))
```

### 6.5 `cape` capf ordering

`(add-hook 'completion-at-point-functions #'cape-dabbrev)` with the default depth
*prepends*, so `cape-dabbrev` can outrank more precise sources.

**Fix** — already folded into the deferred cape block in §4.2:

```elisp
(add-hook 'completion-at-point-functions #'cape-file 10)
(add-hook 'completion-at-point-functions #'cape-dabbrev 20)
```

### 6.6 `which-key` is built-in in Emacs 30.2 **[verified]**

`:ensure t` is a silent no-op — nothing was installed into `elpa/`.

**Fix** — make it explicit, and move the delay to `:custom` so it's set *before* the mode
turns on (currently `:config` sets it after, which works only because which-key reads the
variable lazily):

```elisp
(use-package which-key
  :ensure nil
  :custom (which-key-idle-delay 0.7)
  :init (which-key-mode))
```

---

## 7. Keybinding review (`src/keymap.el`)

### 7.1 `<escape>` → `keyboard-escape-quit` deletes your window layout

From the docstring **[verified]**: *"…or go back to just one window (by deleting all but
the selected window)."* When there's nothing to quit, pressing Escape silently runs
`delete-other-windows`. This is one of the most commonly-regretted bindings.

**Fix** — a `dk/` wrapper in `src/functions.el`:

```elisp
(defun dk/escape-dwim ()
  "Quit the minibuffer if active, otherwise plain `keyboard-quit'.
Never deletes windows, unlike `keyboard-escape-quit'."
  (interactive)
  (if (active-minibuffer-window)
      (abort-recursive-edit)
    (keyboard-quit)))
```

```elisp
;; src/keymap.el
(global-set-key (kbd "<escape>") #'dk/escape-dwim)
```

### 7.2 `C-c C-f` / `C-c C-e` / `C-c ?` are in major-mode territory

Emacs convention: `C-c <letter>` is reserved for the user, `C-c C-<letter>` belongs to
major modes. Your global `C-c C-f` (consult-find) and `C-c C-e` (eval-buffer) get shadowed
unpredictably — markdown-mode already rebinds `C-c C-e` in your own config (`init.el:506`).

**Fix** — move them into user space and onto consult's conventional prefixes:

```elisp
;; in consult's :bind — replaces ("C-c C-f" . consult-find) and ("C-c ?" . consult-flymake)
("M-s f" . consult-find)
("M-g f" . consult-flymake)
("C-c m" . consult-mode-command)     ; already fine: C-c + plain letter
```

### 7.3 `C-c e` → `eval-buffer` globally

`eval-buffer` is only meaningful in `emacs-lisp-mode`, where `C-M-x` (eval-defun) and
`C-c C-c` already exist — and a stray press in a *code* buffer of another language does
nothing useful.

**Fix** — scope it, and use the more common `eval-buffer`/`eval-region` dwim:

```elisp
;; src/keymap.el — replaces the global binding
(with-eval-after-load 'elisp-mode
  (define-key emacs-lisp-mode-map (kbd "C-c e") #'eval-buffer))
```

### 7.4 `C-c r` → `cua-mode`

Toggling a global editing paradigm from a two-key sequence is an easy accidental press, and
CUA's `C-x`/`C-c` rebinding means the *first* misfire can make the config feel broken.

**Fix** — if you actually use it, at least make it deliberate and discoverable; if it was
exploratory, delete the line.

```elisp
;; Option A — keep it but move off the easily-mistyped C-c r
(global-set-key (kbd "C-c T c") #'cua-mode)

;; Option B (recommended if you can't remember last using it) — delete the binding.
;; M-x cua-mode still works when you want it.
```

### 7.5 Bindings that are good as-is

No change needed: `M-o` → `other-window`, `M-/` → comment toggle, the
`upcase/downcase/capitalize-dwim` trio, `C-x C-b` → `ibuffer`, `C-=` → `er/expand-region`,
and the `S-<backspace>` binding on `minibuffer-local-map` (the reasoning in your comment
about it being the parent keymap is correct).

---

## 8. Version control

`diff-hl` is missing the magit integration hooks, so fringe indicators go stale after every
magit operation — a very common complaint — and `diff-hl-flydiff-mode` is off, so they only
update on save.

**Fix:**

```elisp
(use-package diff-hl
  :hook ((prog-mode  . diff-hl-mode)
         (dired-mode . diff-hl-dired-mode)
         (magit-pre-refresh  . diff-hl-magit-pre-refresh)     ; new
         (magit-post-refresh . diff-hl-magit-post-refresh))   ; new
  :config
  (diff-hl-flydiff-mode 1))                                   ; new: update on edit
```

---

## 9. Packages worth adding

Ranked by how much they'd change your day-to-day, given what's in this config. Each entry
has a drop-in `use-package` block — the whole section can be pasted as-is and pruned.

### 9.1 Top tier

**`no-littering`** — your config root has `history`, `places`, `recentf`,
`projectile-*.eld`, `transient/`, `auto-save-list/`, plus 12 lines of `.gitignore` fighting
them. Highest quality-of-life-per-line in this list. Must load **early**, before anything
sets a state file path:

```elisp
(use-package no-littering
  :demand t
  :init
  ;; must be set before the package computes its directories
  (setq no-littering-etc-directory (expand-file-name "etc/" user-emacs-directory)
        no-littering-var-directory (expand-file-name "var/" user-emacs-directory))
  :config
  (no-littering-theme-backups)
  (setq auto-save-file-name-transforms
        `((".*" ,(no-littering-expand-var-file-name "auto-save/") t)))
  (setq custom-file (no-littering-expand-etc-file-name "custom.el")))
```

Then `.gitignore` collapses to:

```
eln-cache/
elpa/
etc/
var/
package-quickstart.el*
\#*
.#*
*~
```

This also supersedes §1.2 — but fix the trailing slash first regardless, so the config is
correct on its own.

**`wgrep`** — you have embark + consult but no way to *edit* the results.
`consult-ripgrep` → `embark-export` → editable grep buffer → project-wide refactor is the
combo you're currently missing half of:

```elisp
(use-package wgrep
  :custom (wgrep-auto-save-buffer t)
  :bind (:map grep-mode-map ("C-c C-p" . wgrep-change-to-wgrep-mode)))
```

**`vundo`** — you raised `undo-limit` 13×, which says you care about undo history, but
there's no way to navigate it. Zero dependencies, unlike `undo-tree`:

```elisp
(use-package vundo
  :bind ("C-c u" . vundo)
  :custom (vundo-glyph-alist vundo-unicode-symbols))
```

**`tempel`** — no snippet system at all. Capf-native, so it plugs straight into your
existing corfu/cape setup:

```elisp
(use-package tempel
  :bind (("M-+" . tempel-complete)
         ("M-*" . tempel-insert)
         :map tempel-map
         ("TAB" . tempel-next)
         ("S-TAB" . tempel-previous))
  :init
  (defun dk/tempel-setup-capf ()
    (setq-local completion-at-point-functions
                (cons #'tempel-expand completion-at-point-functions)))
  (add-hook 'conf-mode-hook  #'dk/tempel-setup-capf)
  (add-hook 'prog-mode-hook  #'dk/tempel-setup-capf)
  (add-hook 'text-mode-hook  #'dk/tempel-setup-capf))
```

(`dk/tempel-setup-capf` belongs in `src/functions.el` per your convention.)

### 9.2 Worth having

**`avy`** — the standard intra-buffer jump:

```elisp
(use-package avy
  :bind (("M-j"   . avy-goto-char-timer)
         ("M-g w" . avy-goto-word-1)
         ("M-g l" . avy-goto-line)))
```

**`envrc`** — you use Haskell (ghcup), Rust (rustup) and Go. If you ever touch direnv/nix
per-project toolchains, this is what makes eglot pick up the *right*
`haskell-language-server`. Must be near the end of init so its hook runs first:

```elisp
(use-package envrc
  :hook (after-init . envrc-global-mode))
```

**`hl-todo`** — trivial, highlights TODO/FIXME, pairs with `M-s r TODO`:

```elisp
(use-package hl-todo
  :hook (prog-mode . hl-todo-mode)
  :bind (:map hl-todo-mode-map
              ("C-c n" . hl-todo-next)
              ("C-c P" . hl-todo-previous)))
```

**`consult-dir`** — jump to project/recent/bookmark directories from inside any file prompt:

```elisp
(use-package consult-dir
  :bind (("C-x C-d" . consult-dir)
         :map vertico-map
         ("C-x C-d" . consult-dir)
         ("C-x C-j" . consult-dir-jump-file)))
```

**`eldoc-box`** — the child-frame hover docs that §1.3's dead setting was reaching for:

```elisp
(use-package eldoc-box
  :hook (eglot-managed-mode . eldoc-box-hover-at-point-mode)
  :custom (eldoc-box-max-pixel-width 600))
```

**`popper`** — tames `*compilation*`, `*eglot*`, `*Help*`. Relevant since you hand-wrote
`dk/helpful-open`/`dk/helpful-close`; popper generalises that idea:

```elisp
(use-package popper
  :bind (("C-`"   . popper-toggle)
         ("M-`"   . popper-cycle)
         ("C-M-`" . popper-toggle-type))
  :custom
  (popper-reference-buffers
   '("\\*Messages\\*" "\\*Warnings\\*" "Output\\*$" "\\*Async Shell Command\\*"
     "\\*eldoc\\*" "\\*compilation\\*" help-mode helpful-mode compilation-mode))
  :init
  (popper-mode 1)
  (popper-echo-mode 1))
```

### 9.3 Situational

**`dape`** — DAP debugging, built to match eglot's philosophy. You have four compiled
languages and no debugger:

```elisp
(use-package dape
  :custom
  (dape-buffer-window-arrangement 'right)
  (dape-inlay-hints t)
  :config (dape-breakpoint-global-mode 1))
```

Needs `delve` for Go and `codelldb` for Rust/C++ installed separately.

**`eat`** — no terminal emulator is configured at all. Pure elisp, no compilation step
(unlike `vterm`):

```elisp
(use-package eat
  :bind ("C-c s" . eat)
  :custom (eat-kill-buffer-on-exit t)
  :hook (eshell-load . eat-eshell-mode))
```

**`jinx`** — spell-check for your prose modes. Needs `enchant` + a dictionary
(`sudo pacman -S enchant hunspell-en_us`):

```elisp
(use-package jinx
  :hook ((markdown-mode org-mode text-mode) . jinx-mode)
  :bind (("M-$" . jinx-correct)
         ("C-M-$" . jinx-languages)))
```

### 9.4 Explicitly not recommended

- **`undo-tree`** — history files corrupt, effectively unmaintained. Use `vundo`.
- **`lsp-mode`** — you're happy on eglot; migrating costs a lot and buys little here.
- **`treemacs`** — you have dired + projectile + consult; a sidebar duplicates all three.

---

## 10. Judgement calls — with a recommendation for each

### 10.1 `projectile` vs built-in `project.el`

Emacs 30's `project.el` is genuinely good now, and consult/embark integrate with it
natively. You're carrying projectile + consult-projectile + a cache file + two
`projectile-globally-ignored-buffers` workarounds for functionality that's ~90% built in.

**Decision rule:** projectile still wins on `alien` indexing in very large repos and on the
breadth of `C-c p`. If you mostly use *find file / switch project / switch buffer* — which
is all four of your current `C-c p` bindings — `project.el` covers it.

**Recommendation: stay on projectile for now.** It works, the migration touches a lot of
muscle memory, and it isn't costing you correctness — only ~30 ms of eager load and one
extra dependency. Revisit only if you drop `consult-projectile`.

**If you do migrate,** the mapping is direct — no third-party package needed:

```elisp
(use-package project
  :ensure nil
  :bind (("C-c p f" . project-find-file)
         ("C-c p p" . project-switch-project)
         ("C-c p b" . consult-project-buffer)
         ("C-c p d" . project-find-dir)
         ("C-c p g" . consult-ripgrep))
  :custom
  (project-vc-extra-root-markers '(".project" "Cargo.toml" "go.mod" "*.cabal")))
```

Then remove `projectile`, `consult-projectile`, the `with-eval-after-load 'projectile`
block, and `projectile.cache` / `projectile-*.eld`.

### 10.2 `electric-pair-mode` vs structural editing

`electric-pair-mode` is fine and should stay on globally.

**Recommendation:** add `puni` for Lisp only — it's `electric-pair`-compatible (unlike
paredit, which fights it) and gives you real structural editing where it matters:

```elisp
(use-package puni
  :hook ((emacs-lisp-mode lisp-mode) . puni-mode)
  :bind (:map puni-mode-map
              ("C-)" . puni-slurp-forward)
              ("C-}" . puni-barf-forward)))
```

### 10.3 Theme surface area

`themes/` holds 32 manually-vendored themes and `elpa/` holds 6 theme packages, but only
`gruber-darker` is loaded. `(setq custom-safe-themes t)` disables signature checking
wholesale.

**Recommendation:** keep `gruber-darker` plus at most one or two you actually rotate
through, and stop blanket-trusting.

```elisp
;; 1. Prune themes/ down to what you use:
;;      cd ~/.config/emacs/themes && ls        # 32 files today
;;    Keep gruber-darker-theme.el; move the rest to a personal archive or delete.
;;
;; 2. Replace the blanket trust with an explicit allowlist.  Load the theme once
;;    with custom-safe-themes still t, answer the prompt, and Custom writes the
;;    hashes for you -- then set it back:
(setq custom-safe-themes
      '("<sha256 of gruber-darker>" "<sha256 of any other you keep>"))

;; 3. Keep :defer t on the theme packages you retain (§4.2).
(load-theme 'gruber-darker t)
```

If pruning feels like busywork, the minimum useful change is step 3 alone — the 32 vendored
files cost nothing at runtime, they just make `M-x consult-theme` noisy.

### 10.4 `custom.el` contains `'(package-selected-packages nil)`

With that empty, `M-x package-autoremove` considers **every** installed package orphaned —
it would offer to delete all 60.

**Fix** — populate it once from what's actually activated, then let Custom maintain it:

```elisp
M-x eval-expression RET
  (progn (setq package-selected-packages (mapcar #'car package-alist))
         (customize-save-variable 'package-selected-packages package-selected-packages))
```

After that, `package-autoremove` is safe and `dk/packages-bootstrap` (§4.1) can reinstall
everything on a new machine via `package-install-selected-packages`.

### 10.5 `custom-file` is loaded too early

`init.el:14-16` loads it before any `use-package` block runs, so a value you set through
`M-x customize` gets silently overwritten by the `:custom` in the corresponding
`use-package` form — the opposite of what you'd expect.

**Fix** — move the load to the very bottom of `init.el`, just above `(provide 'init)`:

```elisp
;; init.el — near the top, keep only the path
(setopt custom-file (locate-user-emacs-file "custom.el"))

;; init.el — last thing before (provide 'init), so Custom wins over use-package defaults
(when (file-exists-p custom-file)
  (load custom-file nil t))
```

---

## 11. Structural proposal

`init.el` is 583 lines and growing linearly. You already have `src/` as a module directory
— extend the convention rather than letting `init.el` absorb everything:

```
early-init.el          GC, frame params, package-quickstart, loads src/bootstrap.el
init.el                ~40 lines: load path + (require 'init-xxx) sequence
src/bootstrap.el       dk/add-to-confdir, dk/add-paths-to-list  (needed pre-init)
src/vars.el            dk/* user variables                      (currently empty!)
src/functions.el       all dk/* functions
src/keymap.el          all global-set-key
src/init-ui.el         fonts, theme, modeline, line numbers, scrolling
src/init-completion.el vertico, orderless, marginalia, consult, embark, corfu, cape
src/init-editing.el    dired, magit, diff-hl, apheleia, expand-region
src/init-lang.el       treesit, eglot, flymake, per-language modes
src/init-org.el        org, org-modern, org-appear, markdown, valign
```

**Fix** — the resulting `init.el` body:

```elisp
;; -*- lexical-binding: t; -*-
(dk/add-paths-to-list 'load-path '("src") t)
(dk/add-paths-to-list 'custom-theme-load-path '("themes/") t)

(setq-default user-full-name "Dmitry Kvasnikov"
              user-mail-address "dmitry.kvasnikov@gmail.com")
(setopt custom-file (locate-user-emacs-file "custom.el"))

(require 'vars)
(require 'functions)
(require 'init-ui)
(require 'init-completion)
(require 'init-editing)
(require 'init-lang)
(require 'init-org)
(require 'keymap)          ; last: bindings may reference commands from any module

(when (file-exists-p custom-file)          ; last of all — see §10.5
  (load custom-file nil t))

(provide 'init)
```

### 11.1 Section headings

The `;;;;;;;;` banner rows are decorative only.

**Fix** — use `;;;` headings, which `outline-minor-mode` and `imenu` both understand for
free:

```elisp
;;; Coding environment        ; instead of the ;;;;;;;; banner row

;; and, in init-ui.el or wherever your elisp settings live:
(add-hook 'emacs-lisp-mode-hook #'outline-minor-mode)
```

You then get folding (`C-c @ C-t`) and `M-g i` (`consult-imenu`, §6.2) navigation over your
own config.

### 11.2 `provide` / `require` mismatch

`(provide 'functions)` and `(provide 'keymap)` are currently pointless because `init.el`
uses `load`, not `require` — so re-evaluating `init.el` re-executes those files and, among
other things, re-runs every `add-hook`.

**Fix** — switch the call sites to `require`, as shown in the `init.el` body above.
`(provide 'init)` at the bottom of `init.el` is harmless but does nothing; keep it or drop
it as you prefer.

---

## 12. Suggested order of work

**Bugs first — each is one line, each is currently silently broken:**

1. `(global-auto-revert-mode 1)` — §1.1
2. Trailing slash on `auto-save-dir`, delete the two stray `#...#` files — §1.2
3. Wire up the flymake fringe bitmaps — §1.4
4. Delete `eglot-put-doc-in-buffer`, add the eldoc settings that actually do it — §1.3
5. Fix or remove `C-x C-p` — §1.5
6. Move `consult-history` off global `C-r` — §1.6

**Then the cheap high-impact ones:**

7. Delete `(require 'package)` + `(package-initialize)` + the use-package bootstrap — ~115 ms, §4.1
8. `:defer t` on the four theme packages, expand-region, cape — §4.2
9. `enable-recursive-minibuffers`, `read-process-output-max`,
   `read-extended-command-predicate`, `xref-show-xrefs-function` — §5.1
10. `diff-hl` magit hooks + flydiff — §8
11. `consult-ripgrep` / `consult-imenu` bindings — §6.2
12. Populate `package-selected-packages` so `package-autoremove` is safe — §10.4

**Then cleanup:**

13. Pick one formatter (apheleia), drop the other three, port the `.clang-format` guard — §3.1
14. Resolve `tab-always-indent` duplicate, move corfu settings out of embark — §3.5
15. all-the-icons → nerd-icons, `package-delete` the six orphans — §3.3
16. Delete the duplicated haskell-markdown function, merge the three eglot blocks — §2.2, §3.4
17. `dk/escape-dwim` for `<escape>` — §7.1
18. Move `custom-file` load to the bottom — §10.5

**Then the bigger calls:**

19. Move `early-init.el` functions into `src/bootstrap.el`, populate `src/vars.el`,
    reorder the loads — §2.1, §2.3
20. `rust-ts-mode`/`go-ts-mode` remaps + matching eglot hooks; decide on rustic — §3.2, §5.3
21. `no-littering` + `.gitignore` cleanup — §9.1
22. Split `init.el` into `src/init-*.el` modules, switch `load` → `require` — §11
23. Try `wgrep`, `vundo`, `tempel` — §9.1
