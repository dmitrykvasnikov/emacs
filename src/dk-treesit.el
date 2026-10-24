;; -*- lexical-binding: t; -*-

;;; Tree-sitter: grammars, explicit installation, major-mode remapping
;;
;; Loaded ahead of dk-programming and dk-languages: `major-mode-remap-alist'
;; has to be in place before any file is visited, and `rust-mode-treesitter-derive'
;; has to be set before rust-mode is loaded.

(require 'treesit)

;; Emacs 31 otherwise prompts to download grammars when files are opened.
(setq treesit-auto-install-grammar 'never)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Grammars
;;
;; Built into <user-emacs-directory>/tree-sitter/ rather than taken from the
;; distro, so availability and grammar revisions do not depend on distro
;; packaging.  Check `treesit-library-abi-version' for Emacs' supported ABI.
;;
;; Every revision is pinned.  An unpinned master can raise the ABI past 15, or
;; rename nodes out from under the queries in Emacs' own ts modes; the second
;; failure mode shows up as quietly missing fontification rather than an error.
(setq treesit-language-source-alist
      '((bash       "https://github.com/tree-sitter/tree-sitter-bash"          "v0.23.3")
        (c          "https://github.com/tree-sitter/tree-sitter-c"             "v0.23.4")
        (cmake      "https://github.com/uyha/tree-sitter-cmake"                "v0.7.1")
        (cpp        "https://github.com/tree-sitter/tree-sitter-cpp"           "v0.23.4")
        (dockerfile "https://github.com/camdencheek/tree-sitter-dockerfile"    "v0.2.0")
        (go         "https://github.com/tree-sitter/tree-sitter-go"            "v0.23.4")
        (gomod      "https://github.com/camdencheek/tree-sitter-go-mod"        "v1.1.0")
        (haskell    "https://github.com/tree-sitter/tree-sitter-haskell"       "v0.23.1")
        (json       "https://github.com/tree-sitter/tree-sitter-json"          "v0.24.8")
        (rust       "https://github.com/tree-sitter/tree-sitter-rust"          "v0.23.2")
        (toml       "https://github.com/tree-sitter-grammars/tree-sitter-toml" "v0.7.0")
        (yaml       "https://github.com/tree-sitter-grammars/tree-sitter-yaml" "v0.7.1")))

(setq treesit-font-lock-level 4)        ; every feature the grammars define

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Installing them
;; Grammar installation is deliberately explicit.  Opening a source file must
;; not unexpectedly start Git, download code, or compile a C grammar in the
;; foreground.  Use `M-x dk/treesit-install-all' when setting up a machine.

(defun dk/treesit-install-all (&optional force)
  "Install every grammar in `treesit-language-source-alist'.
Grammars already present are skipped unless FORCE (the prefix argument)
is non-nil."
  (interactive "P")
  (dolist (src treesit-language-source-alist)
    (let ((lang (car src)))
      (if (and (not force) (treesit-language-available-p lang))
          (message "treesit: %s already installed" lang)
        (message "treesit: installing %s..." lang)
        (treesit-install-language-grammar lang))))
  ;; The built-in installer can report a warning instead of signaling an
  ;; error.  Do not announce success unless every library actually loads.
  (let ((missing (seq-remove #'treesit-language-available-p
                             (mapcar #'car treesit-language-source-alist))))
    (when missing
      (user-error "Tree-sitter grammars still unavailable: %s" missing)))
  (message "treesit: all grammars available; restart Emacs to update modes"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Only select tree-sitter modes when their required grammars are available.
;; Restart Emacs after installing grammars to update these choices; in
;; particular rust-mode's parent is fixed when its library is first loaded.
(dolist (entry '((c-mode c-ts-mode c)
                 (c++-mode c++-ts-mode c cpp)
                 (c-or-c++-mode c-or-c++-ts-mode c cpp)
                 (js-json-mode json-ts-mode json)
                 (conf-toml-mode toml-ts-mode toml)
                 (sh-mode bash-ts-mode bash)))
  (let ((classic (car entry)) (mode (cadr entry)))
    (setf (alist-get classic major-mode-remap-alist nil t)
          (and (seq-every-p #'treesit-language-available-p (cddr entry))
               mode))))

;; These file types have no installed classic language package.  Use plain
;; text when a grammar is missing rather than an unrelated mode (go.mod used
;; to select Modula-2).  No downloads occur while visiting a file.
(dolist (entry '(("\\.go\\'" go-ts-mode go)
                 ("/go\\.mod\\'" go-mod-ts-mode gomod)
                 ("\\.ya?ml\\'" yaml-ts-mode yaml)
                 ("CMakeLists\\.txt\\'" cmake-ts-mode cmake)
                 ("\\.cmake\\'" cmake-ts-mode cmake)
                 ("/\\(?:Containerfile\\|Dockerfile\\)\\(?:\\.[^/]*\\)?\\'"
                  dockerfile-ts-mode dockerfile)))
  (setf (alist-get (car entry) auto-mode-alist nil nil #'equal)
        (if (treesit-language-available-p (nth 2 entry))
            (cadr entry)
          'text-mode)))

;; Haskell remains classic by default.  Rustic can also use classic Rust
;; when its grammar is absent; this must be chosen before rust-mode loads.
(setq rust-mode-treesitter-derive (treesit-language-available-p 'rust))

;; A warning, not a `message': missing grammars quietly put Go, YAML, CMake and
;; Dockerfile files in text-mode (no LSP, no formatter), and under the daemon a
;; startup message ends up in the journal where nobody reads it.
(let ((missing (seq-remove #'treesit-language-available-p
                           (mapcar #'car treesit-language-source-alist))))
  (when missing
    (display-warning
     'dk-treesit
     (format "Tree-sitter grammars missing: %s; run M-x dk/treesit-install-all, then restart Emacs"
             missing)
     :warning)))

(provide 'dk-treesit)
;;; dk-treesit.el ends here
