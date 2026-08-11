;; -*- lexical-binding: t; -*-

;;; Language-agnostic programming support
;;
;; LSP, diagnostics, formatting and the prog-mode display bits.
;; Per-language settings (servers, modes, hooks) live in dk-languages.el.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display in code buffers
(use-package display-line-numbers
  :ensure nil                           ; built-in
  :hook prog-mode
  :custom
  (display-line-numbers-type 'relative)
  (display-line-numbers-width 3)
  (display-line-numbers-grow-only t))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; LSP
(use-package eglot
  :ensure nil                           ; built-in
  ;; Only the tree-sitter modes are listed: dk-treesit.el remaps c-mode,
  ;; c++-mode and go-mode onto them, so the classic hooks would never run.
  ;; Haskell is the exception -- it stays on haskell-mode by default and
  ;; `dk/haskell-toggle-ts' switches it, so both are named.  A parent mode's
  ;; hook does not run for its children here: haskell-ts-mode registers
  ;; haskell-mode via `derived-mode-add-parents', which teaches
  ;; `derived-mode-p' about the relation but does not chain the hooks.
  :hook ((haskell-mode    . eglot-ensure)
         (haskell-ts-mode . eglot-ensure)
         (c-ts-mode       . eglot-ensure)
         (c++-ts-mode     . eglot-ensure)
         (go-ts-mode      . eglot-ensure)
         ;; rust is started by rustic, see dk-languages.el
         (prog-mode       . eldoc-mode))
  :config
  (setq eglot-events-buffer-config '(:size 0))
  (setq eglot-extend-to-xref t)         ; start eglot for cross-referenced files
  ;; Haskell servers wrap their docs in ```haskell fences; strip them so the
  ;; eldoc buffer shows plain text.
  (advice-add 'eglot--format-markup
              :filter-args #'dk/eglot-clean-haskell-markdown))

;; NOTE: `eglot-put-doc-in-buffer' and `eglot-code-actions-indications' were
;; set here before, but neither exists in the eglot shipped with Emacs 30.2 —
;; they were setting variables nothing ever reads.  Re-add on Emacs 31+.

(use-package xref
  :ensure nil                           ; built-in
  :bind (("M-."   . xref-find-definitions)
         ("M-?"   . xref-find-references)
         ("M-,"   . xref-go-back)
         ("C-M-." . xref-find-apropos)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Diagnostics
(use-package flymake
  :ensure nil                           ; built-in
  :hook (prog-mode . flymake-mode)
  :bind (:map flymake-mode-map
              ("M-n" . flymake-goto-next-error)
              ("M-p" . flymake-goto-prev-error))
  :config
  (setq flymake-no-changes-timeout 0.5) ; recheck after 0.5s idle
  (setq flymake-start-on-flymake-mode t)
  (setq flymake-start-on-save-buffer t)

  ;; Show error diagnostics in the fringe
  (setq flymake-fringe-indicator-position 'left-fringe)
  (define-fringe-bitmap 'flymake-error-indicator
    [#b11100000] nil nil '(center repeated))
  (define-fringe-bitmap 'flymake-warning-indicator
    [#b01100000] nil nil '(center repeated))
  (define-fringe-bitmap 'flymake-note-indicator
    [#b00100000] nil nil '(center repeated)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Formatting on save.  apheleia is the *only* formatter: `apheleia-mode-alist'
;; already covers every mode used here, ts modes included, and the per-language
;; `before-save-hook' formatters that used to sit alongside it in
;; dk-languages.el (gofmt, clang-format) plus `rustic-format-on-save' were all
;; running a second time over the same buffer.
(use-package apheleia
  :init (apheleia-global-mode +1)
  :config
  ;; clang-format only where the tree actually asks for it
  (add-to-list 'apheleia-inhibit-functions #'dk/no-clang-format-p))

(provide 'dk-programming)
;;; dk-programming.el ends here
