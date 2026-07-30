;; -*- lexical-binding: t; -*-
;;
;; Annotated copy of init.el: every global setting and package block below
;; carries a short comment describing what it does.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; User settings and variables

;; Identity used by VC commit templates, changelogs, mail and report-emacs-bug.
(setq-default user-full-name "Dmitry Kvasnikov"
	      user-mail-address "dmitry.kvasnikov@gmail.com")

;; Config load paths and load external files

;; Put ~/.config/emacs/src on `load-path' so the local modules below are requirable.
(dk/add-paths-to-list 'load-path '("src") t)
;; Let `load-theme' find the hand-maintained themes in ~/.config/emacs/themes/.
(dk/add-paths-to-list 'custom-theme-load-path '("themes/") t)
;; src/vars.el — dk/* constants (fonts, dirs, package list, treesit grammars).
(require 'vars)
;; src/functions.el — all dk/* helper functions used throughout this file.
(require 'functions)
;; src/keys.el — global keybindings that are not tied to one package.
(require 'keys)   ;; NOT 'keymap — Emacs preloads a built-in feature by that name

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Package settings

;; package.el is the installer; everything else here is bootstrap for use-package.
(require 'package)
;; Archives to fetch from, tried in this order: MELPA first, then org/GNU/NonGNU.
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
			 ("org" . "https://orgmode.org/elpa/")
			 ("elpa" . "https://elpa.gnu.org/packages/")
			 ("nongnu" . "https://elpa.nongnu.org/nongnu/")))
;; Activate all already-installed packages so their autoloads exist.
(package-initialize)
;; Download the archive indexes once, only if this is a fresh checkout.
(unless package-archive-contents
  (package-refresh-contents))
;; Initialize use-package on non-Linux platforms
;; Self-install use-package on a machine where it is not bundled/installed yet.
(unless (package-installed-p 'use-package)
  (package-install 'use-package))
(require 'use-package)
;; Every `use-package' form installs its package if missing — no per-form :ensure.
(setq use-package-always-ensure t)
;; Declare the wanted package set (from vars.el) so `package-autoremove' can prune.
(setq package-selected-packages dk/packages)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Common settings

;; Answer prompts with y/n instead of typing out yes/no.
(setq use-short-answers t)
(setq make-backup-files nil)         ;; do not make backup files
;; No .#file lock symlinks next to edited files.
(setq create-lockfiles nil)
;; Make sure the auto-save directory exists before the transform below points there.
(make-directory dk/auto-save-dir t)
;; Keep all #autosave# files in one directory instead of scattering them in the tree.
(setq auto-save-file-name-transforms
      `((".*" ,dk/auto-save-dir t)))
(setq trusted-content dk/trusted-dirs)  ;; enables elisp-flymake-byte-compile
(setq vc-follow-symlinks t)		;; Follow symlinks without confirmation
;; Deleted files go to the system trash in interactive sessions, but not in batch.
(setq delete-by-moving-to-trash (not noninteractive))
;; Silence the bell completely: no screen flash, no sound.
(setq visible-bell nil)
(setq ring-bell-function #'ignore)
;; Typing or yanking with an active region replaces it, as in other editors.
(delete-selection-mode t)
;; Persist minibuffer histories (and the extra variables listed below) across restarts.
(savehist-mode 1)
;; Reopen a file at the point position it had last time.
(save-place-mode 1)
;; Reload buffers whose file changed on disk (e.g. after a git checkout).
(global-auto-revert-mode 1)
;; Auto-revert Dired/Buffer-menu style buffers too, not just file buffers.
(setq global-auto-revert-non-file-buffers 1)
;; Revert silently — no "Reverting buffer..." echo-area noise.
(setq auto-revert-verbose nil)
;; Repeat the last command of a chord with its final key alone (C-x o o o ...).
(repeat-mode 1)
;; C-c <left>/<right> undo and redo window-layout changes.
(winner-mode 1)
;; Raise the undo memory caps ~13x so long editing sessions keep their history.
(setq undo-limit (* 13 160000)
      undo-strong-limit (* 13 240000)
      undo-outer-limit (* 13 24000000))
;; Text shown in *scratch* at startup.
(setq initial-scratch-message ";; He who walks alone  ... Always walks uphill but ... Beneath his feet are the ... Broken bones of flawed men ...\n\n")
;; Search settings
;; Scrolling commands stay inside isearch instead of terminating it.
(setq isearch-allow-scroll t)
;; Show "current/total" match count in the search prompt.
(setq isearch-lazy-count t)
;; Wrap around at buffer end without the error ding.
(setq isearch-wrap-pause 'no-ding)
;; C-s after C-r moves to the next match rather than re-finding the current one.
(setq isearch-repeat-on-direction-change t)
;; Allow starting a new minibuffer command from within a minibuffer.
(setq enable-recursive-minibuffers t)
;; Show the recursion depth in the minibuffer prompt so nesting stays visible.
(minibuffer-depth-indicate-mode 1)
;; Read up to 4 MiB per subprocess chunk — matters for LSP throughput.
(setq read-process-output-max (* 4 1024 1024))
;; Disable adaptive read throttling; lower latency for chatty processes.
(setq process-adaptive-read-buffering nil)
;; M-x hides commands that are not applicable to the current major mode.
(setq read-extended-command-predicate #'command-completion-default-include-p)
;; Indent with spaces everywhere by default.
(setq-default indent-tabs-mode nil)
;; Default wrap/fill column for `fill-paragraph' and friends.
(setq-default fill-column 80)
;; One space ends a sentence, so sentence motion works on modern prose.
(setq sentence-end-double-space nil)
;; Always terminate saved files with a newline.
(setq require-final-newline t)
;; Don't push a kill onto the kill-ring if it duplicates the previous one.
(setq kill-do-not-save-duplicates t)
;; Middle-click yanks at point instead of at the click position.
(setq mouse-yank-at-point t)
;; Ask before quitting Emacs (full yes-or-no, not just y/n).
(setq confirm-kill-emacs #'yes-or-no-p)
;; Keep 1000 entries in each history list.
(setq history-length 1000)
;; Extra variables savehist should persist beyond plain minibuffer histories.
(setq savehist-additional-variables
      '(kill-ring register-alist search-ring regexp-search-ring corfu-history
        ;; consult--line-history   ;; redundant — savehist already auto-tracks any
        ;; variable used as `minibuffer-history-variable', which is what
        ;; consult-line sets, so C-s history persists without listing it here.
        ))
;; Keep recentf free of package sources, temp files, remote paths and commit messages.
(setq recentf-exclude
      (list (regexp-quote (expand-file-name "elpa/" user-emacs-directory))
            "/tmp/" "/ssh:" "\\.gz\\'" "/COMMIT_EDITMSG\\'"))
;; Disambiguate same-named buffers as "dir/file" rather than "file<2>".
(setq uniquify-buffer-name-style 'forward)
;; Write the bookmark file after every change instead of only at exit.
(setq bookmark-save-flag 1)
;; `switch-to-buffer' respects `display-buffer-alist' window rules.
(setq switch-to-buffer-obey-display-actions t)
;; Follow compilation output only until the first error appears.
(setq compilation-scroll-output 'first-error)
(setq compilation-ask-about-save nil)   ;; save modified buffers without prompting
;; Never truncate long compiler lines (needed for verbose LSP/cabal output).
(setq compilation-max-output-line-length nil)
;; Highlight the message when jumping with `next-error'.
(setq next-error-message-highlight t)
;; Render C-h b bindings as a collapsible outline.
(setq describe-bindings-outline t)
;; Smooth, pixel-precise mouse/trackpad scrolling.
(pixel-scroll-precision-mode 1)
;; Right-click context menus in the GUI.
(context-menu-mode 1)
;; Translate ANSI color escapes in *compilation* into real faces.
(add-hook 'compilation-filter-hook #'ansi-color-compilation-filter)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UI Settings

;; Skip the splash screen; start straight in *scratch*.
(setq inhibit-startup-message t)
;; No GUI tooltips — help text goes to the echo area.
(tooltip-mode -1)
;; 10px fringes, wide enough for the flymake/diff-hl indicators configured below.
(set-fringe-mode 10)
;; Steady cursor, no blinking.
(blink-cursor-mode -1)
;; Show the column number in the mode line.
(column-number-mode)
;; Enable mouse support when running in a terminal.
(unless (display-graphic-p) (xterm-mouse-mode 1))
;; Don't scroll just to bring a tall (image/large-font) line fully into view.
(setq make-cursor-line-fully-visible nil)
;; Auto-insert the matching closing delimiter as you type.
(electric-pair-mode 1)
;; Highlight the line containing point.
(global-hl-line-mode 1)
;; Keep point on the same screen line when scrolling by pages.
(setq scroll-preserve-screen-position t)
;; Wrap long lines at word boundaries rather than mid-word.
(setq word-wrap t)
;; Screen positioninig
;; C-l cycles point to the middle, then the top of the window.
(setq recenter-positions '(middle top))
;; Scroll line by line instead of jumping and recentering.
(setq scroll-conservatively 1000)
;; Always keep 3 lines of context above/below point.
(setq scroll-margin 3)
;; Overlap of 3 lines when paging with C-v / M-v.
(setq next-screen-context-lines 3)
;; Fonts
;; Apply the configured font to new frames and to the minibuffer prompt, but only
;; if that font is actually installed on this machine.
(when (find-font (font-spec :family dk/font-family))
  (add-to-list 'default-frame-alist
               (cons 'font (format "%s-%d" dk/font-family (/ dk/font-height 10))))
  (set-face-attribute 'minibuffer-prompt nil
                      :family dk/font-family :height dk/minibuffer-font-height))
;; (set-face-attribute 'minibuffer-prompt nil :family dk/font-family :height dk/minibuffer-font-height)
;; (set-face-attribute 'default nil :family dk/font-family  :height dk/font-height)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Packages

;; Nerd Font icon set; the backend the three blocks below and doom-modeline draw from.
(use-package nerd-icons)

;; File-type icons in Dired listings.
(use-package nerd-icons-dired
  :hook (dired-mode . nerd-icons-dired-mode))

;; Kind icons (function/variable/snippet) in the corfu completion popup.
(use-package nerd-icons-corfu
  :after corfu
  :config (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

;; Doom's mode line, slimmed to 15px tall.
(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :custom ((doom-modeline-height 15)))

;; Grow the region by semantic units (keys bound in src/keys.el).
(use-package expand-region)

;; Richer *Help* buffers: source, callers, values. Takes over the C-h family and
;; adds C-g/<escape> to dismiss the window via the dk/helpful-* helpers.
(use-package helpful
  :custom
  (helpful-switch-buffer-function #'dk/helpful-open)
  :bind
  (("C-h f" . helpful-callable)
   ("C-h v" . helpful-variable)
   ("C-h k" . helpful-key)
   ("C-h x" . helpful-command)
   ("C-h C-h" . helpful-at-point)
   :map helpful-mode-map
   ("C-g" . dk/helpful-close)
   ("<escape>" . dk/helpful-close)))

;; Popup showing the available continuations of a half-typed prefix, after 0.7s.
(use-package which-key
  :config
  :init (which-key-mode)
  :custom (which-key-idle-delay 0.7))

;; Color nested parens/brackets by depth in code buffers.
(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;; Relative line numbers in code buffers, 3 columns wide and never shrinking
;; (so the text doesn't shift horizontally while scrolling).
(use-package display-line-numbers
  :hook prog-mode
  :custom
  (display-line-numbers-type 'relative)
  (display-line-numbers-width 3)
  (display-line-numbers-grow-only t))

;; Recent-file list (used by consult-recent-file): 300 remembered, 15 in the menu.
(use-package recentf
  :custom
  (recentf-max-menu-items 15)
  (recentf-max-saved-items 300)
  :init (recentf-mode))

;; Vertical minibuffer completion UI: 15 candidates, wrap-around, fixed height.
(use-package vertico
  :init (vertico-mode)
  :custom
  (vertico-count 15)
  (vertico-cycle t)
  (vertico-resize nil)
  (vertico-scroll-margin 7))

;; Path-aware editing in file prompts: RET enters a directory, M-DEL goes up one.
(use-package vertico-directory
  :ensure nil
  :after vertico
  :bind (:map vertico-map
              ("RET"   . vertico-directory-enter)
              ;; Plain commands, not the vertico-directory-* variants: those delete a
              ;; whole path component when point is right after "/", which makes
              ;; Backspace and Shift-Backspace identical at a directory boundary.
              ("DEL"   . delete-backward-char)
              ("S-<backspace>" . backward-kill-word)
              ;; Up one directory in file prompts; plain word kill everywhere else
              ("M-DEL" . vertico-directory-delete-word)))

;; Per-category Vertico tweaks; used here only to sort file prompts alphabetically.
(use-package vertico-multiform
  :ensure nil
  :after vertico
  :custom
  ;; Sort file prompts (find-file, dired, ...) by name.  Other prompts keep the
  ;; default history/length ordering.  Consult sources that declare their own
  ;; display-sort-function, e.g. consult-recent-file, are unaffected.
  (vertico-multiform-categories
   '((file (vertico-sort-function . vertico-sort-alpha))))
  :config
  (vertico-multiform-mode 1))

;; Space-separated, order-independent matching; files keep partial-completion so
;; "/u/s/b" still expands, and a leading wildcard makes prefixes optional.
(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))))
  (completion-pcm-leading-wildcard t))

;; Annotate minibuffer candidates (docstrings, file sizes, key bindings).
(use-package marginalia
  :after vertico
  :init (marginalia-mode))

;; Built-in file manager: human-readable sizes, dirs first, no confirmation for
;; recursive copy/delete, guessed target dir, and one reused buffer per session.
(use-package dired
  :ensure nil
  :commands (dired dired-jump)
  :bind (("C-x C-j" . dired-jump))
  :config
  (setq dired-listing-switches "-agho --group-directories-first"
        dired-recursive-copies 'always
        dired-recursive-deletes 'always
        dired-dwim-target t
	dired-kill-when-opening-new-dired-buffer t))

;; Colorful Dired listings (by file type and permission bits).
(use-package diredfl
  :hook (dired-mode . diredfl-mode))

;; Built-in project.el under a C-c p prefix; the extra root markers make
;; Cargo/Go/Cabal/.project trees count as projects even without VC.
(use-package project
  :ensure nil
  :bind (("C-c p f" . project-find-file)
         ("C-c p p" . project-switch-project)
         ("C-c p b" . consult-project-buffer)
         ("C-c p d" . project-find-dir)
         ("C-c p g" . consult-ripgrep))
  :custom
  (project-vc-extra-root-markers '(".project" "Cargo.toml" "go.mod" "*.cabal")))

;; Consult: previewing search/navigation commands built on completing-read.
;; Preview is instant and on any key; line numbers count from the whole buffer.
(use-package consult
  :bind  ("C-x b" . consult-buffer)           ;; Switch buffer (replaces C-x C-b)
  ("C-x 4 b" . consult-buffer-other-window)
  ("C-c C-f" . consult-find)           ;; Find file (replaces default)
  ("C-s" . consult-line)               ;; Search line in buffer
  ("C-x C-r" . consult-recent-file)    ;; Recent files
  ("C-c ?" . consult-flymake)
  ("C-c m" . consult-mode-command)
  ;; NB: no global C-r here.  `consult-history' only works in the minibuffer and
  ;; in comint buffers (bound in both maps below); globally it just errors and
  ;; costs you `isearch-backward'.
  ("M-y" . consult-yank-pop)
  ("M-s r"   . consult-ripgrep)     ; project-wide search — the big one
  ("M-s g"   . consult-grep)
  ("M-g i"   . consult-imenu)       ; you set org-imenu-depth 4 but have no imenu binding
  ("M-g I"   . consult-imenu-multi)
  ("M-g g"   . consult-goto-line)
  ("M-g m"   . consult-mark)
  ("M-'"     . consult-register-store)
  ("C-x r b" . consult-bookmark)
  (:map minibuffer-local-map ("C-r" . consult-history))
  (:map comint-mode-map      ("C-r" . consult-history))
  :custom
  (consult-preview-key 'any)              ;; Preview while typing
  (consult-preview-delay 0)               ;; No delay
  (consult-line-numbers-widen t))

;; Jump to recent/bookmarked/project directories, including from inside a file prompt.
(use-package consult-dir
  :bind (("C-x C-d" . consult-dir)
         :map vertico-map
         ("C-x C-d" . consult-dir)
         ("C-x C-j" . consult-dir-jump-file)))

;; Route the register preview through consult: formatted list after 0.5s.
(setq register-preview-delay 0.5
      register-preview-function #'consult-register-format)
(advice-add #'register-preview :override #'consult-register-window)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Coding environment
;; Plain setq rather than use-package :custom: this has to land before treesit
;; loads, and `defcustom' only sets a default when the symbol is still unbound,
;; so the value set here survives.  Run `M-x dk/treesit-install-missing' once
;; per machine to compile the grammars.
;; Where `treesit-install-language-grammar' fetches each grammar from.
(setq treesit-language-source-alist dk/treesit-languages)
;; Maximum tree-sitter fontification detail.
(setq treesit-font-lock-level 4)

;; Prefer tree-sitter major modes over the classic ones, but only where the
;; grammar is actually installed.  `treesit-language-available-p' is a C
;; primitive, so this needs no `require' and costs nothing at startup.
(dk/treesit-apply-remaps)

;; Tree-sitter modes without a classic counterpart to remap
;; File-extension bindings for ts-modes that have no legacy mode to remap from.
(add-to-list 'auto-mode-alist '("\\(?:CMakeLists\\.txt\\|\\.cmake\\)\\'" . cmake-ts-mode))
(add-to-list 'auto-mode-alist '("\\.ya?ml\\'" . yaml-ts-mode))
(add-to-list 'auto-mode-alist '("/go\\.mod\\'" . go-mod-ts-mode))

;; Built-in LSP client. Auto-starts for Haskell/C/C++/Go/Rust/Python, keeps no
;; event log, follows xref into out-of-project files, and shuts the server down
;; with the last buffer; per-server settings go in the workspace configuration.
(use-package eglot
  :ensure nil
  :hook ((haskell-mode . eglot-ensure)
         (haskell-ts-mode . eglot-ensure)
	 (c-ts-mode . eglot-ensure)
	 (c++-ts-mode . eglot-ensure)
	 (go-ts-mode . eglot-ensure)
	 (go-mode . eglot-ensure)       ; the fallback mode when the grammar is gone
	 (rust-ts-mode . eglot-ensure)
	 (python-base-mode . eglot-ensure))
  ;;(rust-mode . eglot-ensure))      ;; Rustic is enabled
  :config
  ;; Signature/type echo in every programming buffer, LSP-backed or not.
  (add-hook 'prog-mode-hook 'eldoc-mode)
  (setq eglot-events-buffer-config '(:size 0))
  (setq eglot-extend-to-xref t)             ; start eglot for cross-referenced files
  (setq eglot-autoshutdown t)               ; new: kill the server with the last buffer
  ;; `eglot-sync-connect' deliberately keeps its default of 3.  With nil,
  ;; opening a file never waits at all, and every jump attempted before the
  ;; server answers `initialize' falls through to the etags backend — which is
  ;; how M-. ends up asking for a TAGS file instead of jumping.  See also
  ;; `dk/xref-wait-for-eglot', which covers the rest of that window.
  ;; Advertise available code actions as an eldoc hint plus a margin marker.
  (setq eglot-code-actions-indications '(eldoc-hint margin))
  ;; Server-side options: fourmolu for Haskell formatting, staticcheck and extra
  ;; analyzers for gopls.
  (setq-default eglot-workspace-configuration
		'(:haskell (:formattingProvider "fourmolu")
		  :gopls   (:staticcheck t
			    :usePlaceholders t
			    :analyses (:unusedparams t :nilness t :shadow t)))))

;; Which binary to launch per language, plus a filter that tidies the Markdown
;; HLS returns before it reaches eldoc.
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

;; one line in the echo area, full docs in a dedicated buffer on demand
(setq eldoc-echo-area-use-multiline-p 1)
(setq eldoc-echo-area-prefer-doc-buffer t)
;; Compose all documentation sources at once instead of taking the first hit.
(setq eldoc-documentation-strategy #'eldoc-documentation-compose-eagerly)

;; Cross-references through the consult UI (previewable candidate list), with the
;; standard M-. / M-? / M-, jump keys.
(use-package xref
  :ensure nil
  :config
  (setq xref-show-xrefs-function       #'consult-xref)
  (setq xref-show-definitions-function #'consult-xref)
  :bind (("M-."   . xref-find-definitions)
         ("M-?"   . xref-find-references)
         ("M-,"   . xref-go-back)
         ("C-M-." . xref-find-apropos)))

;; Advise the commands, not the backend: `xref-backend-functions' is consulted
;; the moment M-. runs, so the server has to be up before that, not after.
(advice-add 'xref-find-definitions :before #'dk/xref-wait-for-eglot)
(advice-add 'xref-find-references  :before #'dk/xref-wait-for-eglot)



;; Workspace-wide LSP symbol search.  consult-imenu covers the current buffer
;; and xref jumps from an existing reference; this is the "find SYMBOL anywhere
;; in the project by name" case neither of those handles.
(use-package consult-eglot
  :after (consult eglot)
  :bind (:map eglot-mode-map
              ("M-g s" . consult-eglot-symbols)))

;; Header line: project -> file -> enclosing function.  Uses LSP where a server
;; is running, imenu otherwise, so it also works in Elisp and plain buffers.
(use-package breadcrumb
  :hook (prog-mode . breadcrumb-local-mode))

;; Context menu of actions for the thing at point or the current candidate.
(use-package embark
  :bind (("C-." . embark-act)         ;; act on thing at point
         ("C-;" . embark-dwim)        ;; do what I mean
         ("C-h B" . embark-bindings)))

;; Bridges embark and consult: exported candidate buffers get consult previews.
(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;; Built-in on-the-fly diagnostics in all code buffers, M-n/M-p to walk errors,
;; rechecked 0.5s after typing stops and on save, with custom fringe bitmaps.
(use-package flymake
  :ensure nil  ;; built-in
  :hook (prog-mode . flymake-mode)  ;; enable in all prog modes
  :bind (:map flymake-mode-map
              ("M-n" . flymake-goto-next-error)
              ("M-p" . flymake-goto-prev-error))
  :config
  (setq flymake-no-changes-timeout 0.5)  ;; recheck after 0.5s idle
  (setq flymake-start-on-flymake-mode t)
  (setq flymake-start-on-save-buffer t)

  ;; Show error diagnostics in the fringe
  (setq flymake-fringe-indicator-position 'left-fringe)

  ;; Pretty fringe indicators
  ;; Bar width encodes severity: thick = error, medium = warning, thin = note.
  (define-fringe-bitmap 'flymake-error-indicator
    [#b11100000] nil nil '(center repeated))
  (define-fringe-bitmap 'flymake-warning-indicator
    [#b01100000] nil nil '(center repeated))
  (define-fringe-bitmap 'flymake-note-indicator
    [#b00100000] nil nil '(center repeated)))

;; Bind the bitmaps above to the three severities, each with a matching face.
(setq flymake-error-bitmap   '(flymake-error-indicator   compilation-error)
      flymake-warning-bitmap '(flymake-warning-indicator compilation-warning)
      flymake-note-bitmap    '(flymake-note-indicator    compilation-info))

;; In-buffer completion popup, auto-triggered after 2 chars / 0.2s, with docs on
;; M-d; TAB both indents and completes, and history/popupinfo modes are enabled.
(use-package corfu
  :custom
  (tab-always-indent 'complete)     ; TAB indents, then completes
  (completion-cycle-threshold 3)
  (corfu-cycle t)                   ;; TAB cycles candidates
  (corfu-auto t)                    ;; auto-popup completion
  (corfu-auto-delay 0.2)            ;; delay before auto popup
  (corfu-auto-prefix 2)             ;; minimum prefix length for auto
  (corfu-popupinfo-delay 0.5)       ;; delay for doc popup
  (corfu-preview-current t)         ;; preview current candidate
  (corfu-on-exact-match nil)        ;; don't auto-insert on exact match
  (corfu-quit-at-boundary 'separator) ;; quit at boundary
  (corfu-quit-no-match t)           ;; quit if no match
  (corfu-separator ?\s)             ;; space is separator (for LSP)
  (corfu-scroll-margin 5)           ;; scroll margin
  (corfu-preselect :first)
  :bind
  (:map corfu-map
        ("TAB"     . corfu-insert)
        ("RET"     . nil)
        ("M-d"     . corfu-popupinfo-toggle) ;; toggle doc popup
        ("C-g"     . corfu-quit)
        ("M-l"     . corfu-show-location))   ;; go to definition
  :init
  (global-corfu-mode 1)
  (corfu-popupinfo-mode 1)
  (corfu-history-mode 1))   ;; makes the savehist corfu-history entry actually work

;; Extra completion-at-point sources: file paths and dabbrev words (min. 3 chars),
;; appended after the mode's own capf so LSP candidates still come first.
(use-package cape
  :init
  (add-hook 'completion-at-point-functions #'cape-file 10)
  (add-hook 'completion-at-point-functions #'cape-dabbrev 20)
  :custom (cape-dabbrev-min-length 3))

;; Folding driven by the tree-sitter parse tree; only active in ts-modes, which
;; now includes Haskell.  `global-treesit-fold-mode' no-ops where no parser is
;; running, so it is safe to enable everywhere.
(use-package treesit-fold
  :init (global-treesit-fold-mode 1)
  :bind (("C-c f" . treesit-fold-toggle)
         ("C-c F" . treesit-fold-close-all)))

;; Format-on-save via external formatters, globally. The inhibit function skips
;; C/C++ buffers with no project formatter config; haskell-ts-mode maps to fourmolu.
(use-package apheleia
  :init (apheleia-global-mode +1)
  :config
  (add-hook 'apheleia-inhibit-functions #'dk/apheleia-inhibit-unconfigured-c)
  ;; apheleia ships a haskell-mode entry but not one for the ts-mode.
  (setf (alist-get 'haskell-ts-mode apheleia-mode-alist) 'fourmolu))

;; Edit grep results in place and write them back to the files; C-c C-p to start.
(use-package wgrep
  :custom (wgrep-auto-save-buffer t)
  :bind (:map grep-mode-map ("C-c C-p" . wgrep-change-to-wgrep-mode)))

;; Visual undo tree on C-c u, drawn with Unicode box glyphs.
(use-package vundo
  :bind ("C-c u" . vundo)
  :custom (vundo-glyph-alist vundo-unicode-symbols))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Version control

;; Full Git porcelain: C-x g for the status buffer, C-c g for file-local actions;
;; diffs are refined word-by-word on both sides of a hunk.
(use-package magit
  :bind (("C-x g" . magit-status)
         ("C-c g" . magit-file-dispatch))
  :custom (magit-diff-refine-hunk 'all))

;; Uncommitted-change markers in the fringe (and in Dired), kept in sync with
;; Magit refreshes and updated live from the unsaved buffer via flydiff.
(use-package diff-hl
  :hook ((prog-mode  . diff-hl-mode)
         (dired-mode . diff-hl-dired-mode)
         (magit-pre-refresh  . diff-hl-magit-pre-refresh)
         (magit-post-refresh . diff-hl-magit-post-refresh))
  :config
  (diff-hl-flydiff-mode 1))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Langauge specific settings

;; haskell-ts-mode owns `.hs'; haskell-mode stays installed because it supplies
;; `haskell-compile' and the interactive cabal-repl session, which the ts-mode
;; has no equivalent for.  Both are listed in `eglot-server-programs' below.
;; Loaded lazily, only when one of those commands is invoked; the REPL is `cabal repl'.
(use-package haskell-mode
  :defer t
  :commands (haskell-compile haskell-interactive-switch haskell-process-load-file)
  :config
  (setq haskell-process-type 'cabal-repl))

;; The tree-sitter Haskell mode used for editing, wired to the borrowed
;; haskell-mode REPL/compile commands and to dk/haskell-setup.
(use-package haskell-ts-mode
  :mode ("\\.hs\\'" . haskell-ts-mode)
  :hook (haskell-ts-mode . dk/haskell-setup)
  :bind
  (:map haskell-ts-mode-map
	("C-c C-l" . haskell-process-load-file)
	("C-c C-z" . haskell-interactive-switch)
	;; Whole-project `cabal build' into compilation-mode, so next-error
	;; works across the build.  The repl alone cannot do that.
	("C-c C-c" . haskell-compile)))

;; Classic Go mode; kept as the fallback when the go tree-sitter grammar is absent.
(use-package go-mode
  :mode "\\.go\\'")

;; Built-in tree-sitter Rust mode, with rust-analyzer started on open.
(use-package rust-ts-mode
  :ensure nil
  :mode "\\.rs\\'"
  :hook (rust-ts-mode . eglot-ensure))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Markdown mode

;; GitHub-flavored Markdown with concealed markup/URLs, scaled headings, native
;; code-block fontification, math, pretty bullets, and pandoc for previews.
(use-package markdown-mode
  ;; GFM everywhere: tables, strikethrough, checkboxes, ``` fences
  :mode (("\\.md\\'"       . gfm-mode)
         ("\\.markdown\\'" . gfm-mode)
         ("README\\.md\\'" . gfm-mode))
  :hook (markdown-mode . dk/prose-setup)
  :custom
  (markdown-command '("pandoc" "--from=gfm" "--to=html5" "--standalone"))
  (markdown-header-scaling t)
  (markdown-hide-markup t)                  ;; set it, never toggle it in a hook
  (markdown-hide-urls t)                    ;; [text](url) -> text ⚓
  (markdown-fontify-code-blocks-natively t)
  (markdown-fontify-whole-heading-line t)
  (markdown-enable-math t)
  (markdown-enable-highlighting-syntax t)
  (markdown-asymmetric-header t)
  (markdown-list-item-bullets '("•" "◦" "▪" "▫"))
  :bind (:map markdown-mode-map
              ("C-c C-e"  . markdown-do)
              ("C-c C-v"  . gfm-view-mode)  ;; read-only fully-rendered view
              ("M-<up>"   . markdown-move-up)
              ("M-<down>" . markdown-move-down)))

;; Pixel-align Markdown/Org tables so variable-width fonts and CJK still line up.
(use-package valign
  :hook ((markdown-mode org-mode) . valign-mode)
  :custom (valign-fancy-bar t))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ORG mode

;; Org: agenda reads ~/org, DONE gets a timestamp in a LOGBOOK drawer, and the
;; rest tunes rendering, source blocks and editing safety (grouped inline below).
(use-package org
  :ensure nil
  :hook (org-mode . dk/prose-setup)
  :custom
  (org-agenda-files (list "~/org"))
  (org-log-done 'time)
  (org-log-into-drawer t)
  ;; Rendering
  (org-startup-indented t)                       ;; virtual indent, no leading stars
  (org-hide-emphasis-markers t)                  ;; /italic/ -> italic
  (org-pretty-entities t)                        ;; \alpha -> α
  (org-pretty-entities-include-sub-superscripts t)
  (org-ellipsis " ▾")
  (org-fontify-quote-and-verse-blocks t)
  (org-fontify-whole-heading-line t)
  (org-startup-with-inline-images t)
  (org-image-actual-width '(600))
  ;; Source blocks
  (org-src-fontify-natively t)
  (org-src-tab-acts-natively t)
  (org-edit-src-content-indentation 0)
  (org-src-preserve-indentation t)
  ;; Editing behaviour
  (org-catch-invisible-edits 'show-and-error)    ;; never silently edit folded text
  (org-return-follows-link t)
  (org-insert-heading-respect-content t)
  (org-auto-align-tags nil)                      ;; let org-modern place tags
  (org-tags-column 0)
  (org-imenu-depth 4))

;; Modern Org look: replaced stars, styled blocks/tags, Unicode list bullets.
(use-package org-modern
  :hook (org-mode . org-modern-mode)
  :custom
  (org-modern-table nil)          ;; valign owns tables — don't run both
  (org-modern-star 'replace)      ;; ◉ ○ ◈ instead of ***; 'fold for folding indicators
  (org-modern-hide-stars 'leading)
  (org-modern-block-fringe nil)   ;; set nil unless you enable fringes in org
  (org-modern-list '((?- . "–") (?+ . "•") (?* . "‣"))))

;; Reveal the hidden markup (emphasis, links, entities, sub/superscripts) of
;; whatever element point is on, with no delay.
(use-package org-appear
  :hook (org-mode . org-appear-mode)
  :custom
  (org-appear-autoemphasis t)
  (org-appear-autolinks t)
  (org-appear-autosubmarkers t)
  (org-appear-autoentities t)
  (org-appear-delay 0.0))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Theme settings

;; Re-apply the custom face tweaks in functions.el whenever a theme is enabled.
(add-hook 'enable-theme-functions #'dk/theme-hook)
;; Load themes without the "is this safe?" prompt.
(setq custom-safe-themes t)
;; Theme collections kept installed to switch between; only one is loaded.
(use-package doom-themes)
(use-package ef-themes)
(use-package gruvbox-theme)
(use-package spacemacs-theme)
;; The active theme (ships in ./themes/, hence the load path added at the top).
(load-theme 'gruber-darker)

;; Keep Customize's generated code in custom.el instead of appending to init.el.
(setopt custom-file (locate-user-emacs-file "custom.el"))
(when (file-exists-p custom-file)
  (load custom-file))

;; Feature name matches this file, so requiring it can't shadow the real init.
(provide 'init_)
;;; init_.el ends here
