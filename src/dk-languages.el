;; -*- lexical-binding: t; -*-

;;; Per-language settings
;;
;; Editor-wide programming support (eglot, flymake, apheleia) is in
;; dk-programming.el; this file only holds what differs per language.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; LSP servers
;;
;; One `add-to-list' per server: the value is an alist of (MODES . CONTACT), so a
;; single call must not wrap them in an extra list -- and it must be quoted once,
;; not twice.  `add-to-list' prepends and eglot takes the first match, so these
;; win over eglot's built-in defaults.
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((haskell-mode haskell-ts-mode)
                 . ("haskell-language-server-wrapper" "--lsp")))
  (add-to-list 'eglot-server-programs
               '((rust-ts-mode rust-mode)
                 . ("rust-analyzer"
                    :initializationOptions (:check (:command "clippy")))))
  (add-to-list 'eglot-server-programs
               '((c-ts-mode c-mode c++-ts-mode c++-mode)
                 . ("clangd" "--clang-tidy"
                    :initializationOptions (:fallbackFlags ["-std=c23"])))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Haskell
(use-package haskell-mode
  :mode ("\\.hs\\'" . haskell-mode)
  :hook ((haskell-mode . haskell-indentation-mode)
         ;; haskell-doc-mode fights with eglot/eldoc over the echo area
         (haskell-mode . dk/haskell-disable-doc-mode))
  :bind
  (:map haskell-mode-map
        ("C-c C-l" . haskell-process-load-file)
        ("C-c C-z" . haskell-interactive-switch)
        ("C-c C-t" . haskell-mode-show-type-at))
  :config
  (setq haskell-process-type 'cabal-repl))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Rust -- rustic drives eglot, so rust-mode gets no eglot-ensure hook
(use-package rust-mode)

(use-package rustic
  :custom (rustic-lsp-client 'eglot)
  :hook (rustic-mode . eglot-ensure)
  :config (setq rustic-format-on-save t))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Go
(use-package go-mode
  :mode "\\.go\\'"
  :hook (go-mode . dk/go-format-on-save))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; C / C++ -- format on save only in trees that carry a .clang-format
(use-package clang-format
  :hook ((c-ts-mode c-mode c++-ts-mode c++-mode) . dk/clang-format-on-save))

(provide 'dk-languages)
;;; dk-languages.el ends here
