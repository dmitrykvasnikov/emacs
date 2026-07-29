;; -*- lexical-binding: t; -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; User settings and variables
(setq-default user-full-name "Dmitry Kvasnikov"
	      user-mail-address "dmitry.kvasnikov@gmail.com")

;; Config load paths and load external files
(dk/add-paths-to-list 'load-path '("src") t)
(dk/add-paths-to-list 'custom-theme-load-path '("themes/") t)
(load "vars.el" nil t)
(load "functions.el" nil t)
(load "keymap.el" nil t)
(setopt custom-file (locate-user-emacs-file "custom.el"))
(when (file-exists-p custom-file)
  (load custom-file))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Package settings
(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
			 ("org" . "https://orgmode.org/elpa/")
			 ("elpa" . "https://elpa.gnu.org/packages/")
			 ("nongnu" . "https://elpa.nongnu.org/nongnu/")))
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))
;; Initialize use-package on non-Linux platforms
(unless (package-installed-p 'use-package)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Common settings
(setq use-short-answers t)
(setq make-backup-files nil)         ;; do not make backup files
(setq create-lockfiles nil)
(setq auto-save-dir dk/auto-save-dir)
(make-directory auto-save-dir t)
(setq auto-save-file-name-transforms
      `((".*" ,auto-save-dir t)))
(setq vc-follow-symlinks t)		;; Follow symlinks without confirmation
(setq delete-by-moving-to-trash (not noninteractive))
(setq visible-bell nil)
(setq ring-bell-function #'ignore)
(delete-selection-mode t)
(savehist-mode 1)
(save-place-mode 1)
(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers 1)
(setq auto-revert-verbose nil)
(repeat-mode 1)
(winner-mode 1)
(setq undo-limit (* 13 160000)
      undo-strong-limit (* 13 240000)
      undo-outer-limit (* 13 24000000))
(setq initial-scratch-message ";; He who walks alone  ... Always walks uphill but ... Beneath his feet are the ... Broken bones of flawed men ...\n\n")
;; Search settings
(setq isearch-allow-scroll t)
(setq isearch-lazy-count t)
(setq isearch-wrap-pause 'no-ding)
(setq isearch-repeat-on-direction-change t)
(setq enable-recursive-minibuffers t)
(minibuffer-depth-indicate-mode 1)
(setq read-process-output-max (* 4 1024 1024))
(setq process-adaptive-read-buffering nil)
(setq read-extended-command-predicate #'command-completion-default-include-p)
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UI Settings
(setq inhibit-startup-message t)
(tooltip-mode -1)
(set-fringe-mode 10)
(blink-cursor-mode -1)
(column-number-mode)
(unless (display-graphic-p) (xterm-mouse-mode 1))
(setq make-cursor-line-fully-visible nil)
(electric-pair-mode 1)
(global-hl-line-mode 1)
(setq scroll-preserve-screen-position t)
(setq word-wrap t)
;; Screen positioninig
(setq recenter-positions '(middle top))
(setq scroll-conservatively 1000)
(setq scroll-margin 3)
(setq next-screen-context-lines 3)
;; Fonts
(when (find-font (font-spec :family dk/font-family))
  (add-to-list 'default-frame-alist
               (cons 'font (format "%s-%d" dk/font-family (/ dk/font-height 10))))
  (set-face-attribute 'minibuffer-prompt nil
                      :family dk/font-family :height dk/minibuffer-font-height))
;; (set-face-attribute 'minibuffer-prompt nil :family dk/font-family :height dk/minibuffer-font-height)
;; (set-face-attribute 'default nil :family dk/font-family  :height dk/font-height)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Packages
;; (use-package all-the-icons)

(use-package nerd-icons)

(use-package nerd-icons-dired
  :hook (dired-mode . nerd-icons-dired-mode))

(use-package nerd-icons-corfu
  :after corfu
  :config (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :custom ((doom-modeline-height 15)))

(use-package expand-region)

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

(use-package which-key
  :config
  :init (which-key-mode)
  :custom (which-key-idle-delay 0.7))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package display-line-numbers
  :hook prog-mode
  :custom
  (display-line-numbers-type 'relative)
  (display-line-numbers-width 3)
  (display-line-numbers-grow-only t))

(use-package recentf
  :custom
  (recentf-max-menu-items 15)
  (recentf-max-saved-items 300)
  :init (recentf-mode))

(use-package vertico
  :init (vertico-mode)
  :custom
  (vertico-count 15)
  (vertico-cycle t)
  (vertico-resize nil)
  (vertico-scroll-margin 7))

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

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))))
  (completion-pcm-leading-wildcard t))

(use-package marginalia
  :after vertico
  :init (marginalia-mode))

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

(use-package diredfl
  :hook (dired-mode . diredfl-mode))

;; (use-package all-the-icons-dired
;;   :hook (dired-mode . all-the-icons-dired-mode))

(use-package projectile
  :init
  (setq projectile-auto-discover t)
  (setq projectile-track-known-projects-automatically t)  ; Auto-add projects
  (setq projectile-cache-file (expand-file-name "projectile.cache" user-emacs-directory))
  (projectile-mode +1)
  ;; Basic settings
  (setq projectile-completion-system 'default)
  (setq projectile-indexing-method 'alien)       ; Faster on Unix (Linux/Mac)
  :bind
  (:map projectile-mode-map
	("C-c p" . projectile-command-map)))

(with-eval-after-load 'projectile
  (add-to-list 'projectile-globally-ignored-buffers "*projectile-files-errors*")
  (add-to-list 'projectile-globally-ignored-buffers "EGLOT*"))

(use-package consult
  :bind  ("C-x b" . consult-buffer)           ;; Switch buffer (replaces C-x C-b)
  ("C-x 4 b" . consult-buffer-other-window)
  ("C-c C-f" . consult-find)           ;; Find file (replaces default)
  ("C-s" . consult-line)               ;; Search line in buffer
  ("C-x C-r" . consult-recent-file)    ;; Recent files
  ("C-c ?" . consult-flymake)
  ("C-c m" . consult-mode-command)
  ("C-r" . consult-history)            ;; Minibuffer history
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

;; (consult-customize
;;  consult-ripgrep consult-git-grep consult-grep consult-recent-file
;;  consult-source-recent-file consult-source-project-recent-file
;;  consult-source-bookmark
 ;; :preview-key '(:debounce 0.3 any))

(setq register-preview-delay 0.5
      register-preview-function #'consult-register-format)
(advice-add #'register-preview :override #'consult-register-window)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Coding environment
(use-package treesit
  :ensure nil
  :defer t
  :custom
  (treesit-font-lock-level 4)
  (treesit-language-soource-alist dk/treesit-languages))

;; Prefer tree-sitter major modes over the classic ones
(setq major-mode-remap-alist
      '((c-mode . c-ts-mode)
	(c++-mode . c++-ts-mode)
	(c-or-c++-mode . c-or-c++-ts-mode)
	(python-mode . python-ts-mode)
	(sh-mode . bash-ts-mode)
	(js-json-mode . json-ts-mode)
	(conf-toml-mode . toml-ts-mode)
        (rust-mode . rust-ts-mode)
        (go-mode . go-ts-mode)))

;; Tree-sitter modes without a classic counterpart to remap
(add-to-list 'auto-mode-alist '("\\(?:CMakeLists\\.txt\\|\\.cmake\\)\\'" . cmake-ts-mode))
(add-to-list 'auto-mode-alist '("\\.ya?ml\\'" . yaml-ts-mode))

(use-package eglot
  :ensure nil
  :hook ((haskell-mode . eglot-ensure)
         (haskell-ts-mode . eglot-ensure)
	 (c-ts-mode . eglot-ensure)
	 (c++-ts-mode . eglot-ensure)
	 (go-ts-mode . eglot-ensure)
	 (rust-ts-mode . eglot-ensure)
	 (python-base-mode . eglot-ensure))
  ;;(rust-mode . eglot-ensure))      ;; Rustic is enabled
  :config
  (add-hook 'prog-mode-hook 'eldoc-mode)
  (setq eglot-events-buffer-config '(:size 0))
  (setq eglot-extend-to-xref t)             ; start eglot for cross-referenced files
  (setq eglot-autoshutdown t)               ; new: kill the server with the last buffer
  (setq eglot-sync-connect nil)             ; new: don't block on server startup
  (setq eglot-code-actions-indications '(eldoc-hint margin))
  (setq-default eglot-workspace-configuration
		'(:haskell (:formattingProvider "fourmolu"))))

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
(setq eldoc-documentation-strategy #'eldoc-documentation-compose-eagerly)

(use-package xref
  :ensure nil
  :config
  (setq xref-show-xrefs-function       #'consult-xref)
  (setq xref-show-definitions-function #'consult-xref)
  :bind (("M-."   . xref-find-definitions)
         ("M-?"   . xref-find-references)
         ("M-,"   . xref-go-back)
         ("C-M-." . xref-find-apropos)))



(use-package embark
  :bind (("C-." . embark-act)         ;; act on thing at point
         ("C-;" . embark-dwim)        ;; do what I mean
         ("C-h B" . embark-bindings)))

(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

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
  (define-fringe-bitmap 'flymake-error-indicator
    [#b11100000] nil nil '(center repeated))
  (define-fringe-bitmap 'flymake-warning-indicator
    [#b01100000] nil nil '(center repeated))
  (define-fringe-bitmap 'flymake-note-indicator
    [#b00100000] nil nil '(center repeated)))

(setq flymake-error-bitmap   '(flymake-error-indicator   compilation-error)
      flymake-warning-bitmap '(flymake-warning-indicator compilation-warning)
      flymake-note-bitmap    '(flymake-note-indicator    compilation-info))

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
  (corfu-popupinfo-mode 1))

;; Corfu in terminal (uses popon instead of child frames)
;; (use-package corfu-terminal
;;   :after corfu
;;   :config
;;   (unless (display-graphic-p)
;;(corfu-terminal-mode 1)

(use-package cape
  :init
  (add-hook 'completion-at-point-functions #'cape-file 10)
  (add-hook 'completion-at-point-functions #'cape-dabbrev 20)
  :custom (cape-dabbrev-min-length 3))

(use-package consult-projectile
  :after projectile
  :bind
  (("C-c p f" . consult-projectile-find-file)
   ("C-c p p" . consult-projectile-switch-project)
   ("C-c p b" . consult-projectile-switch-to-buffer)
   ("C-c p d" . consult-projectile-find-dir))
  :config
  (setq consult-projectile-function #'consult-projectile))

(use-package apheleia
  :init (apheleia-global-mode +1)
  :config (add-hook 'apheleia-inhibit-functions #'dk/apheleia-inhibit-unconfigured-c))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Version control
(use-package magit
  :bind (("C-x g" . magit-status)
         ("C-c g" . magit-file-dispatch))
  :custom (magit-diff-refine-hunk 'all))

(use-package diff-hl                       ; fringe git indicators
  :hook ((prog-mode . diff-hl-mode)
         (dired-mode . diff-hl-dired-mode)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Langauge specific settings

(use-package haskell-mode
  :mode ("\\.hs\\'" . haskell-mode)
  :hook ((haskell-mode . haskell-indentation-mode))
  ;; (haskell-mode . dk/haskell-setup))
  :bind
  (:map haskell-mode-map
	("C-c C-l" . haskell-process-load-file)
	("C-c C-z" . haskell-interactive-switch)
	("C-c C-t" . haskell-mode-show-type-at))
  :config
  (setq haskell-process-type 'cabal-repl))

(add-hook 'haskell-mode-hook
          (lambda ()
            ;; Disable the old school doc mode so it doesn't fight with Eglot
            (haskell-doc-mode -1)))
;; Start eglot automatically (optional, if you haven't already)
;; (eglot-ensure)))

;; (use-package rust-mode)

(use-package go-mode
  :mode "\\.go\\'")

(use-package rust-ts-mode
  :ensure nil
  :mode "\\.rs\\'"
  :hook (rust-ts-mode . eglot-ensure))

;; (add-hook 'go-mode-hook
;; 	  (lambda()
;; 	    (add-hook 'before-save-hook #'gofmt-before-save nil t)))

;; (use-package rustic
;;   :custom
;;   (rustic-lsp-client 'eglot)
;;   :hook
;; (rustic-mode . eglot-ensure))
;; :config
;; (setq rustic-format-on-save t))

;; (use-package clang-format
;;   :hook ((c-ts-mode c-mode c++-ts-mode c++-mode) . dk/clang-fos))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Markdown mode
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

(use-package valign
  :hook ((markdown-mode org-mode) . valign-mode)
  :custom (valign-fancy-bar t))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ORG mode
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

(use-package org-modern
  :hook (org-mode . org-modern-mode)
  :custom
  (org-modern-table nil)          ;; valign owns tables — don't run both
  (org-modern-star 'replace)      ;; ◉ ○ ◈ instead of ***; 'fold for folding indicators
  (org-modern-hide-stars 'leading)
  (org-modern-block-fringe nil)   ;; set nil unless you enable fringes in org
  (org-modern-list '((?- . "–") (?+ . "•") (?* . "‣"))))

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
(add-hook 'enable-theme-functions #'dk/theme-hook)
(setq custom-safe-themes t)
(use-package doom-themes)
(use-package ef-themes)
(use-package gruvbox-theme)
(use-package spacemacs-theme)
(load-theme 'gruber-darker)

(provide 'init)
;;; init.el ends here
