;; -*- lexical-binding: t; -*-

;;; Language-agnostic programming support
;;
;; LSP, diagnostics, formatting and the prog-mode display bits.
;; Per-language settings (servers, modes, hooks) live in dk-languages.el.

(require 'dk-functions)                 ; `dk/xref-wait-for-eglot', `dk/apheleia-inhibit-p'

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

;; Re-evaluate the whole buffer -- only where the buffer *is* Emacs Lisp.  A
;; global binding read Markdown, C or shell files as Lisp on a stray C-c e.
;; `lisp-interaction-mode-map' (*scratch*) does not inherit from
;; `emacs-lisp-mode-map', so it is named too.
(use-package elisp-mode
  :ensure nil                           ; built-in
  :bind ((:map emacs-lisp-mode-map
               ("C-c e" . eval-buffer))
         (:map lisp-interaction-mode-map
               ("C-c e" . eval-buffer))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; LSP
(use-package eglot
  :ensure nil                           ; built-in
  ;; Include classic C/C++ modes for machines without their grammars.
  ;; Haskell is the exception -- it stays on haskell-mode by default and
  ;; `dk/haskell-toggle-ts' switches it, so both are named.  A parent mode's
  ;; hook does not run for its children here: haskell-ts-mode registers
  ;; haskell-mode via `derived-mode-add-parents', which teaches
  ;; `derived-mode-p' about the relation but does not chain the hooks.
  :hook ((haskell-mode    . eglot-ensure)
         (haskell-ts-mode . eglot-ensure)
         (c-mode          . eglot-ensure)
         (c++-mode        . eglot-ensure)
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
  (add-hook 'eglot-server-initialized-hook #'dk/eglot-server-initialized)
  (add-hook 'eglot-managed-mode-hook #'dk/eglot-forget-connecting-server))

;; NOTE: `eglot-put-doc-in-buffer' and `eglot-code-actions-indications' were
;; set here before, but neither exists in the eglot shipped with Emacs 31.1 --
;; they set variables nothing reads.  31.1 does have the singular `eglot-code-action-indications'
;; (default: eldoc hint, left fringe and margin); there is still no option for
;; putting documentation in a buffer.  Left at the defaults on purpose.

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
;; Since Emacs 30 the elisp byte-compile backend only runs in buffers covered
;; by `trusted-content' (compiling expands macros, i.e. runs the file's code),
;; and nothing is trusted by default -- so this config's own sources got no
;; diagnostics at all.  Trust exactly the files written here and already
;; executed at every startup; not the whole `user-emacs-directory', which also
;; holds elpa/ and themes from elsewhere.  `trusted-content-p' matches against
;; the abbreviated truename, hence `file-truename'; directory entries keep
;; their trailing slash.  Appended, so a Customize value survives, and skipped
;; when it is already `:all'.
(when (listp trusted-content)
  (let ((root (file-truename user-emacs-directory)))
    (dolist (path '("src/" "test/" "init.el" "early-init.el"))
      (add-to-list 'trusted-content
                   (abbreviate-file-name (expand-file-name path root)) t))))

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
  ;; Diagnostics are marked in the left fringe.  The bitmaps below replace the
  ;; stock arrow/dot glyphs with plain vertical bars of decreasing width:
  ;; 3px for an error, 2px for a warning, 1px for a note.  Each bitmap is one
  ;; row and '(center repeated) tiles it down the height of the line.
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
;; dk-languages.el (gofmt, clang-format) plus Rustic's own formatter were all
;; running a second time over the same buffer.
(use-package apheleia
  :init (apheleia-global-mode +1)
  :config
  ;; clang-format and fourmolu only where the tree asks for them, and never
  ;; Emacs Lisp; see `dk/apheleia-inhibit-p'.  The predicate's old name is
  ;; dropped so reloading this module over an older session leaves one entry.
  (setq apheleia-inhibit-functions
        (delq 'dk/no-clang-format-p apheleia-inhibit-functions))
  (add-to-list 'apheleia-inhibit-functions #'dk/apheleia-inhibit-p))

(provide 'dk-programming)
;;; dk-programming.el ends here
