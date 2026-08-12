;; -*- lexical-binding: t; -*-

;;; Language-agnostic programming support
;;
;; LSP, diagnostics, formatting and the prog-mode display bits.
;; Per-language settings (servers, modes, hooks) live in dk-languages.el.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display in code buffers
;; Line numbers in code buffers only -- prose and special buffers stay clean.
(use-package display-line-numbers
  :ensure nil                           ; built-in
  :hook prog-mode
  :custom
  ;; Distance from the current line rather than absolute numbers, so a motion
  ;; like M-8 C-n can be read straight off the margin.  The current line still
  ;; shows its own absolute number.
  (display-line-numbers-type 'relative)
  (display-line-numbers-width 3)        ; reserve 3 columns, so the text doesn't shift
  (display-line-numbers-grow-only t))   ; ...and never shrink the margin back

;; Nested brackets coloured by depth, which is how a missing paren gets spotted.
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
         ;; rust is started by rustic, see dk-languages.el
         (go-ts-mode      . eglot-ensure))
  ;; No (prog-mode . eldoc-mode) here: `global-eldoc-mode' is on by default in
  ;; Emacs 30, so that hook was re-enabling a mode that was already on.
  :config
  ;; Stop logging every JSON message to *EGLOT events*.  That buffer is a
  ;; debugging aid only, and keeping it costs memory in a long session.  Set a
  ;; size back if a server ever needs to be debugged.
  (setq eglot-events-buffer-config '(:size 0))
  ;; Keep the server managing a file reached by M-. that lies outside the
  ;; project (a dependency's source), instead of opening it unmanaged.
  (setq eglot-extend-to-xref t)
  ;; Shut the server down once its last managed buffer is killed.  Off by
  ;; default, and in a normal Emacs session that default is fine -- quitting
  ;; Emacs reaps the servers.  This one runs as a daemon, which never quits, so
  ;; without this a server outlives every buffer of its project and is only
  ;; reclaimed by restarting the daemon.  With HLS and rust-analyzer in the mix
  ;; that is a lot of resident memory held for projects closed hours ago.
  ;; The cost is a cold restart on the next visit; `dk/xref-wait-for-eglot'
  ;; covers the part of that which used to look like broken navigation.
  (setq eglot-autoshutdown t)
  ;; Haskell servers wrap their docs in ```haskell fences; strip them so the
  ;; eldoc buffer shows plain text.
  (advice-add 'eglot--format-markup
              :filter-args #'dk/eglot-clean-haskell-markdown))

;; NOTE: `eglot-put-doc-in-buffer' and `eglot-code-actions-indications' were
;; set here before, but neither exists in the eglot shipped with Emacs 30.2 —
;; they were setting variables nothing ever reads.  Re-add on Emacs 31+.

;; Code navigation.  These are the stock bindings, restated so they are not
;; quietly taken over by a package -- with eglot running they are answered by
;; the language server, and fall back to etags/elisp elsewhere.
(use-package xref
  :ensure nil                           ; built-in
  :bind (("M-."   . xref-find-definitions)
         ("M-?"   . xref-find-references)
         ("M-,"   . xref-go-back)         ; back to where M-. was pressed
         ("C-M-." . xref-find-apropos)))  ; definitions matching a pattern

;; A jump made in the first moments after opening a file would otherwise fall
;; through to the etags backend, because eglot has not finished connecting and
;; the buffer is not managed yet -- see `dk/xref-wait-for-eglot'.  Plain
;; `advice-add' rather than `define-advice': these are commands from a built-in
;; library, and the advice has to be in place before the first jump, not after
;; xref's `use-package' happens to load.
(advice-add 'xref-find-definitions :before #'dk/xref-wait-for-eglot)
(advice-add 'xref-find-references  :before #'dk/xref-wait-for-eglot)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Diagnostics
;; On-the-fly diagnostics.  eglot registers itself as a flymake backend, so in
;; an LSP buffer these are the server's errors; elsewhere it is whatever backend
;; the mode provides (elisp byte-compile, shellcheck, ...).
(use-package flymake
  :ensure nil                           ; built-in
  :hook (prog-mode . flymake-mode)
  :bind (:map flymake-mode-map
              ("M-n" . flymake-goto-next-error)
              ("M-p" . flymake-goto-prev-error))
  :config
  (setq flymake-no-changes-timeout 0.5) ; recheck after 0.5s idle
  (setq flymake-start-on-flymake-mode t) ; check immediately, don't wait for an edit
  (setq flymake-start-on-save-buffer t)  ; and again on every save

  ;; Diagnostics are marked in the left fringe.  The bitmaps below replace the
  ;; stock arrow/dot glyphs with plain vertical bars of decreasing width:
  ;; 3px for an error, 2px for a warning, 1px for a note.  Each bitmap is one
  ;; row and '(center repeated) tiles it down the height of the line.
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
