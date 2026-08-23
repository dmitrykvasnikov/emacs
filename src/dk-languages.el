;; -*- lexical-binding: t; -*-

;;; Per-language settings
;;
;; Editor-wide programming support (eglot, flymake, apheleia) is in
;; dk-programming.el, and the grammar/remap plumbing is in dk-treesit.el.
;; This file only holds what differs per language.

(require 'treesit)                      ; `treesit-ready-p' in `dk/haskell-toggle-ts'
(require 'dk-functions)

(defvar eglot-server-programs)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; LSP servers
;;
;; One `add-to-list' per server: the value is an alist of (MODES . CONTACT), so a
;; single call must not wrap them in an extra list -- and it must be quoted once,
;; not twice.  `add-to-list' prepends and eglot takes the first match, so these
;; win over eglot's built-in defaults.  Classic and ts modes are both named in
;; each entry so the lookup does not depend on how the modes are related.
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((haskell-mode haskell-ts-mode)
                 . ("haskell-language-server-wrapper" "--lsp")))
  (add-to-list 'eglot-server-programs
               '((rustic-mode rust-mode rust-ts-mode)
                 . ("rust-analyzer"
                    :initializationOptions (:check (:command "clippy")))))
  (add-to-list 'eglot-server-programs
               '((c-ts-mode c-mode c++-ts-mode c++-mode)
                 . ("clangd" "--clang-tidy"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Haskell -- haskell-mode by default, haskell-ts-mode on demand
;;
;; `major-mode-remap-alist' is the only lever: no entry means haskell-mode, an
;; entry means haskell-ts-mode.  `dk/haskell-toggle-ts' flips it for the whole
;; session; `M-x haskell-ts-mode' switches a single buffer, and a
;; `-*- mode: haskell-ts -*-' cookie pins one file for good.
(use-package haskell-mode
  :mode ("\\.hs\\'" . haskell-mode)
  :bind (:map haskell-mode-map
              ("C-c C-l" . haskell-process-load-file)    ; load this file into the repl
              ("C-c C-z" . haskell-interactive-switch)   ; jump to the repl buffer
              ("C-c C-t" . haskell-mode-show-type-at))   ; type of the thing at point
  ;; Start the repl as `cabal repl' rather than a bare ghci, so the project's
  ;; dependencies and extensions are in scope.
  :custom (haskell-process-type 'cabal-repl))

(use-package haskell-ts-mode
  :defer t
  :custom
  (haskell-ts-use-indent t)             ; nil upstream -- no indent rules at all
  :bind (:map haskell-ts-mode-map
              ;; Mirror the haskell-mode keys above where an equivalent exists.
              ;; This mode drives a bare ghci, not a cabal repl.
              ("C-c C-l" . haskell-ts-compile-region-and-go)
              ("C-c C-z" . run-haskell)
              ("C-c C-t" . eldoc-doc-buffer))
  :config
  ;; Loading this file prepends ("\\.hs\\'" . haskell-ts-mode) to
  ;; `auto-mode-alist' as soon as the grammar is ready, which would hijack .hs
  ;; the first time the package is touched.  Drop it -- the remap alist decides.
  (setq auto-mode-alist (delete '("\\.hs\\'" . haskell-ts-mode) auto-mode-alist))
  ;; Upstream binds C-c C-f to `haskell-ts-format'.  apheleia already formats
  ;; on save, so the manual command is only a way to reformat at a moment
  ;; apheleia would not have picked -- not worth a key.  (It used to shadow the
  ;; global `consult-find' as well; that binding has since moved to C-c f, so
  ;; dropping this line no longer costs anything but the clutter.)
  (keymap-unset haskell-ts-mode-map "C-c C-f" t))

(defun dk/haskell-toggle-ts ()
  "Toggle Haskell between `haskell-mode' and `haskell-ts-mode'.
Flips the remap for files opened later, and re-applies it to the Haskell
buffers already open."
  (interactive)
  (require 'haskell-ts-mode)
  (unless (treesit-ready-p 'haskell)
    (user-error "No Haskell grammar -- run M-x dk/treesit-install-all"))
  (let ((on (eq (alist-get 'haskell-mode major-mode-remap-alist)
                'haskell-ts-mode)))
    (if on
        (setf (alist-get 'haskell-mode major-mode-remap-alist nil t) nil)
      (setf (alist-get 'haskell-mode major-mode-remap-alist) 'haskell-ts-mode))
    (dolist (buf (buffer-list))
      (with-current-buffer buf
        ;; haskell-ts-mode registers haskell-mode as a parent via
        ;; `derived-mode-add-parents', so this catches buffers in either mode.
        (when (derived-mode-p 'haskell-mode)
          (if on (haskell-mode) (haskell-ts-mode)))))
    (message "Haskell: %s" (if on "haskell-mode" "haskell-ts-mode"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Rust -- rustic owns .rs and drives eglot, so rust-mode gets no eglot hook.
;; `rust-mode-treesitter-derive' (dk-treesit.el) makes rust-mode derive from
;; `rust-ts-mode', and rustic-mode derives from rust-mode, so rustic buffers
;; are tree-sitter buffers without needing a remap entry.
;; rust-mode must not be demand-loaded: loading it re-adds ("\\.rs\\'" .
;; rust-mode) to `auto-mode-alist' ahead of rustic's own autoloaded entry, and
;; .rs then opens in rust-mode -- which meant rustic never loaded and its
;; `eglot-ensure' hook never ran.  rustic pulls rust-mode in as its parent.
(use-package rust-mode
  :defer t)

(use-package rustic
  :mode ("\\.rs\\'" . rustic-mode)
  :hook (rustic-mode . eglot-ensure)
  :init
  ;; The hook above is the single owner of Eglot startup.  Rustic otherwise
  ;; installs `rustic-setup-lsp', which calls `eglot-ensure' a second time.
  (setq rustic-lsp-setup-p nil)
  :custom
  ;; rustic would otherwise start lsp-mode, which is not installed here.
  (rustic-lsp-client 'eglot)
  ;; Formatting is apheleia's job (rust-ts-mode -> rustfmt).
  (rustic-format-trigger nil))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Go -- go-ts-mode is built in but ships no `auto-mode-alist' entry, so
;; dk-treesit.el adds one pointing straight at it.  The go-mode package used to
;; be installed for that single entry and nothing else: with .go mapped to
;; go-mode and go-mode remapped to go-ts-mode, `set-auto-mode' resolved the
;; remap before dispatching and the package was never actually loaded.  go.mod
;; would otherwise open in `m2-mode', which dk-treesit.el also fixes.
(use-package go-ts-mode
  :ensure nil                           ; built-in
  :defer t
  ;; Go indents with tabs; this is how wide one is displayed, 4 instead of the
  ;; default 8.  It does not change what gofmt writes to the file.
  :custom (go-ts-mode-indent-offset 4))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; C / C++ -- c-ts-mode does NOT derive from c-mode, so anything that used to
;; hang off `c-mode-hook' has to be re-pointed at the ts modes.  Formatting is
;; apheleia's, gated on .clang-format or _clang-format by
;; `dk/no-clang-format-p'.
(use-package c-ts-mode
  :ensure nil                           ; built-in
  :defer t
  ;; Indentation step for both c-ts-mode and c++-ts-mode.  The overall style
  ;; (brace placement and the rest) comes from `c-ts-mode-set-style'; only the
  ;; width is overridden here.
  :custom (c-ts-mode-indent-offset 4))

;; Not used for format-on-save -- apheleia calls the clang-format binary itself.
;; This is kept for the interactive commands (`clang-format-buffer',
;; `clang-format-region'), which is why it is never demand-loaded.
(use-package clang-format
  :defer t)

(provide 'dk-languages)
;;; dk-languages.el ends here
